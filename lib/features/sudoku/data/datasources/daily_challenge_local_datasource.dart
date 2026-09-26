import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart' show compute;
import 'package:m6_sudoku/core/errors/failures.dart';
import 'package:m6_sudoku/core/services/json_store.dart';
import 'package:m6_sudoku/core/services/storage_service.dart';
import 'package:m6_sudoku/features/sudoku/domain/entities/daily_challenge.dart';
import 'package:m6_sudoku/features/sudoku/domain/entities/puzzle.dart';
import 'package:m6_sudoku/features/sudoku/engine/generator/puzzle_generator.dart';
import 'package:m6_sudoku/features/sudoku/engine/grader/technique_grader.dart';
import 'package:m6_sudoku/features/sudoku/engine/models/difficulty.dart';

/// The daily puzzle for [dateSeed] (YYYYMMDD): the first puzzle in a fixed
/// seed sequence that genuinely grades as Medium (see [TechniqueGrader]).
/// Clue count alone let the occasional daily need chains or trial and
/// error. Generation and grading are both deterministic, so every device
/// still settles on the same puzzle. The first seed is the date itself, so
/// days whose original puzzle already fits keep it.
///
/// Top-level so it can run under [compute].
PuzzleGenerationResult generateDailyPuzzle(int dateSeed) {
  // Medium-generated puzzles fit Medium ~85% of the time, so running out
  // is vanishingly unlikely; the last candidate is used if it happens.
  const maxCandidates = 20;
  late PuzzleGenerationResult result;
  for (var i = 0; i < maxCandidates; i++) {
    // Stride past any YYYYMMDD value so no two dates share a seed.
    result = generatePuzzleInBackground((
      difficulty: Difficulty.medium,
      seed: dateSeed + i * 100000000,
    ));
    if (TechniqueGrader.grade(result.grid).fits(Difficulty.medium)) break;
  }
  return result;
}

class DailyChallengeLocalDataSource {
  DailyChallengeLocalDataSource(this._storage) : _json = JsonStore(_storage);

  final StorageService _storage;
  final JsonStore _json;

  static const String _dailyChallengeKey = 'daily_challenge_';
  static const String _dailyStatsKey = 'daily_challenge_stats';

  Future<Either<Failure, DailyChallenge>> getOrGenerateDailyChallenge() async {
    final today = _getTodayDateString();

    // Check if today's challenge already exists
    final existing = await _getDailyChallenge(today);
    if (existing != null) {
      return Right(existing);
    }

    // Generate new puzzle for today
    final puzzle = await _generateDailyPuzzle(today);
    final challenge = DailyChallenge(
      date: today,
      puzzle: puzzle,
      isCompleted: false,
      timeElapsed: null,
      mistakes: null,
      hintsUsed: null,
    );

    await _saveDailyChallenge(challenge);
    return Right(challenge);
  }

  Future<DailyChallenge?> _getDailyChallenge(String date) async {
    return _json
        .readJson<DailyChallenge?>(
          '$_dailyChallengeKey$date',
          (decoded) => DailyChallenge.fromJson(decoded as Map<String, dynamic>),
          () => null,
          'get daily challenge',
        )
        .fold((_) => null, (challenge) => challenge);
  }

  Future<void> _saveDailyChallenge(DailyChallenge challenge) async {
    await _storage.setString(
      '$_dailyChallengeKey${challenge.date}',
      jsonEncode(challenge.toJson()),
    );
  }

  Future<Either<Failure, void>> completeDailyChallenge({
    required String date,
    required int timeElapsed,
    required int mistakes,
    required int hintsUsed,
  }) async {
    try {
      final existing = await _getDailyChallenge(date);
      if (existing == null) {
        return const Left(NotFoundFailure('Daily challenge not found'));
      }
      if (existing.isCompleted) {
        return const Left(
          ValidationFailure('Daily challenge already completed'),
        );
      }

      final completed = existing.copyWith(
        isCompleted: true,
        timeElapsed: timeElapsed,
        mistakes: mistakes,
        hintsUsed: hintsUsed,
        completedAt: DateTime.now(),
      );

      await _saveDailyChallenge(completed);
      await _updateStats(completed);
      return const Right(null);
    } catch (e) {
      return Left(StorageFailure('Failed to complete daily challenge: $e'));
    }
  }

  Future<void> _updateStats(DailyChallenge challenge) async {
    try {
      final stats = await _getStats();
      final newStats = stats.copyWith(
        totalPlayed: stats.totalPlayed + 1,
        totalCompleted: stats.totalCompleted + (challenge.isCompleted ? 1 : 0),
        currentStreak: challenge.isCompleted ? stats.currentStreak + 1 : 0,
        bestStreak:
            challenge.isCompleted &&
                    (stats.currentStreak + 1) > stats.bestStreak
                ? stats.currentStreak + 1
                : stats.bestStreak,
        lastPlayedDate: DateTime.now(),
      );
      await _storage.setString(_dailyStatsKey, jsonEncode(newStats.toJson()));
    } catch (_) {
      // Silently fail
    }
  }

  Future<DailyChallengeStats> _getStats() async {
    return _json
        .readJson(
          _dailyStatsKey,
          (decoded) =>
              DailyChallengeStats.fromJson(decoded as Map<String, dynamic>),
          _defaultStats,
          'get daily challenge stats',
        )
        .fold((_) => _defaultStats(), (stats) => stats);
  }

  DailyChallengeStats _defaultStats() {
    return const DailyChallengeStats(
      totalPlayed: 0,
      totalCompleted: 0,
      currentStreak: 0,
      bestStreak: 0,
      lastPlayedDate: null,
    );
  }

  Future<Either<Failure, DailyChallengeStats>> getStats() async {
    return Right(await _getStats());
  }

  Future<bool> isDailyChallengeCompleted(String date) async {
    final challenge = await _getDailyChallenge(date);
    return challenge?.isCompleted ?? false;
  }

  // Runs off the UI isolate via compute() — see generatePuzzleInBackground's
  // doc comment for why. The seed makes generation deterministic per date,
  // so every player gets the same puzzle regardless of which isolate solves
  // it.
  Future<Puzzle> _generateDailyPuzzle(String date) async {
    final result = await compute(generateDailyPuzzle, _dateToSeed(date));

    return Puzzle(
      id: 'daily_$date',
      grid: result.grid,
      solution: result.solution,
      difficulty: 'medium',
      cluesCount: result.cluesCount,
      createdAt: DateTime.now(),
    );
  }

  int _dateToSeed(String date) {
    // Convert YYYY-MM-DD to integer seed
    final parts = date.split('-');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final day = int.parse(parts[2]);
    // Create deterministic seed: YYYYMMDD
    return year * 10000 + month * 100 + day;
  }

  String _getTodayDateString() {
    final now = DateTime.now().toUtc();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
