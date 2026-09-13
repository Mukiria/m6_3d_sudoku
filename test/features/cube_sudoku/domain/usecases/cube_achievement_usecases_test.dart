import 'package:flutter_test/flutter_test.dart';
import 'package:m6_sudoku/features/cube_sudoku/domain/entities/cube_face.dart';
import 'package:m6_sudoku/features/cube_sudoku/domain/entities/cube_game_state.dart';
import 'package:m6_sudoku/features/cube_sudoku/domain/usecases/cube_achievement_usecases.dart';
import 'package:m6_sudoku/features/sudoku/domain/entities/game_state.dart';
import 'package:m6_sudoku/features/sudoku/domain/entities/puzzle.dart';
import 'package:m6_sudoku/features/sudoku/engine/models/difficulty.dart';

GameState _completedFace({
  Difficulty difficulty = Difficulty.easy,
  int mistakes = 0,
  int hintsUsed = 0,
}) {
  final grid = List.generate(9, (_) => List.generate(9, (_) => 0));
  final puzzle = Puzzle(
    id: 'test',
    grid: grid,
    solution: grid,
    difficulty: difficulty.name,
    cluesCount: 0,
    createdAt: DateTime(2026, 1, 1),
  );
  return GameState(
    puzzleId: puzzle.id,
    puzzle: puzzle,
    userGrid: grid,
    notes: List.generate(9, (_) => List.generate(9, (_) => <int>{})),
    timeElapsed: 0,
    mistakes: mistakes,
    hintsUsed: hintsUsed,
    penaltyTime: 0,
    moveHistory: const [],
    redoStack: const [],
    status: GameStatus.completed,
    lastPlayed: DateTime(2026, 1, 1),
    difficulty: difficulty,
    selectedCell: null,
    selectedNumber: null,
    isNoteMode: false,
    highlightedCells: const {},
    conflictCells: const {},
    hintState: null,
    lastSaved: DateTime(2026, 1, 1),
  );
}

CubeGameState _completedCube({
  int timeElapsed = 600,
  Map<CubeFace, Difficulty> difficulties = const {},
  Map<CubeFace, int> mistakesByFace = const {},
  Map<CubeFace, int> hintsByFace = const {},
}) {
  final faceStates = {
    for (final face in CubeFace.values)
      face.name: _completedFace(
        difficulty: difficulties[face] ?? Difficulty.easy,
        mistakes: mistakesByFace[face] ?? 0,
        hintsUsed: hintsByFace[face] ?? 0,
      ),
  };
  return CubeGameState(
    cubeId: 'test_cube',
    faceStates: faceStates,
    activeFace: CubeFace.front,
    timeElapsed: timeElapsed,
    lastPlayed: DateTime(2026, 1, 1),
    lastSaved: DateTime(2026, 1, 1),
  );
}

void main() {
  group('EvaluateCubeAchievementDeltasUseCase', () {
    final useCase = EvaluateCubeAchievementDeltasUseCase();

    test('always credits first_cube on any completed cube', () {
      final deltas = useCase(_completedCube());
      expect(deltas['first_cube'], 1);
    });

    test(
      'credits flawless_cube only with 0 total mistakes and 0 total hints',
      () {
        final flawless = useCase(_completedCube());
        expect(flawless['flawless_cube'], 1);

        final oneMistake = useCase(
          _completedCube(mistakesByFace: {CubeFace.back: 1}),
        );
        expect(oneMistake['flawless_cube'], isNull);

        final oneHint = useCase(
          _completedCube(hintsByFace: {CubeFace.left: 1}),
        );
        expect(oneHint['flawless_cube'], isNull);
      },
    );

    test('credits speed_cuber under 1200 seconds, not at or above', () {
      final fast = useCase(_completedCube(timeElapsed: 1199));
      expect(fast['speed_cuber'], 1);

      final slow = useCase(_completedCube(timeElapsed: 1200));
      expect(slow['speed_cuber'], isNull);
    });

    test('credits evil_cube only when every face is Evil difficulty', () {
      final allEvil = useCase(
        _completedCube(
          difficulties: {
            for (final face in CubeFace.values) face: Difficulty.evil,
          },
        ),
      );
      expect(allEvil['evil_cube'], 1);

      final fiveEvilOneEasy = useCase(
        _completedCube(
          difficulties: {
            for (final face in CubeFace.values) face: Difficulty.evil,
            CubeFace.top: Difficulty.easy,
          },
        ),
      );
      expect(fiveEvilOneEasy['evil_cube'], isNull);

      final allEasy = useCase(_completedCube());
      expect(allEasy['evil_cube'], isNull);
    });
  });
}
