import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart' show compute;
import 'package:m6_sudoku/core/errors/failures.dart';
import 'package:m6_sudoku/core/services/json_store.dart';
import 'package:m6_sudoku/core/services/storage_service.dart';
import 'package:m6_sudoku/features/sudoku/data/datasources/puzzle_bank_source.dart';
import 'package:m6_sudoku/features/sudoku/domain/entities/game_state.dart';
import 'package:m6_sudoku/features/sudoku/domain/entities/puzzle.dart';
import 'package:m6_sudoku/features/sudoku/engine/generator/puzzle_generator.dart';
import 'package:m6_sudoku/features/sudoku/engine/models/difficulty.dart';

class PuzzleLocalDataSource {
  PuzzleLocalDataSource(
    this._storage, [
    PuzzleGenerator? generator,
    PuzzleBankSource? bank,
  ]) : _generator = generator ?? PuzzleGenerator(),
       _bank = bank ?? PuzzleBankSource(),
       _json = JsonStore(_storage);

  final StorageService _storage;
  final PuzzleGenerator _generator;
  final PuzzleBankSource _bank;
  final JsonStore _json;

  static const String _puzzleKey = 'current_puzzle';
  static const String _gameStateKey = 'game_state';
  static const String _historyKey = 'puzzle_history';
  static const String _legacyCacheKey = 'puzzle_cache_';

  Future<Either<Failure, Puzzle>> generatePuzzle(String difficulty) async {
    try {
      final puzzle = await _generatePuzzleForDifficulty(difficulty);
      await _storage.setString(_puzzleKey, jsonEncode(puzzle.toJson()));
      // Builds up to 1.0.0+3 kept a per-difficulty cache here that re-served
      // the puzzle just played on every other New Game; drop what's left.
      await _storage.remove('$_legacyCacheKey$difficulty');
      return Right(puzzle);
    } catch (e) {
      return Left(PuzzleGenerationFailure('Failed to generate puzzle: $e'));
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

  // Draws from the pre-graded bundled bank (see PuzzleBankSource) unless a
  // seeded generator was injected, which asks for deterministic output.
  // Live generation is the fallback, and runs off the UI isolate via
  // compute() — see generatePuzzleInBackground's doc comment for why.
  Future<Puzzle> _generatePuzzleForDifficulty(String difficulty) async {
    final parsedDifficulty = Difficulty.values.firstWhere(
      (d) => d.name == difficulty,
      orElse: () => Difficulty.medium,
    );
    final drawn =
        _generator.seed == null ? await _bank.draw(parsedDifficulty) : null;
    final PuzzleGenerationResult result =
        drawn ??
        await compute(generatePuzzleInBackground, (
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
