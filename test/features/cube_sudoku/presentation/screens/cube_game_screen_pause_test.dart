import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:m6_sudoku/core/theme/app_theme_extension.dart';
import 'package:m6_sudoku/features/cube_sudoku/domain/entities/cube_face.dart';
import 'package:m6_sudoku/features/cube_sudoku/domain/entities/cube_game_state.dart';
import 'package:m6_sudoku/features/cube_sudoku/presentation/providers/cube_game_provider.dart';
import 'package:m6_sudoku/features/cube_sudoku/presentation/screens/cube_game_screen.dart';
import 'package:m6_sudoku/features/sudoku/domain/entities/game_state.dart';
import 'package:m6_sudoku/features/sudoku/domain/entities/puzzle.dart';
import 'package:m6_sudoku/features/sudoku/engine/models/difficulty.dart';
import 'package:m6_sudoku/features/sudoku/presentation/providers/sudoku_providers.dart';
import 'package:m6_sudoku/shared/widgets/pausable_blur.dart';

import '../../../../fakes/fake_services.dart';

GameState _playingFace(String id) {
  final solution = List.generate(
    9,
    (r) => List.generate(9, (c) => ((r + c) % 9) + 1),
  );
  final puzzle = Puzzle(
    id: id,
    grid: solution,
    solution: solution,
    difficulty: 'easy',
    cluesCount: 81,
    createdAt: DateTime(2026, 1, 1),
  );
  return GameState(
    puzzleId: puzzle.id,
    puzzle: puzzle,
    userGrid: solution,
    notes: List.generate(9, (_) => List.generate(9, (_) => <int>{})),
    timeElapsed: 10,
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

/// Regression coverage for the 3D cube's pause button. Two things this
/// guards: pausing gives no visual feedback (the puzzle stayed fully
/// visible/readable behind the sheet — fixed via [PausableBlur]), and the
/// only way to pause was an unlabeled-looking back arrow in the top bar —
/// there's now a dedicated pause icon next to the timer, matching the
/// regular game's `GameHeader`.
void main() {
  testWidgets(
    'tapping Pause blurs/shrinks the cube content and shows the pause sheet; Resume undoes both',
    (tester) async {
      final container = ProviderContainer(
        overrides: [
          storageServiceProvider.overrideWithValue(FakeStorageService()),
          audioServiceProvider.overrideWithValue(FakeAudioService()),
        ],
      );
      container.listen(cubeGameControllerProvider, (_, _) {});

      final cubeState = CubeGameState(
        cubeId: 'cube_1',
        faceStates: {
          for (final face in CubeFace.values)
            face.name: _playingFace('puzzle_${face.name}'),
        },
        activeFace: CubeFace.front,
        timeElapsed: 10,
        lastPlayed: DateTime(2026, 1, 1),
        lastSaved: DateTime(2026, 1, 1),
      );
      await container
          .read(cubeGameControllerProvider.notifier)
          .continueCubeGame(cubeState);

      // CubePauseSheet's Resume button dismisses via go_router's
      // context.pop() extension, which needs a real GoRouter ancestor.
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const CubeGameScreen(),
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            theme: ThemeData.light().copyWith(
              extensions: [AppThemeExtension.light],
            ),
            routerConfig: router,
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(
        tester.widget<PausableBlur>(find.byType(PausableBlur)).paused,
        false,
      );
      expect(
        find.byIcon(Icons.pause_rounded),
        findsOneWidget,
        reason: 'a visible pause button should sit next to the timer',
      );

      // The top bar's back arrow is *also* tooltipped 'Pause' (it pauses
      // too, as a secondary entry point) — Icons.pause_rounded picks out
      // the dedicated pause button next to the timer specifically.
      await tester.tap(find.byIcon(Icons.pause_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(
        tester.widget<PausableBlur>(find.byType(PausableBlur)).paused,
        true,
        reason: 'the cube content should blur/shrink while paused',
      );
      expect(find.text('3D Sudoku Paused'), findsOneWidget);

      await tester.tap(find.text('Resume'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(
        tester.widget<PausableBlur>(find.byType(PausableBlur)).paused,
        false,
        reason: 'the blur/shrink should lift once resumed',
      );
      expect(find.text('3D Sudoku Paused'), findsNothing);
      expect(tester.takeException(), isNull);

      // Unmount before disposing so State.dispose runs ahead of the
      // provider container teardown that cancels the cube timer.
      await tester.pumpWidget(const SizedBox.shrink());
      container.dispose();
    },
  );
}
