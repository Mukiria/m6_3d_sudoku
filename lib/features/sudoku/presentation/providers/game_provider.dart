import 'dart:async';

import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:m6_sudoku/features/sudoku/domain/entities/puzzle.dart';
import 'package:m6_sudoku/features/sudoku/domain/entities/game_state.dart';
import 'package:m6_sudoku/features/sudoku/engine/models/difficulty.dart';
import 'package:m6_sudoku/features/sudoku/engine/puzzle_session_ops.dart';
import 'package:m6_sudoku/features/sudoku/presentation/providers/sudoku_providers.dart';

part 'game_provider.g.dart';

/// Whether the auto-computed candidate ("pencil mark") numbers are shown in
/// empty cells. Purely a display preference — the underlying notes keep
/// being tracked and updated regardless, so toggling this back on
/// immediately reveals them again rather than losing anything. Reset to
/// `true` whenever a puzzle starts (see [GameController.newGame] and
/// [GameController.loadPuzzle]) so every new puzzle begins with pencil
/// marks visible.
final showPencilMarksProvider = StateProvider<bool>((ref) => true);

@riverpod
class GameController extends _$GameController {
  @override
  GameState? build() {
    ref.onDispose(() => _autoSaveTimer?.cancel());
    return null;
  }

  // Conflict/highlight detection, notes recomputation, and undo/redo replay
  // are shared with the cube-sudoku feature — see PuzzleSessionOps.
  final PuzzleSessionOps _ops = PuzzleSessionOps();

  Future<void> newGame(Difficulty difficulty) async {
    // Puzzle generation now runs on a background isolate (see
    // PuzzleLocalDataSource._generatePuzzleForDifficulty), which means this
    // method has a genuine async suspension point instead of resolving
    // within one microtask. gameControllerProvider is autoDispose, and
    // nothing guarantees a widget is watching it for the duration of a call
    // like this one (main.dart's startup loadGame call, for instance,
    // isn't watched by anything) — without keepAlive, autoDispose could
    // tear this controller down mid-generation, silently discarding the
    // result when `state = ...` below runs against an already-disposed
    // instance.
    final keepAliveLink = ref.keepAlive();
    try {
      final generatePuzzle = ref.read(generatePuzzleUseCaseProvider);
      final result = await generatePuzzle(difficulty.name);

      state = result.fold(
        (failure) => throw Exception(failure.message),
        (puzzle) => _freshGameState(puzzle, difficulty),
      );
      ref.read(showPencilMarksProvider.notifier).state = true;
      _startAutoSave();
    } finally {
      keepAliveLink.close();
    }
  }

  /// Loads a specific [puzzle] (used for the daily challenge) instead of
  /// generating a random one. Sessions whose [Puzzle.id] starts with
  /// `daily_` are kept out of the single regular-game save slot — see
  /// [_saveGame] — so playing today's challenge never clobbers a paused
  /// regular game, and vice versa.
  Future<void> loadPuzzle(
    Puzzle puzzle, {
    required Difficulty difficulty,
  }) async {
    state = _freshGameState(puzzle, difficulty);
    ref.read(showPencilMarksProvider.notifier).state = true;
    _startAutoSave();
  }

  /// The starting [GameState] for a brand-new session on [puzzle] — shared
  /// by [newGame] (a freshly generated puzzle) and [loadPuzzle] (a puzzle
  /// handed in already, e.g. the daily challenge), which otherwise differ
  /// only in how they obtain that puzzle. Delegates to [PuzzleSessionOps] so
  /// the cube-sudoku feature builds every face's starting state the exact
  /// same way.
  GameState _freshGameState(Puzzle puzzle, Difficulty difficulty) {
    return _ops.buildFreshGameState(puzzle, difficulty);
  }

  Future<void> loadGame() async {
    final getGameState = ref.read(getGameStateUseCaseProvider);
    final result = await getGameState();
    final loaded = result.fold((failure) => null, (gameState) => gameState);

    // Don't clobber a session that already started (e.g. the user began a
    // new game) while this load was in flight.
    if (state != null) return;

    state = loaded;
    if (state != null && state!.status == GameStatus.playing) {
      _startAutoSave();
    }
  }

  Future<void> continueGame(GameState savedState) async {
    state = savedState;
    _startAutoSave();
  }

  void selectCell(int row, int col) {
    if (state == null) return;

    final puzzle = state!.puzzle;
    // Don't select fixed/given cells
    if (puzzle.grid[row][col] != 0) return;

    state = state!.copyWith(
      selectedCell: CellPosition(row: row, col: col),
      highlightedCells: _ops.getHighlightedCells(row, col),
      conflictCells: _ops.getConflicts(state!.userGrid),
      lastPlayed: DateTime.now(),
    );
  }

