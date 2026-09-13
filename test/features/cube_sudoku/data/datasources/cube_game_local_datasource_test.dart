import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:m6_sudoku/features/cube_sudoku/data/datasources/cube_game_local_datasource.dart';
import 'package:m6_sudoku/features/cube_sudoku/domain/entities/cube_face.dart';
import 'package:m6_sudoku/features/cube_sudoku/domain/entities/cube_game_state.dart';
import 'package:m6_sudoku/features/sudoku/domain/entities/game_state.dart';
import 'package:m6_sudoku/features/sudoku/domain/entities/puzzle.dart';
import 'package:m6_sudoku/features/sudoku/engine/models/difficulty.dart';

import '../../../../fakes/fake_services.dart';

GameState _buildGameState(String id) {
  final grid = List.generate(9, (i) => List.generate(9, (j) => 0));
  final solution = List.generate(
    9,
    (i) => List.generate(9, (j) => ((i + j) % 9) + 1),
  );
  final puzzle = Puzzle(
    id: id,
    grid: grid,
    solution: solution,
    difficulty: 'easy',
    cluesCount: 30,
    createdAt: DateTime(2026, 1, 1),
  );

  return GameState(
    puzzleId: puzzle.id,
    puzzle: puzzle,
    userGrid: grid,
    notes: List.generate(9, (_) => List.generate(9, (_) => <int>{})),
    timeElapsed: 0,
    mistakes: 0,
    hintsUsed: 0,
    penaltyTime: 0,
    moveHistory: const [],
    redoStack: const [],
    status: GameStatus.playing,
    lastPlayed: DateTime(2026, 1, 1),
    difficulty: Difficulty.easy,
    selectedCell: null,
    selectedNumber: null,
    isNoteMode: false,
    highlightedCells: const {},
    conflictCells: const {},
    hintState: null,
    lastSaved: DateTime(2026, 1, 1),
  );
}

CubeGameState _buildCubeGameState({int? saveVersion}) {
  final faceStates = {
    for (final face in CubeFace.values)
      face.name: _buildGameState('puzzle_${face.name}'),
  };
  var state = CubeGameState(
    cubeId: 'cube_1',
    faceStates: faceStates,
    activeFace: CubeFace.front,
    timeElapsed: 10,
    lastPlayed: DateTime(2026, 1, 1),
    lastSaved: DateTime(2026, 1, 1),
  );
  if (saveVersion != null) {
    state = state.copyWith(saveVersion: saveVersion);
  }
  return state;
}

void main() {
  group('CubeGameLocalDataSource.generateCubePuzzles', () {
    test(
      'generates one puzzle per face with the requested difficulty',
      () async {
        final ds = CubeGameLocalDataSource(FakeStorageService());

        // Easy/medium only — expert/evil clue-removal is slow (already
        // covered by the engine's own generator tests) and would just make
        // this wiring test slow without adding coverage of anything new.
        final result = await ds.generateCubePuzzles({
          CubeFace.top: Difficulty.easy,
          CubeFace.bottom: Difficulty.medium,
          CubeFace.front: Difficulty.easy,
          CubeFace.back: Difficulty.medium,
          CubeFace.left: Difficulty.easy,
          CubeFace.right: Difficulty.medium,
        });

        final puzzles = result.fold(
          (f) => throw Exception(f.message),
          (p) => p,
        );

        expect(puzzles.keys.toSet(), CubeFace.values.toSet());
        expect(puzzles[CubeFace.top]!.difficulty, 'easy');
        expect(puzzles[CubeFace.bottom]!.difficulty, 'medium');
        expect(puzzles[CubeFace.front]!.difficulty, 'easy');
        expect(puzzles[CubeFace.back]!.difficulty, 'medium');

        // Every face gets a distinct puzzle id — two faces sharing one would
        // corrupt per-face save/completion tracking that keys off it.
        final ids = puzzles.values.map((p) => p.id).toSet();
        expect(ids.length, CubeFace.values.length);

        for (final puzzle in puzzles.values) {
          expect(puzzle.isValid, true);
          expect(puzzle.grid.length, 9);
        }
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );
  });

  group('CubeGameLocalDataSource cube game state save format', () {
    test('saveCubeGameState stamps the current save version', () async {
      final ds = CubeGameLocalDataSource(FakeStorageService());
      await ds.saveCubeGameState(_buildCubeGameState(saveVersion: 999));

      final result = await ds.getCubeGameState();
      final loaded = result.fold((f) => throw Exception(f.message), (s) => s);

      expect(loaded, isNotNull);
      expect(loaded!.saveVersion, CubeGameState.currentSaveVersion);
    });

    test('round-trips the rest of the cube game state correctly', () async {
      final ds = CubeGameLocalDataSource(FakeStorageService());
      final original = _buildCubeGameState();
      await ds.saveCubeGameState(original);

      final result = await ds.getCubeGameState();
      final loaded = result.fold((f) => throw Exception(f.message), (s) => s);

      expect(loaded!.cubeId, original.cubeId);
      expect(loaded.activeFace, original.activeFace);
      expect(loaded.timeElapsed, original.timeElapsed);
      for (final face in CubeFace.values) {
        expect(
          loaded.faceState(face).puzzleId,
          original.faceState(face).puzzleId,
        );
      }
    });

    test(
      'discards a save with a mismatched version instead of loading it',
      () async {
        final storage = FakeStorageService();
        final ds = CubeGameLocalDataSource(storage);

        final staleJson =
            _buildCubeGameState(
              saveVersion: CubeGameState.currentSaveVersion + 1,
            ).toJson();
        await storage.setString('cube_game_state', jsonEncode(staleJson));

        final result = await ds.getCubeGameState();
        final loaded = result.fold((f) => throw Exception(f.message), (s) => s);
        expect(loaded, isNull);

        // The stale entry should have been cleared, not just skipped.
        expect(storage.getString('cube_game_state'), isNull);
      },
    );

    test('discards corrupt JSON and clears it', () async {
      final storage = FakeStorageService();
      final ds = CubeGameLocalDataSource(storage);

      await storage.setString('cube_game_state', '{not valid json');

      final result = await ds.getCubeGameState();
      expect(result.isLeft(), true);
      expect(storage.getString('cube_game_state'), isNull);
    });

    test('getCubeGameState returns null when nothing has been saved', () async {
      final ds = CubeGameLocalDataSource(FakeStorageService());
      final result = await ds.getCubeGameState();
      final loaded = result.fold((f) => throw Exception(f.message), (s) => s);
      expect(loaded, isNull);
    });

    test('clearCubeGameState removes the saved session', () async {
      final storage = FakeStorageService();
      final ds = CubeGameLocalDataSource(storage);
      await ds.saveCubeGameState(_buildCubeGameState());

      await ds.clearCubeGameState();

      expect(storage.getString('cube_game_state'), isNull);
    });
  });

  test(
    'a regular game save and a cube game save coexist under separate keys',
    () async {
      final storage = FakeStorageService();
      final ds = CubeGameLocalDataSource(storage);
      await storage.setString('game_state', 'not touched by cube saves');

      await ds.saveCubeGameState(_buildCubeGameState());

      expect(storage.getString('game_state'), 'not touched by cube saves');
      expect(storage.getString('cube_game_state'), isNotNull);
    },
  );
}
