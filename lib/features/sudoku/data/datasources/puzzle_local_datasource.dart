import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:m6_sudoku/features/sudoku/domain/entities/puzzle.dart';
import 'package:m6_sudoku/features/sudoku/domain/entities/game_state.dart';
import 'package:m6_sudoku/features/sudoku/engine/generator/puzzle_generator.dart';
import 'package:m6_sudoku/features/sudoku/engine/models/difficulty.dart';
import 'package:m6_sudoku/core/errors/failures.dart';
import 'package:m6_sudoku/core/services/storage_service.dart';

class PuzzleLocalDataSource {
  PuzzleLocalDataSource(this._storage, [PuzzleGenerator? generator])
    : _generator = generator ?? PuzzleGenerator();

  final StorageService _storage;
  final PuzzleGenerator _generator;

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
      final puzzle = _generatePuzzleForDifficulty(difficulty);
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
    try {
      final jsonString = _storage.getString(_puzzleKey);
      if (jsonString == null) return const Right(null);
      final map = jsonDecode(jsonString) as Map<String, dynamic>;
      return Right(Puzzle.fromJson(map));
    } catch (e) {
      return Left(CacheFailure('Failed to get current puzzle: $e'));
    }
  }

  Future<Either<Failure, void>> savePuzzle(Puzzle puzzle) async {
    try {
      await _storage.setString(_puzzleKey, jsonEncode(puzzle.toJson()));
      return const Right(null);
    } catch (e) {
      return Left(StorageFailure('Failed to save puzzle: $e'));
    }
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

  Future<Either<Failure, void>> saveGameState(GameState state) async {
    try {
      final versioned = state.copyWith(
        saveVersion: GameState.currentSaveVersion,
      );
      await _storage.setString(_gameStateKey, jsonEncode(versioned.toJson()));
      return const Right(null);
    } catch (e) {
      return Left(StorageFailure('Failed to save game state: $e'));
    }
  }

  Future<Either<Failure, void>> clearGameState() async {
    try {
      await _storage.remove(_gameStateKey);
      await _storage.remove(_puzzleKey);
      return const Right(null);
    } catch (e) {
      return Left(StorageFailure('Failed to clear game state: $e'));
    }
  }

  Future<Either<Failure, List<Puzzle>>> getPuzzleHistory() async {
    try {
      final jsonString = _storage.getString(_historyKey);
      if (jsonString == null) return const Right([]);
      final list = jsonDecode(jsonString) as List;
      return Right(
        list.map((e) => Puzzle.fromJson(e as Map<String, dynamic>)).toList(),
      );
    } catch (e) {
      return Left(CacheFailure('Failed to get puzzle history: $e'));
    }
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

  Puzzle _generatePuzzleForDifficulty(String difficulty) {
    final parsedDifficulty = Difficulty.values.firstWhere(
      (d) => d.name == difficulty,
      orElse: () => Difficulty.medium,
    );
    final (:puzzle, :solution) = _generator.generatePuzzleWithSolution(
      parsedDifficulty,
    );

    return Puzzle(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      grid: puzzle.toGrid(),
      solution: solution.toGrid(),
      difficulty: difficulty,
      cluesCount: puzzle.filledCount,
      createdAt: DateTime.now(),
    );
  }
}
