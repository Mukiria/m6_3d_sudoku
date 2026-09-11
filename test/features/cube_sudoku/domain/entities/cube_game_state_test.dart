import 'package:flutter_test/flutter_test.dart';
import 'package:m6_sudoku/features/cube_sudoku/domain/entities/cube_face.dart';
import 'package:m6_sudoku/features/cube_sudoku/domain/entities/cube_game_state.dart';
import 'package:m6_sudoku/features/sudoku/domain/entities/game_state.dart';
import 'package:m6_sudoku/features/sudoku/domain/entities/puzzle.dart';
import 'package:m6_sudoku/features/sudoku/engine/models/difficulty.dart';

GameState _buildGameState(String id, {GameStatus status = GameStatus.playing}) {
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
    status: status,
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

CubeGameState _buildCubeGameState({
  Map<CubeFace, GameStatus> statuses = const {},
}) {
  final faceStates = {
    for (final face in CubeFace.values)
      face.name: _buildGameState(
        'puzzle_${face.name}',
        status: statuses[face] ?? GameStatus.playing,
      ),
  };
  return CubeGameState(
    cubeId: 'cube_1',
    faceStates: faceStates,
    activeFace: CubeFace.front,
    timeElapsed: 10,
    lastPlayed: DateTime(2026, 1, 1),
    lastSaved: DateTime(2026, 1, 1),
  );
}

void main() {
  group('CubeGameState', () {
    test('round-trips through JSON', () {
      final original = _buildCubeGameState();
      final decoded = CubeGameState.fromJson(original.toJson());

      expect(decoded.cubeId, original.cubeId);
      expect(decoded.activeFace, CubeFace.front);
      expect(decoded.faceStates.keys.toSet(), original.faceStates.keys.toSet());
      for (final face in CubeFace.values) {
        expect(
          decoded.faceState(face).puzzleId,
          original.faceState(face).puzzleId,
        );
      }
    });

    test('faceState/withFaceState read and update one face in isolation', () {
      final original = _buildCubeGameState();
      final updatedFrontState = original
          .faceState(CubeFace.front)
          .copyWith(timeElapsed: 99);

      final updated = original.withFaceState(CubeFace.front, updatedFrontState);

      expect(updated.faceState(CubeFace.front).timeElapsed, 99);
      // Every other face is untouched.
      for (final face in CubeFace.values.where((f) => f != CubeFace.front)) {
        expect(updated.faceState(face).timeElapsed, 0);
      }
    });

    test('isComplete is false until every face is completed', () {
      final partial = _buildCubeGameState(
        statuses: {
          for (final face in CubeFace.values) face: GameStatus.completed,
        }..[CubeFace.back] = GameStatus.playing,
      );
      expect(partial.isComplete, false);
      expect(partial.facesCompleted, 5);

      final full = _buildCubeGameState(
        statuses: {
          for (final face in CubeFace.values) face: GameStatus.completed,
        },
      );
      expect(full.isComplete, true);
      expect(full.facesCompleted, 6);
    });
  });
}