  void selectNumber(int number) {
    if (state == null) return;
    if (state!.selectedCell == null) return;

    final isFixed =
        state!.puzzle.grid[state!.selectedCell!.row][state!
            .selectedCell!
            .col] !=
        0;
    if (isFixed) return;

    if (state!.isNoteMode) {
      toggleNote(state!.selectedCell!.row, state!.selectedCell!.col, number);
    } else {
      setValue(state!.selectedCell!.row, state!.selectedCell!.col, number);
    }
  }

  void setValue(int row, int col, int value) {
    if (state == null) return;

    final currentState = state!;
    final puzzle = currentState.puzzle;

    if (puzzle.grid[row][col] != 0) return; // Fixed cell

    final previousValue = currentState.userGrid[row][col];
    if (previousValue == value) return;

    final newGrid = _ops.copyGrid(currentState.userGrid);
    newGrid[row][col] = value;

    final isCorrect = puzzle.solution[row][col] == value;
    final newMistakes =
        isCorrect ? currentState.mistakes : currentState.mistakes + 1;

    // Auto-remove candidates from affected cells using bitmasks
    final newNotesGrid = _ops.autoRemoveCandidatesBitmask(
      currentState.notes,
      row,
      col,
      value,
    );

    final newMove = Move(
      row: row,
      col: col,
      previousValue: previousValue,
      newValue: value,
      type: MoveType.value,
      timestamp: DateTime.now(),
    );

    state = state!.copyWith(
      userGrid: newGrid,
      notes: newNotesGrid,
      mistakes: newMistakes,
      conflictCells: _ops.getConflicts(newGrid),
      moveHistory: [...currentState.moveHistory, newMove],
      redoStack: [],
      lastPlayed: DateTime.now(),
      lastSaved: DateTime.now(),
    );

    // Auto-save on every move
    _saveGame();

    // Play sound
    if (isCorrect) {
      ref.read(audioServiceProvider).playClick();
    } else {
      ref.read(audioServiceProvider).playError();
      // The sound and the cell's own color/border change are enough for a
      // sighted player, but a screen-reader user only discovers a mistake
      // by re-exploring the cell — this announces it immediately instead.
      SemanticsService.announce('Incorrect', TextDirection.ltr);
    }

    if (newMistakes >= 3) {
      state = state!.copyWith(status: GameStatus.failed);
      SemanticsService.announce(
        'Game over. Too many mistakes.',
        TextDirection.ltr,
      );
    } else if (_isGridComplete(newGrid, puzzle.solution)) {
      state = state!.copyWith(status: GameStatus.completed);
      _saveGame();
      // Every achievement this completion can affect is collected into one
      // delta map and applied in a single batched write (see
      // _incrementAchievements) rather than one write per achievement, so
      // there's exactly one read-modify-write cycle against achievement
      // storage per completion — not several racing ones.
      final achievementDeltas = ref.read(
        evaluateAchievementDeltasUseCaseProvider,
      )(currentState);
      _completeDailyChallengeIfNeeded(currentState, achievementDeltas);
      _incrementAchievements(achievementDeltas);
      ref.read(audioServiceProvider).playWin();
      SemanticsService.announce('Puzzle solved!', TextDirection.ltr);
    }
  }

  /// Records completion + streak/stats for the daily challenge, and blocks
  /// the puzzle from being replayed for credit: [CompleteDailyChallengeUseCase]
  /// rejects a second completion for the same date at the storage layer.
  /// Adds the 'daily_champion' progress into [achievementDeltas] rather than
  /// writing it separately, so it lands in the same atomic achievement write
  /// as every other unlock from this completion.
  void _completeDailyChallengeIfNeeded(
    GameState completedState,
    Map<String, int> achievementDeltas,
  ) {
    final puzzleId = completedState.puzzleId;
    if (!puzzleId.startsWith('daily_')) return;

    final date = puzzleId.substring('daily_'.length);
    ref.read(completeDailyChallengeUseCaseProvider)(
      date: date,
      timeElapsed: completedState.timeElapsed,
      mistakes: completedState.mistakes,
      hintsUsed: completedState.hintsUsed,
    );
    ref.invalidate(dailyChallengeProvider);
    ref.invalidate(dailyChallengeStatsProvider);
    achievementDeltas['daily_champion'] =
        (achievementDeltas['daily_champion'] ?? 0) + 1;
  }

