import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart' show compute;
import 'package:m6_sudoku/core/errors/failures.dart';
import 'package:m6_sudoku/core/services/json_store.dart';
import 'package:m6_sudoku/core/services/storage_service.dart';
import 'package:m6_sudoku/features/sudoku/domain/entities/game_state.dart';
import 'package:m6_sudoku/features/sudoku/domain/entities/puzzle.dart';
import 'package:m6_sudoku/features/sudoku/engine/generator/puzzle_generator.dart';
import 'package:m6_sudoku/features/sudoku/engine/models/difficulty.dart';

class PuzzleLocalDataSource {
  PuzzleLocalDataSource(this._storage, [PuzzleGenerator? generator])
    : _generator = generator ?? PuzzleGenerator(),
      _json = JsonStore(_storage);

  final StorageService _storage;
  final PuzzleGenerator _generator;
  final JsonStore _json;

  static const String _puzzleKey = 'current_puzzle';
  static const String _gameStateKey = 'game_state';
  static const String _historyKey = 'puzzle_history';
  static const String _cacheKey = 'puzzle_cache_';
  static const int _maxCachedPuzzlesPerDifficulty = 10;

  Future<Either<Failure, Puzzle>> generatePuzzle(String difficulty) async {
    try {
      // Try to get a cached puzzle first
      final cached = await _getCachedPuzzle(difficulty);
      if (cached != null) {
        await _storage.setString(_puzzleKey, jsonEncode(cached.toJson()));
        return Right(cached);
      }

      // Generate new puzzle if no cache available
      final puzzle = await _generatePuzzleForDifficulty(difficulty);
      await _storage.setString(_puzzleKey, jsonEncode(puzzle.toJson()));
      await _cachePuzzle(puzzle);
      return Right(puzzle);
    } catch (e) {
      return Left(PuzzleGenerationFailure('Failed to generate puzzle: $e'));
    }
  }

  Future<Puzzle?> _getCachedPuzzle(String difficulty) async {
    try {
      final jsonString = _storage.getString('$_cacheKey$difficulty');
      if (jsonString == null) return null;
      final list = jsonDecode(jsonString) as List;
      if (list.isEmpty) return null;
      final map = list.removeAt(0) as Map<String, dynamic>;
      await _storage.setString('$_cacheKey$difficulty', jsonEncode(list));
      return Puzzle.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  Future<void> _cachePuzzle(Puzzle puzzle) async {
    try {
      final jsonString = _storage.getString('$_cacheKey${puzzle.difficulty}');
      final list =
          jsonString != null ? jsonDecode(jsonString) as List : <dynamic>[];
      list.insert(0, puzzle.toJson());
      if (list.length > _maxCachedPuzzlesPerDifficulty) {
        list.removeRange(_maxCachedPuzzlesPerDifficulty, list.length);
      }
      await _storage.setString(
        '$_cacheKey${puzzle.difficulty}',
        jsonEncode(list),
      );
    } catch (_) {
      // Silently fail caching
    }
  }

  Future<Either<Failure, Puzzle?>> getCurrentPuzzle() async {
    return _json.readJson(
      _puzzleKey,
      (decoded) => Puzzle.fromJson(decoded as Map<String, dynamic>),
      () => null,
      'get current puzzle',
    );
  }

  Future<Either<Failure, void>> savePuzzle(Puzzle puzzle) {
    return _json.writeJson(_puzzleKey, puzzle.toJson(), 'save puzzle');
  }

  Future<Either<Failure, GameState?>> getGameState() async {
    try {
      final jsonString = _storage.getString(_gameStateKey);
      if (jsonString == null) return const Right(null);
      final map = jsonDecode(jsonString) as Map<String, dynamic>;

      // A save from an older/newer app version may not deserialize into a
      // valid state (or may parse "successfully" into wrong semantics), so
      // discard it outright rather than risk restoring a broken game.
      final savedVersion = map['saveVersion'] as int?;
      if (savedVersion != GameState.currentSaveVersion) {
        await _storage.remove(_gameStateKey);
        return const Right(null);
      }

      return Right(GameState.fromJson(map));
    } catch (e) {
      // Corrupt save data — clear it so future launches don't keep hitting
      // the same failure.
      await _storage.remove(_gameStateKey);
      return Left(CacheFailure('Failed to get game state: $e'));
    }
  }

  Future<Either<Failure, void>> saveGameState(GameState state) {
    final versioned = state.copyWith(saveVersion: GameState.currentSaveVersion);
    return _json.writeJson(
      _gameStateKey,
      versioned.toJson(),
      'save game state',
    );
  }

  Future<Either<Failure, void>> clearGameState() {
    return _json.removeKeys([_gameStateKey, _puzzleKey], 'clear game state');
  }

  Future<Either<Failure, List<Puzzle>>> getPuzzleHistory() async {
    return _json.readJson(
      _historyKey,
      (decoded) =>
          (decoded as List)
              .map((e) => Puzzle.fromJson(e as Map<String, dynamic>))
              .toList(),
      () => <Puzzle>[],
      'get puzzle history',
    );
  }

  Future<Either<Failure, void>> savePuzzleToHistory(Puzzle puzzle) async {
    try {
      final historyResult = await getPuzzleHistory();
      return historyResult.fold((failure) => Left(failure), (history) {
        final updated = [puzzle, ...history].take(100).toList();
        _storage.setString(
          _historyKey,
          jsonEncode(updated.map((p) => p.toJson()).toList()),
        );
        return const Right(null);
      });
    } catch (e) {
      return Left(StorageFailure('Failed to save puzzle to history: $e'));
    }
  }

  // Runs off the UI isolate via compute() — see generatePuzzleInBackground's
  // doc comment for why: this backtracking generation can take long enough
  // (Expert/Evil especially) to visibly freeze the UI if run in place.
  Future<Puzzle> _generatePuzzleForDifficulty(String difficulty) async {
    final parsedDifficulty = Difficulty.values.firstWhere(
      (d) => d.name == difficulty,
      orElse: () => Difficulty.medium,
    );
    final result = await compute(generatePuzzleInBackground, (
      difficulty: parsedDifficulty,
      seed: _generator.seed,
    ));

    return Puzzle(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      grid: result.grid,
      solution: result.solution,
      difficulty: difficulty,
      cluesCount: result.cluesCount,
      createdAt: DateTime.now(),
    );
  }
}
