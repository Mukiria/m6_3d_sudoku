import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:m6_sudoku/core/theme/app_theme_extension.dart';
import 'package:m6_sudoku/features/cube_sudoku/domain/entities/cube_face.dart';
import 'package:m6_sudoku/features/cube_sudoku/domain/entities/cube_game_state.dart';
import 'package:m6_sudoku/features/cube_sudoku/presentation/providers/cube_game_provider.dart';
import 'package:m6_sudoku/features/cube_sudoku/presentation/screens/cube_game_screen.dart';
import 'package:m6_sudoku/features/sudoku/domain/entities/game_state.dart';
import 'package:m6_sudoku/features/sudoku/domain/entities/puzzle.dart';
import 'package:m6_sudoku/features/sudoku/engine/models/difficulty.dart';
import 'package:m6_sudoku/features/sudoku/presentation/providers/sudoku_providers.dart';

import '../../../../fakes/fake_services.dart';

/// A trivially "solved except for one cell" 9x9: everything already
/// matches [_kSolution] except the given [emptyRow]/[emptyCol], which is
/// still empty (0) — solving that one cell via [CubeGameController.setValue]
/// is what flips this face's status to completed, without needing the
/// real (isolate-based, and — critically — hostile to `testWidgets`'
/// FakeAsync test zone — see this file's other doc comment) puzzle
/// generator at all.
final _kSolution = List.generate(
  9,
  (r) => List.generate(9, (c) => ((r + c) % 9) + 1),
);

List<List<int>> _almostSolvedGrid({
  required int emptyRow,
  required int emptyCol,
}) {
  return List.generate(9, (r) {
    return List.generate(9, (c) {
      if (r == emptyRow && c == emptyCol) return 0;
      return _kSolution[r][c];
    });
  });
}

GameState _almostSolvedFace(
  String id, {
  required int emptyRow,
  required int emptyCol,
}) {
  final grid = _almostSolvedGrid(emptyRow: emptyRow, emptyCol: emptyCol);
  final puzzle = Puzzle(
    id: id,
    grid: grid,
    solution: _kSolution,
    difficulty: 'easy',
    cluesCount: 80,
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

/// Solving one face while five others remain should — in the 3D cube
/// experience — automatically shrink the cube, rotate it to the next
/// unsolved face, and expand back into Play View there, without the
/// player having to manually back out to Browse View and pick one
/// themselves. This exercises that whole sequence end-to-end rather than
/// any one private method, since the sequence is implemented as several
/// cooperating AnimationControllers/callbacks private to
/// _CubeGameScreenState.
///
/// Deliberately seeds the session via [CubeGameController.continueCubeGame]
/// (a synchronous state assignment) rather than [CubeGameController.newCubeGame]
/// (which generates every face's puzzle on a background isolate via
/// `compute()`): a `testWidgets` body runs inside a FakeAsync test zone
/// that only advances via explicit `tester.pump`, and an `await` on a real
/// isolate round-trip never resolves under it — awaiting `newCubeGame`
/// here hangs the test indefinitely instead of failing.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget wrap(ProviderContainer container) {
    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: ThemeData.light().copyWith(
          extensions: [AppThemeExtension.light],
        ),
        home: const CubeGameScreen(),
      ),
    );
  }

  testWidgets(
    'completing the active face auto-advances to the next unsolved face in the 3D cube experience',
    (tester) async {
      final container = ProviderContainer(
        overrides: [
          storageServiceProvider.overrideWithValue(FakeStorageService()),
          audioServiceProvider.overrideWithValue(FakeAudioService()),
        ],
      );
      // Disposed explicitly at the end of the test body, not via
      // addTearDown: this screen leaves a real (non-fake-clock) 30s
      // autosave Timer and a periodic 1s game timer running for as long as
      // its providers are alive, and testWidgets' own pending-timer check
      // runs before addTearDown callbacks do — so an addTearDown-only
      // disposal here would still trip "A Timer is still pending" even
      // though nothing is actually leaked.
      container.listen(cubeGameControllerProvider, (_, _) {});

      final cubeState = CubeGameState(
        cubeId: 'cube_1',
        faceStates: {
          for (final face in CubeFace.values)
            face.name: _almostSolvedFace(
              'puzzle_${face.name}',
              emptyRow: 0,
              emptyCol: 0,
            ),
        },
        activeFace: CubeFace.front,
        timeElapsed: 0,
        lastPlayed: DateTime(2026, 1, 1),
        lastSaved: DateTime(2026, 1, 1),
      );

      final controller = container.read(cubeGameControllerProvider.notifier);
      await controller.continueCubeGame(cubeState);

      await tester.pumpWidget(wrap(container));
      await tester.pump();
      // The screen's own postFrameCallback starts the cube timer and reads
      // isComplete; let that settle before driving gameplay.
      await tester.pump();

      // The one empty cell on the active face (front) — filling it in with
      // the right value completes that face without touching any other.
      controller.setValue(CubeFace.front, 0, 0, _kSolution[0][0]);

      final afterSolve = container.read(cubeGameControllerProvider)!;
      expect(afterSolve.faceState(CubeFace.front).status.name, 'completed');
      expect(afterSolve.isComplete, false);

      // Drive the auto-advance's own timeline: the 450ms pause before it
      // starts, the 500ms shrink, the 650ms rotate, and the 500ms expand.
      await tester.pump(const Duration(milliseconds: 460));
      await tester.pump(const Duration(milliseconds: 520));
      await tester.pump(const Duration(milliseconds: 670));
      await tester.pump(const Duration(milliseconds: 520));
      await tester.pump();

      expect(tester.takeException(), isNull);

      final after = container.read(cubeGameControllerProvider)!;
      // CubeFace.values is [top, bottom, front, back, left, right] — the
      // next entry after front that isn't already solved is back.
      expect(after.activeFace, CubeFace.back);

      // Unmount before disposing so State.dispose (which cancels this
      // screen's own AnimationControllers) runs ahead of the provider
      // container teardown that cancels the notifier's autosave Timer.
      await tester.pumpWidget(const SizedBox.shrink());
      container.dispose();
    },
  );
}
