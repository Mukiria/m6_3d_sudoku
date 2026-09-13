import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:m6_sudoku/core/theme/app_theme_extension.dart';
import 'package:m6_sudoku/features/sudoku/domain/entities/game_state.dart';
import 'package:m6_sudoku/features/sudoku/domain/entities/puzzle.dart';
import 'package:m6_sudoku/features/sudoku/engine/models/difficulty.dart';
import 'package:m6_sudoku/features/sudoku/presentation/providers/game_provider.dart';
import 'package:m6_sudoku/features/sudoku/presentation/providers/sudoku_providers.dart';
import 'package:m6_sudoku/features/sudoku/presentation/screens/game_screen.dart';
import 'package:m6_sudoku/shared/widgets/pausable_blur.dart';

import '../../../../fakes/fake_services.dart';

GameState _buildPlayingState() {
  final solution = List.generate(
    9,
    (r) => List.generate(9, (c) => ((r + c) % 9) + 1),
  );
  final puzzle = Puzzle(
    id: 'test_puzzle',
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
    timeElapsed: 42,
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

/// Regression coverage for the pause button: pausing must actually stop the
/// game (status + timer), blur the board so it can't be read, and resuming
/// (by any exit from the sheet) must undo all of that — none of which
/// happened before, since GameController.pause()/resume() were built but
/// never wired to the UI, and the `_showPauseMenu` flag that was meant to
/// drive a blur was set outside setState and never read anywhere.
void main() {
  testWidgets(
    'tapping Pause blurs the board and pauses the game; Resume un-blurs and resumes it',
    (tester) async {
      final container = ProviderContainer(
        overrides: [
          storageServiceProvider.overrideWithValue(FakeStorageService()),
          audioServiceProvider.overrideWithValue(FakeAudioService()),
        ],
      );
      container.listen(gameControllerProvider, (_, _) {});
      await container
          .read(gameControllerProvider.notifier)
          .continueGame(_buildPlayingState());

      // PauseMenu's Resume button dismisses the sheet via go_router's
      // context.pop() extension, which throws without a real GoRouter
      // ancestor — a plain MaterialApp(home: ...) isn't enough here.
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder:
                (context, state) => const GameScreen(difficulty: 'continue'),
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
        container.read(gameControllerProvider)!.status,
        GameStatus.playing,
      );

      await tester.tap(find.byTooltip('Pause'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(
        tester.widget<PausableBlur>(find.byType(PausableBlur)).paused,
        true,
        reason: 'the board should blur/shrink while paused',
      );
      expect(container.read(gameControllerProvider)!.status, GameStatus.paused);
      expect(find.text('Game Paused'), findsOneWidget);

      await tester.tap(find.text('Resume'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(
        tester.widget<PausableBlur>(find.byType(PausableBlur)).paused,
        false,
        reason: 'the blur/shrink should lift once resumed',
      );
      expect(
        container.read(gameControllerProvider)!.status,
        GameStatus.playing,
      );
      expect(tester.takeException(), isNull);

      // Unmount before disposing so State.dispose runs ahead of the
      // provider container teardown that cancels the timer.
      await tester.pumpWidget(const SizedBox.shrink());
      container.dispose();
    },
  );
}