  void toggleNote(int row, int col, int note) {
    if (state == null) return;

    final currentState = state!;
    final puzzle = currentState.puzzle;
    // Don't add notes to fixed/given cells
    if (puzzle.grid[row][col] != 0) return;

    final currentNotes = currentState.notes[row][col];
    final newNotes = Set<int>.from(currentNotes);

    if (newNotes.contains(note)) {
      newNotes.remove(note);
    } else {
      newNotes.add(note);
    }

    final newNotesGrid = _ops.copyNotesGrid(currentState.notes);
    newNotesGrid[row][col] = newNotes;

    state = currentState.copyWith(
      notes: newNotesGrid,
      moveHistory: [
        ...currentState.moveHistory,
        Move(
          row: row,
          col: col,
          previousValue: null,
          newValue: note,
          type: MoveType.note,
          timestamp: DateTime.now(),
        ),
      ],
      lastPlayed: DateTime.now(),
      lastSaved: DateTime.now(),
    );
    ref.read(audioServiceProvider).playClick();
    _saveGame();
  }

  void clearCell(int row, int col) {
    if (state == null) return;

    final currentState = state!;

    if (currentState.puzzle.grid[row][col] != 0) return; // Fixed cell

    final previousValue = currentState.userGrid[row][col];
    if (previousValue == 0 && currentState.notes[row][col].isEmpty) return;

    final newGrid = _ops.copyGrid(currentState.userGrid);
    newGrid[row][col] = 0;

    final newNotesGrid = _ops.copyNotesGrid(currentState.notes);
    newNotesGrid[row][col] = <int>{};

    state = currentState.copyWith(
      userGrid: newGrid,
      notes: newNotesGrid,
      moveHistory: [
        ...currentState.moveHistory,
        Move(
          row: row,
          col: col,
          previousValue: previousValue,
          newValue: 0,
          type: MoveType.clear,
          timestamp: DateTime.now(),
        ),
      ],
      // A new move invalidates whatever was redoable — same as setValue —
      // so a stale redo entry can't later reapply a value this clear just
      // erased.
      redoStack: [],
      lastPlayed: DateTime.now(),
      lastSaved: DateTime.now(),
    );
    _saveGame();
  }

  Future<void> useHint() async {
    if (state == null) return;

    final currentState = state!;

    final getHint = ref.read(getHintUseCaseProvider);
    final result = await getHint(state: currentState);

    result.fold((failure) => null, (hint) {
      if (hint != null) {
        // Add penalty time (15 seconds for logical hints, 30 for direct reveal)
        final penalty = hint.hintType == HintType.directReveal ? 30 : 15;

        setValue(hint.row, hint.col, hint.value!);
        state = state!.copyWith(
          hintsUsed: currentState.hintsUsed + 1,
          penaltyTime: currentState.penaltyTime + penalty,
          timeElapsed: currentState.timeElapsed + penalty,
          hintState: HintState(
            type: hint.hintType,
            cell: CellPosition(row: hint.row, col: hint.col),
            value: hint.value!,
            explanation: hint.explanation,
            shownAt: DateTime.now(),
          ),
          moveHistory: [
            ...currentState.moveHistory,
            Move(
              row: hint.row,
              col: hint.col,
              previousValue: null,
              newValue: hint.value,
              type: MoveType.hint,
              timestamp: DateTime.now(),
            ),
          ],
          lastPlayed: DateTime.now(),
          lastSaved: DateTime.now(),
        );
        ref.read(audioServiceProvider).playHint();
        SemanticsService.announce(
          'Hint: ${hint.explanation}',
          TextDirection.ltr,
        );
      }
    });
  }

  void undo() {
    if (state == null || state!.moveHistory.isEmpty) return;

    final currentState = state!;
    final lastMove = currentState.moveHistory.last;
    final previousMoves = currentState.moveHistory.sublist(
      0,
      currentState.moveHistory.length - 1,
    );

    final applied = _ops.applyHistoryMove(currentState, lastMove, isUndo: true);

    state = currentState.copyWith(
      userGrid: applied.grid,
      notes: applied.notes,
      mistakes: applied.mistakes,
      hintsUsed: applied.hintsUsed,
      moveHistory: previousMoves,
      redoStack: [lastMove, ...currentState.redoStack],
      status: GameStatus.playing,
      lastPlayed: DateTime.now(),
      lastSaved: DateTime.now(),
    );
    ref.read(audioServiceProvider).playClick();
    _saveGame();
  }

