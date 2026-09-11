import 'dart:convert';
import 'package:flutter/foundation.dart' show compute;
import 'package:dartz/dartz.dart';
import 'package:m6_sudoku/core/errors/failures.dart';
import 'package:m6_sudoku/core/services/json_store.dart';
import 'package:m6_sudoku/core/services/storage_service.dart';
import 'package:m6_sudoku/features/cube_sudoku/domain/entities/cube_face.dart';
import 'package:m6_sudoku/features/cube_sudoku/domain/entities/cube_game_state.dart';
import 'package:m6_sudoku/features/sudoku/domain/entities/puzzle.dart';
import 'package:m6_sudoku/features/sudoku/engine/generator/puzzle_generator.dart';
import 'package:m6_sudoku/features/sudoku/engine/models/difficulty.dart';

/// Persists a 3D Sudoku session in its own storage key — entirely separate
/// from [PuzzleLocalDataSource]'s single regular-game slot, so a paused
/// cube game and a paused regular game can coexist (mirrors how the daily
/// challenge already keeps its own slot).
class CubeGameLocalDataSource {
  CubeGameLocalDataSource(this._storage, [PuzzleGenerator? generator])
    : _generator = generator ?? PuzzleGenerator(),
      _json = JsonStore(_storage);

  final StorageService _storage;
  final PuzzleGenerator _generator;
  final JsonStore _json;

  static const String _cubeGameStateKey = 'cube_game_state';

  /// Generates one puzzle per face, all in parallel via [compute] — each
  /// call spawns its own background isolate (see
  /// `generatePuzzleInBackground`'s doc comment), so six puzzles — even at
  /// Expert/Evil clue counts — generate concurrently rather than one after
  /// another.
  Future<Either<Failure, Map<CubeFace, Puzzle>>> generateCubePuzzles(
    Map<CubeFace, Difficulty> difficulties,
  ) async {
    try {
      final entries = difficulties.entries.toList();
      final results = await Future.wait(
        entries.map(
          (entry) => compute(generatePuzzleInBackground, (
            difficulty: entry.value,
            seed: _generator.seed,
          )),
        ),
      );

      final generatedAt = DateTime.now();
      final puzzles = <CubeFace, Puzzle>{};
      for (var i = 0; i < entries.length; i++) {
        final face = entries[i].key;
        final difficulty = entries[i].value;
        final result = results[i];
        puzzles[face] = Puzzle(
          // Unique per face even though every face is generated in the same
          // millisecond — two faces sharing a puzzleId would corrupt the
          // per-face save/completion tracking that keys off it.
          id: '${generatedAt.millisecondsSinceEpoch}_${face.name}',
          grid: result.grid,
          solution: result.solution,
          difficulty: difficulty.name,
          cluesCount: result.cluesCount,
          createdAt: generatedAt,
        );
      }
      return Right(puzzles);
    } catch (e) {
      return Left(
        PuzzleGenerationFailure('Failed to generate cube puzzles: $e'),
      );
    }
  }

  Future<Either<Failure, CubeGameState?>> getCubeGameState() async {
    try {
      final jsonString = _storage.getString(_cubeGameStateKey);
      if (jsonString == null) return const Right(null);
      final map = jsonDecode(jsonString) as Map<String, dynamic>;

      // A save from an older/newer app version may not deserialize into a
      // valid state (or may parse "successfully" into wrong semantics), so
      // discard it outright rather than risk restoring a broken session —
      // same policy as PuzzleLocalDataSource.getGameState.
      final savedVersion = map['saveVersion'] as int?;
      if (savedVersion != CubeGameState.currentSaveVersion) {
        await _storage.remove(_cubeGameStateKey);
        return const Right(null);
      }

      return Right(CubeGameState.fromJson(map));
    } catch (e) {
      // Corrupt save data — clear it so future launches don't keep hitting
      // the same failure.
      await _storage.remove(_cubeGameStateKey);
      return Left(CacheFailure('Failed to get cube game state: $e'));
    }
  }

  Future<Either<Failure, void>> saveCubeGameState(CubeGameState state) {
    final versioned = state.copyWith(
      saveVersion: CubeGameState.currentSaveVersion,
    );
    return _json.writeJson(
      _cubeGameStateKey,
      versioned.toJson(),
      'save cube game state',
    );
  }

  Future<Either<Failure, void>> clearCubeGameState() {
    return _json.removeKeys([_cubeGameStateKey], 'clear cube game state');
  }
}
