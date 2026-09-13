import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:m6_sudoku/core/constants/app_constants.dart';
import 'package:m6_sudoku/core/routing/app_router.dart';
import 'package:m6_sudoku/features/sudoku/domain/entities/game_state.dart';
import 'package:m6_sudoku/features/sudoku/engine/models/difficulty.dart';
import 'package:m6_sudoku/features/sudoku/presentation/providers/game_provider.dart';
import 'package:m6_sudoku/features/sudoku/presentation/providers/sudoku_providers.dart';
import 'package:m6_sudoku/features/sudoku/presentation/widgets/achievement_unlock_banner.dart';
import 'package:m6_sudoku/features/sudoku/presentation/widgets/game_header.dart';
import 'package:m6_sudoku/features/sudoku/presentation/widgets/game_top_bar.dart';
import 'package:m6_sudoku/features/sudoku/presentation/widgets/hint_overlay.dart';
import 'package:m6_sudoku/features/sudoku/presentation/widgets/number_pad.dart';
import 'package:m6_sudoku/features/sudoku/presentation/widgets/pause_menu.dart';
import 'package:m6_sudoku/features/sudoku/presentation/widgets/sudoku_board.dart';
import 'package:m6_sudoku/shared/widgets/buttons.dart';
import 'package:m6_sudoku/shared/widgets/glass/glass_surface.dart';
import 'package:m6_sudoku/shared/widgets/pausable_blur.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key, required this.difficulty});

  final String difficulty;

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  /// Whether the pause bottom sheet is currently up — drives the blurred
  /// overlay in [build] so the puzzle can't be read behind it while paused,
  /// and is the single signal (set in [_showPauseOverlay]) for pausing and
  /// resuming both the game status and the timer.
  bool _showPauseMenu = false;
  bool _hasNavigated = false;
  bool _showHintOverlay = false;

  /// True once the initial "continue" hand-off (see [_startSession]) has
  /// been consumed, so a later retry-after-failure knows to actually
  /// regenerate a puzzle instead of no-op'ing again.
  bool _initialContinueHandled = false;

  /// Bumped whenever the selected cell changes, so [SudokuBoard] can key its
  /// per-cell fade animation off it and restart the 3-second highlight fade
  /// from full strength on every new selection.
  int _selectionEpoch = 0;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await _startSession();
      } catch (e) {
        if (mounted) _handleSessionLoadFailure(e);
        return;
      }
      // _startSession's daily-challenge branch awaits a provider future and
      // a puzzle load — either can outlast this screen (the user backs out,
      // a hot restart lands mid-request, or on web the browser's own back
      // button pops the route without this widget's PopScope seeing it
      // first). Reading a provider through `ref` on a since-disposed
      // ConsumerState throws StateError (flutter_riverpod's
      // `_assertNotDisposed`, not merely a debug assert), so this check
      // has to happen before touching `ref` again, not after.
      if (!mounted) return;
      ref.read(timerControllerProvider).start();
    });
  }

  /// Loads a puzzle for [widget.difficulty] unless a matching session is
  /// already in progress.
  ///
  /// `widget.difficulty` is one of: a `Difficulty.name` (new regular game),
  /// a `daily_<date>` id (daily challenge — also its own puzzleId, so the
  /// equality check below doubles as "already playing today's challenge"),
  /// or the sentinel `'continue'` from HomeScreen's Continue Game button,
  /// which already loaded the exact session into gameControllerProvider
  /// before navigating here — regular puzzleIds are timestamps, not
  /// difficulty names, so they can never be matched by equality the way the
  /// daily id can, hence the sentinel instead of trying to encode it.
  Future<void> _startSession() async {
    if (widget.difficulty == 'continue' && !_initialContinueHandled) {
      _initialContinueHandled = true;
      return;
    }

    final gameState = ref.read(gameControllerProvider);
    final mode =
        widget.difficulty == 'continue'
            ? (gameState?.puzzleId.startsWith('daily_') == true
                ? gameState!.puzzleId
                : (gameState?.difficulty.name ?? AppConstants.difficultyEasy))
            : widget.difficulty;

    final hasMatchingSession =
        gameState != null &&
        gameState.status == GameStatus.playing &&
        gameState.puzzleId == mode;
    if (hasMatchingSession) return;

    if (mode.startsWith('daily_')) {
      final challenge = await ref.read(dailyChallengeProvider.future);
      // Same disposal race as the caller's post-_startSession read, one
      // await earlier: don't touch `ref` again after a suspension point
      // without checking the widget is still around to own it.
      if (!mounted) return;
      await ref
          .read(gameControllerProvider.notifier)
          .loadPuzzle(challenge.puzzle, difficulty: Difficulty.medium);
    } else {
      final difficulty = Difficulty.values.firstWhere(
        (d) => d.name == mode,
        orElse: () => Difficulty.easy,
      );
      await ref.read(gameControllerProvider.notifier).newGame(difficulty);
    }
  }

  /// [_startSession]'s two failure-prone calls — [dailyChallengeProvider]
  /// and `newGame` — are both documented to throw on a real, reachable
  /// failure (a corrupt/missing daily challenge; `newGame`'s own generator
  /// throws if it can't produce a valid puzzle), and neither caller used to
  /// catch that. Left uncaught, it surfaced as an unhandled exception with
  /// the player stuck on the loading spinner forever — this at least gets
  /// them back to a screen they can act from, with a visible reason why.
  void _handleSessionLoadFailure(Object error) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Failed to load puzzle: $error')));
    context.go(AppRoutes.home);
  }

  /// Pauses the game (status + timer) and shows the pause sheet over a
  /// blurred board — see [_showPauseMenu]. Resumes both, unconditionally,
  /// once the sheet closes by any route (Resume, swipe-to-dismiss, tapping
  /// the scrim, or the system back gesture re-invoking this while already
  /// open is guarded against below): Restart/Main Menu each replace or
  /// leave the session in their own way moments later, so resuming first is
  /// harmless, and it's what guarantees paused never gets stuck as the
  /// on-screen or saved state.
  void _showPauseOverlay() {
    if (_showPauseMenu) return;
    setState(() => _showPauseMenu = true);
    ref.read(gameControllerProvider.notifier).pause();
    ref.read(timerControllerProvider).pause();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      // PauseMenu draws its own drag handle as part of its glass sheet —
      // without this, the theme's default showDragHandle:true (see
      // bottomSheetTheme in app_theme.dart) draws a second one behind it.
      // The old opaque sheet background hid that redundant handle; the
      // translucent glass one doesn't.
      showDragHandle: false,
      builder: (context) => const PauseMenu(),
    ).whenComplete(() {
      if (!mounted) return;
      setState(() => _showPauseMenu = false);
      ref.read(gameControllerProvider.notifier).resume();
      ref.read(timerControllerProvider).resume();
    });
  }

  void _checkGameStatus(GameState gameState) {
    if (_hasNavigated) return;

    if (gameState.status == GameStatus.completed) {
      _hasNavigated = true;
      ref.read(timerControllerProvider).pause();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.go(
            AppRoutes.completion,
            extra: {
              'time': gameState.timeElapsed,
              'mistakes': gameState.mistakes,
              'hintsUsed': gameState.hintsUsed,
              'difficulty': gameState.difficulty.name,
            },
          );
        }
      });
    } else if (gameState.status == GameStatus.failed) {
      _hasNavigated = true;
      ref.read(timerControllerProvider).pause();
      _showGameOverDialog();
    }
  }

  void _showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: const Text('Game Over'),
            content: const Text('You made 3 mistakes. Better luck next time!'),
            actions: [
              TextButton(
                onPressed: () {
                  context.pop();
                  context.go(AppRoutes.home);
                },
                child: const Text('Main Menu'),
              ),
              TextButton(
                onPressed: () async {
                  context.pop();
                  // Game-over state is never GameStatus.playing, so
                  // _startSession always reloads a fresh session here —
                  // regenerating a puzzle is genuinely slow on the harder
                  // difficulties, so there's a real window for the player
                  // to navigate away before this resolves.
                  try {
                    await _startSession();
                  } catch (e) {
                    if (mounted) _handleSessionLoadFailure(e);
                    return;
                  }
                  if (!mounted) return;
                  ref.read(timerControllerProvider).reset();
                  ref.read(timerControllerProvider).start();
                  _hasNavigated = false;
                },
                child: const Text('Try Again'),
              ),
            ],
          ),
    );
  }

  void _checkHintState(GameState gameState) {
    if (gameState.hintState != null && !_showHintOverlay) {
      _showHintOverlay = true;
      _showHintOverlayDialog(gameState.hintState!);
    }
  }

  void _showHintOverlayDialog(HintState hintState) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => HintOverlay(
            hintState: hintState,
            onDismiss: () {
              Navigator.of(context).pop();
              setState(() {
                _showHintOverlay = false;
              });
              // Clear hint state after dismissing
              ref.read(gameControllerProvider.notifier).clearHintState();
            },
          ),
    );
  }

  static List<List<Set<int>>> _emptyNotesGrid() =>
      List.generate(9, (_) => List.generate(9, (_) => <int>{}));

  @override
  Widget build(BuildContext context) {
    // Only the "is there a session at all" bit is watched here — everything
    // else below is read per-section via its own Consumer + select, so a
    // change to one slice of GameState (most notably the once-a-second
    // timer tick) only rebuilds the small section that actually displays
    // it, instead of tearing down and rebuilding the whole screen —
    // including the 81-cell SudokuBoard — every second.
    final hasSession = ref.watch(
      gameControllerProvider.select((s) => s != null),
    );

    ref.listen<GameState?>(gameControllerProvider, (previous, next) {
      if (next?.selectedCell != previous?.selectedCell) {
        setState(() => _selectionEpoch++);
      }
      if (next != null &&
          (next.status != previous?.status ||
              next.hintState != previous?.hintState)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _checkGameStatus(next);
          _checkHintState(next);
        });
      }
    });

    if (!hasSession) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Covers the case where a session is already present on the very first
    // build (e.g. resumed via "Continue"), which the status/hintState-delta
    // listen above wouldn't fire for on its own.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final gameState = ref.read(gameControllerProvider);
      if (gameState != null) {
        _checkGameStatus(gameState);
        _checkHintState(gameState);
      }
    });

    final colorScheme = Theme.of(context).colorScheme;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _showPauseOverlay();
        }
      },
      child: Scaffold(
        backgroundColor: colorScheme.surfaceContainerHighest,
        body: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  GlassSurface(
                    margin: const EdgeInsets.symmetric(
                      horizontal: AppConstants.spacingMd,
                      vertical: AppConstants.spacingSm,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.spacingMd,
                      vertical: AppConstants.spacingSm,
                    ),
                    child: Column(
                      children: [
                        GameTopBar(onBack: _showPauseOverlay),
                        Divider(
                          height: AppConstants.spacingMd,
                          color: colorScheme.outlineVariant.withValues(
                            alpha: 0.4,
                          ),
                        ),
                        Consumer(
                          builder: (context, ref, _) {
                            final header = ref.watch(
                              gameControllerProvider.select(
                                (s) => (
                                  difficulty:
                                      s!.puzzleId.startsWith('daily_')
                                          ? 'daily'
                                          : s.difficulty.name,
                                  timeElapsed: s.timeElapsed,
                                  mistakes: s.mistakes,
                                ),
                              ),
                            );
                            return GameHeader(
                              difficulty: header.difficulty,
                              timeElapsed: header.timeElapsed,
                              mistakes: header.mistakes,
                              onPause: _showPauseOverlay,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: PausableBlur(
                      paused: _showPauseMenu,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppConstants.spacingSm,
                        ),
                        child: Consumer(
                          builder: (context, ref, _) {
                            final board = ref.watch(
                              gameControllerProvider.select(
                                (s) => (
                                  puzzle: s!.puzzle,
                                  userGrid: s.userGrid,
                                  notes: s.notes,
                                  selectedCell: s.selectedCell,
                                  highlightedCells: s.highlightedCells,
                                  conflictCells: s.conflictCells,
                                  isNoteMode: s.isNoteMode,
                                ),
                              ),
                            );
                            final showPencilMarks = ref.watch(
                              showPencilMarksProvider,
                            );
                            return SudokuBoard(
                              puzzle: board.puzzle,
                              userGrid: board.userGrid,
                              notes:
                                  showPencilMarks
                                      ? board.notes
                                      : _emptyNotesGrid(),
                              selectedCell: board.selectedCell,
                              highlightedCells: board.highlightedCells,
                              conflictCells: board.conflictCells,
                              isNoteMode: board.isNoteMode,
                              selectionEpoch: _selectionEpoch,
                              onCellTap:
                                  (row, col) => ref
                                      .read(gameControllerProvider.notifier)
                                      .selectCell(row, col),
                              onCellLongPress: (row, col) {
                                final gameState = ref.read(
                                  gameControllerProvider,
                                );
                                if (gameState != null) {
                                  _showCellOptions(row, col, gameState);
                                }
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingMd),
                  Consumer(
                    builder: (context, ref, _) {
                      // userGrid is selected raw (not the derived
                      // disabledNumbers set) so this only recomputes when
                      // the grid's object identity actually changes —
                      // GameState.copyWith keeps the same userGrid reference
                      // for fields it isn't touching (e.g. every timer
                      // tick), and a freshly-allocated Set built inside the
                      // selector itself would never compare equal across
                      // calls, defeating select's dedup entirely.
                      final pad = ref.watch(
                        gameControllerProvider.select(
                          (s) => (
                            selectedNumber: s!.selectedNumber,
                            isNoteMode: s.isNoteMode,
                            userGrid: s.userGrid,
                          ),
                        ),
                      );
                      return NumberPad(
                        selectedNumber: pad.selectedNumber,
                        onNumberSelected:
                            (number) => ref
                                .read(gameControllerProvider.notifier)
                                .selectNumber(number),
                        onNoteModeToggle:
                            () =>
                                ref
                                    .read(gameControllerProvider.notifier)
                                    .toggleNoteMode(),
                        isNoteMode: pad.isNoteMode,
                        disabledNumbers: _getDisabledNumbers(pad.userGrid),
                      );
                    },
                  ),
                  const SizedBox(height: AppConstants.spacingMd),
                ],
              ),
            ),
            const AchievementUnlockBanner(),
          ],
        ),
      ),
    );
  }

  void _showCellOptions(int row, int col, GameState gameState) {
    final isFixed = gameState.puzzle.grid[row][col] != 0;
    if (isFixed) return;

    showModalBottomSheet(
      context: context,
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(AppConstants.spacingLg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Cell Options',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppConstants.spacingLg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    AppButton(
                      onPressed: () {
                        ref
                            .read(gameControllerProvider.notifier)
                            .clearCell(row, col);
                        Navigator.pop(context);
                      },
                      variant: AppButtonVariant.outlined,
                      child: const Text('Clear'),
                    ),
                    AppButton(
                      onPressed: () {
                        // Toggle note mode for this cell
                        Navigator.pop(context);
                      },
                      variant: AppButtonVariant.filled,
                      child: Text(
                        gameState.notes[row][col].isNotEmpty
                            ? 'Clear Notes'
                            : 'Add Notes',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
    );
  }

  Map<int, int> _getNumberCounts(List<List<int>> userGrid) {
    final counts = <int, int>{};
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        final val = userGrid[r][c];
        if (val != 0) {
          counts[val] = (counts[val] ?? 0) + 1;
        }
      }
    }
    // Return remaining counts (9 - used)
    final remaining = <int, int>{};
    for (int i = 1; i <= 9; i++) {
      remaining[i] = 9 - (counts[i] ?? 0);
    }
    return remaining;
  }

  Set<int> _getDisabledNumbers(List<List<int>> userGrid) {
    final disabled = <int>{};
    final counts = _getNumberCounts(userGrid);
    for (int i = 1; i <= 9; i++) {
      if ((counts[i] ?? 9) <= 0) {
        disabled.add(i);
      }
    }
    return disabled;
  }
}