  void redo() {
    if (state == null || state!.redoStack.isEmpty) return;

    final currentState = state!;
    final nextMove = currentState.redoStack.first;
    final remainingRedo = currentState.redoStack.sublist(1);

    final applied = _ops.applyHistoryMove(currentState, nextMove, isUndo: false);

    state = currentState.copyWith(
      userGrid: applied.grid,
      notes: applied.notes,
      mistakes: applied.mistakes,
      hintsUsed: applied.hintsUsed,
      moveHistory: [...currentState.moveHistory, nextMove],
      redoStack: remainingRedo,
      status: GameStatus.playing,
      lastPlayed: DateTime.now(),
      lastSaved: DateTime.now(),
    );
    ref.read(audioServiceProvider).playClick();
    _saveGame();
  }


  void toggleNoteMode() {
    if (state == null) return;
    state = state!.copyWith(
      isNoteMode: !state!.isNoteMode,
      lastSaved: DateTime.now(),
    );
    _saveGame();
  }

  void setSelectedNumber(int? number) {
    if (state == null) return;
    state = state!.copyWith(selectedNumber: number);
  }

  void incrementTimer() {
    if (state == null) return;
    if (state!.status != GameStatus.playing) return;

    state = state!.copyWith(
      timeElapsed: state!.timeElapsed + 1,
      lastPlayed: DateTime.now(),
    );
  }

  void pause() {
    if (state == null) return;
    state = state!.copyWith(status: GameStatus.paused);
    _saveGame();
    ref.read(audioServiceProvider).playPause();
  }

  void resume() {
    if (state == null) return;
    state = state!.copyWith(
      status: GameStatus.playing,
      lastPlayed: DateTime.now(),
    );
    ref.read(audioServiceProvider).playResume();
  }

  bool get _isDailyChallenge => state?.puzzleId.startsWith('daily_') ?? false;

  void _saveGame() {
    if (state == null) return;
    // The daily challenge shares no slot with the regular saved game — see
    // loadPuzzle's doc comment.
    if (_isDailyChallenge) return;
    final saveGame = ref.read(saveGameStateUseCaseProvider);
    saveGame(state!.copyWith(lastSaved: DateTime.now()));
  }

  Timer? _autoSaveTimer;

  void _startAutoSave() {
    // Periodic auto-save as backup (every 30 seconds). Cancelable — see
    // build()'s ref.onDispose — because an unguarded Future.delayed here
    // would keep firing after this controller (autoDispose) is torn down
    // and try to `ref.read` through an already-disposed ref, throwing.
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(seconds: 30), () {
      if (state != null && state!.status == GameStatus.playing) {
        _saveGame();
        _startAutoSave();
      }
    });
  }

  // Delegates to the existing domain usecase rather than keeping a private
  // copy — CheckCompletionUseCase already implemented this exact check but
  // had no caller; this used to silently duplicate it here instead.
  bool _isGridComplete(List<List<int>> grid, List<List<int>> solution) {
    final result = ref.read(
      checkCompletionUseCaseProvider,
    )(grid: grid, solution: solution);
    return result.fold((_) => false, (complete) => complete);
  }

  void clearHintState() {
    if (state == null) return;
    state = state!.copyWith(hintState: null);
  }

  /// Applies [deltas] in one batched write and queues every achievement
  /// that write unlocked for [AchievementUnlockBanner] to animate.
  Future<void> _incrementAchievements(Map<String, int> deltas) async {
    final result = await ref.read(
      incrementAchievementProgressBatchUseCaseProvider,
    )(deltas);
    result.fold((_) {}, (unlocked) {
      for (final achievement in unlocked) {
        try {
          ref.read(achievementUnlockQueueProvider.notifier).push(achievement);
        } on StateError {
          // gameControllerProvider is autodispose: completing a game
          // navigates away almost immediately, which can dispose this
          // controller before this await resumes. The achievement is
          // already persisted at this point; there's just no screen left
          // to animate the unlock on.
        }
      }
    });
  }
}

/// Ticks gameControllerProvider's timeElapsed once a second while a game is
/// playing. Holds no timer state of its own — GameState.timeElapsed is the
/// only source of truth for elapsed time, and no widget ever read this
/// controller's own tick count, so it's a plain Timer wrapper rather than a
/// second, redundant copy of the clock.
class TimerController {
  TimerController(this.ref);

  final Ref ref;
  Timer? _timer;

  void start() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final gameState = ref.read(gameControllerProvider);
      if (gameState != null && gameState.status == GameStatus.playing) {
        ref.read(gameControllerProvider.notifier).incrementTimer();
      }
    });
  }

  void pause() {
    _timer?.cancel();
    _timer = null;
  }

  void resume() {
    start();
  }

  void reset() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() {
    _timer?.cancel();
  }
}

final timerControllerProvider = Provider<TimerController>((ref) {
  final controller = TimerController(ref);
  ref.onDispose(controller.dispose);
  return controller;
});
