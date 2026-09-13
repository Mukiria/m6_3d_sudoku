import 'dart:async';

import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:m6_sudoku/features/cube_sudoku/domain/entities/cube_face.dart';
import 'package:m6_sudoku/features/cube_sudoku/domain/entities/cube_game_state.dart';
import 'package:m6_sudoku/features/cube_sudoku/presentation/providers/cube_sudoku_providers.dart';
import 'package:m6_sudoku/features/statistics/presentation/providers/statistics_provider.dart';
import 'package:m6_sudoku/features/sudoku/domain/entities/game_state.dart';
import 'package:m6_sudoku/features/sudoku/domain/entities/puzzle.dart';
import 'package:m6_sudoku/features/sudoku/engine/models/difficulty.dart';
import 'package:m6_sudoku/features/sudoku/engine/puzzle_session_ops.dart';
import 'package:m6_sudoku/features/sudoku/presentation/providers/game_provider.dart'
    show showPencilMarksProvider;
import 'package:m6_sudoku/features/sudoku/presentation/providers/sudoku_providers.dart'
    show
        audioServiceProvider,
        checkCompletionUseCaseProvider,
        getHintUseCaseProvider;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'cube_game_provider.g.dart';

@riverpod
class CubeGameController extends _$CubeGameController {
  @override
  CubeGameState? build() {
    ref.onDispose(() => _autoSaveTimer?.cancel());
    return null;
  }

  // One PuzzleSessionOps per face, each with its own highlighted/conflict
  // cache — sharing a single instance across all six faces would thrash
  // that cache on every face switch instead of each face keeping its own.
  final Map<CubeFace, PuzzleSessionOps> _ops = {
    for (final face in CubeFace.values) face: PuzzleSessionOps(),
  };

  Timer? _autoSaveTimer;

  Future<void> newCubeGame(Map<CubeFace, Difficulty> difficulties) async {
    // See GameController.newGame's doc comment: generation now has a real
    // async suspension point (compute() isolates), so this keepAlive stops
    // gameControllerProvider's autoDispose from tearing this controller
    // down mid-generation.
    final keepAliveLink = ref.keepAlive();
    try {
      final generate = ref.read(generateCubePuzzlesUseCaseProvider);
      final result = await generate(difficulties);

      state = result.fold(
        (failure) => throw Exception(failure.message),
        (puzzles) => _freshCubeGameState(puzzles, difficulties),
      );
      ref.read(showPencilMarksProvider.notifier).state = true;
      _startAutoSave();
    } finally {
      keepAliveLink.close();
    }
  }

  CubeGameState _freshCubeGameState(
    Map<CubeFace, Puzzle> puzzles,
    Map<CubeFace, Difficulty> difficulties,
  ) {
    final faceStates = {
      for (final face in CubeFace.values)
        face.name: _ops[face]!.buildFreshGameState(
          puzzles[face]!,
          difficulties[face]!,
        ),
    };
    return CubeGameState(
      cubeId: DateTime.now().millisecondsSinceEpoch.toString(),
      faceStates: faceStates,
      activeFace: CubeFace.front,
      timeElapsed: 0,
      lastPlayed: DateTime.now(),
      lastSaved: DateTime.now(),
    );
  }

  /// Restores a persisted cube session, same semantics as
  /// [GameController.loadGame] — a no-op if some session already started
  /// (e.g. the user began a new cube) while this load was in flight.
  Future<void> loadCubeGame() async {
    final getState = ref.read(getCubeGameStateUseCaseProvider);
    final result = await getState();
    final loaded = result.fold((failure) => null, (s) => s);

    if (state != null) return;

    state = loaded;
    if (state != null && !state!.isComplete) {
      _startAutoSave();
    }
  }

  Future<void> continueCubeGame(CubeGameState savedState) async {
    state = savedState;
    _startAutoSave();
  }

  void setActiveFace(CubeFace face) {
    if (state == null || state!.activeFace == face) return;
    state = state!.copyWith(activeFace: face);
  }

  void selectCell(CubeFace face, int row, int col) {
    if (state == null) return;
    final faceState = state!.faceState(face);
    // Don't select fixed/given cells or cells on a face that's no longer
    // playable.
    if (faceState.puzzle.grid[row][col] != 0) return;
    if (faceState.status != GameStatus.playing) return;

    final ops = _ops[face]!;
    final updated = faceState.copyWith(
      selectedCell: CellPosition(row: row, col: col),
      highlightedCells: ops.getHighlightedCells(row, col),
      conflictCells: ops.getConflicts(faceState.userGrid),
      lastPlayed: DateTime.now(),
    );
    state = state!.withFaceState(face, updated);
  }

  void selectNumber(CubeFace face, int number) {
    if (state == null) return;
    final faceState = state!.faceState(face);
    if (faceState.selectedCell == null) return;

    final isFixed =
        faceState.puzzle.grid[faceState.selectedCell!.row][faceState
            .selectedCell!
            .col] !=
        0;
    if (isFixed) return;

    if (faceState.isNoteMode) {
      toggleNote(
        face,
        faceState.selectedCell!.row,
        faceState.selectedCell!.col,
        number,
      );
    } else {
      setValue(
        face,
        faceState.selectedCell!.row,
        faceState.selectedCell!.col,
        number,
      );
    }
  }

  void setValue(CubeFace face, int row, int col, int value) {
    if (state == null) return;
    final ops = _ops[face]!;
    final currentFaceState = state!.faceState(face);
    final puzzle = currentFaceState.puzzle;

    if (puzzle.grid[row][col] != 0) return; // Fixed cell
    if (currentFaceState.status != GameStatus.playing) return;

    final previousValue = currentFaceState.userGrid[row][col];
    if (previousValue == value) return;

    final newGrid = ops.copyGrid(currentFaceState.userGrid);
    newGrid[row][col] = value;

    final isCorrect = puzzle.solution[row][col] == value;
    final newMistakes =
        isCorrect ? currentFaceState.mistakes : currentFaceState.mistakes + 1;

    final newNotesGrid = ops.autoRemoveCandidatesBitmask(
      currentFaceState.notes,
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

    var updatedFaceState = currentFaceState.copyWith(
      userGrid: newGrid,
      notes: newNotesGrid,
      mistakes: newMistakes,
      conflictCells: ops.getConflicts(newGrid),
      moveHistory: [...currentFaceState.moveHistory, newMove],
      redoStack: [],
      lastPlayed: DateTime.now(),
      lastSaved: DateTime.now(),
    );

    if (isCorrect) {
      ref.read(audioServiceProvider).playClick();
    } else {
      ref.read(audioServiceProvider).playError();
      SemanticsService.announce('Incorrect', TextDirection.ltr);
    }

    // A 3-mistake limit is per face (see CubeGameState.isComplete) — one
    // face failing never blocks or resets the other five.
    if (newMistakes >= 3) {
      updatedFaceState = updatedFaceState.copyWith(status: GameStatus.failed);
      SemanticsService.announce(
        '${face.displayName} face failed. Too many mistakes.',
        TextDirection.ltr,
      );
    } else if (_isGridComplete(newGrid, puzzle.solution)) {
      updatedFaceState = updatedFaceState.copyWith(
        status: GameStatus.completed,
      );
      ref.read(audioServiceProvider).playWin();
      SemanticsService.announce(
        '${face.displayName} face solved!',
        TextDirection.ltr,
      );
      // A face is a real, independently-solved puzzle of its own
      // difficulty — folded into the same per-difficulty stats a regular
      // single-puzzle completion feeds, immediately, rather than deferred
      // until (or lost if) the whole six-face cube never gets finished.
      ref
          .read(statisticsProvider.notifier)
          .recordCubeFaceCompletion(currentFaceState.difficulty.name);
    }

    state = state!.withFaceState(face, updatedFaceState);
    _saveGame();

    if (state!.isComplete) {
      SemanticsService.announce(
        'Cube complete! All six faces solved.',
        TextDirection.ltr,
      );
    }
  }

  void toggleNote(CubeFace face, int row, int col, int note) {
    if (state == null) return;
    final ops = _ops[face]!;
    final currentFaceState = state!.faceState(face);
    final puzzle = currentFaceState.puzzle;
    if (puzzle.grid[row][col] != 0) return;
    if (currentFaceState.status != GameStatus.playing) return;

    final currentNotes = currentFaceState.notes[row][col];
    final newNotes = Set<int>.from(currentNotes);
    if (newNotes.contains(note)) {
      newNotes.remove(note);
    } else {
      newNotes.add(note);
    }

    final newNotesGrid = ops.copyNotesGrid(currentFaceState.notes);
    newNotesGrid[row][col] = newNotes;

    final updated = currentFaceState.copyWith(
      notes: newNotesGrid,
      moveHistory: [
        ...currentFaceState.moveHistory,
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
    state = state!.withFaceState(face, updated);
    ref.read(audioServiceProvider).playClick();
    _saveGame();
  }

  void clearCell(CubeFace face, int row, int col) {
    if (state == null) return;
    final ops = _ops[face]!;
    final currentFaceState = state!.faceState(face);
    if (currentFaceState.puzzle.grid[row][col] != 0) return;
    if (currentFaceState.status != GameStatus.playing) return;

    final previousValue = currentFaceState.userGrid[row][col];
    if (previousValue == 0 && currentFaceState.notes[row][col].isEmpty) {
      return;
    }

    final newGrid = ops.copyGrid(currentFaceState.userGrid);
    newGrid[row][col] = 0;

    final newNotesGrid = ops.copyNotesGrid(currentFaceState.notes);
    newNotesGrid[row][col] = <int>{};

    final updated = currentFaceState.copyWith(
      userGrid: newGrid,
      notes: newNotesGrid,
      moveHistory: [
        ...currentFaceState.moveHistory,
        Move(
          row: row,
          col: col,
          previousValue: previousValue,
          newValue: 0,
          type: MoveType.clear,
          timestamp: DateTime.now(),
        ),
      ],
      redoStack: [],
      lastPlayed: DateTime.now(),
      lastSaved: DateTime.now(),
    );
    state = state!.withFaceState(face, updated);
    _saveGame();
  }

  Future<void> useHint(CubeFace face) async {
    if (state == null) return;
    final currentFaceState = state!.faceState(face);
    if (currentFaceState.status != GameStatus.playing) return;

    final getHint = ref.read(getHintUseCaseProvider);
    final result = await getHint(state: currentFaceState);

    result.fold((failure) => null, (hint) {
      if (hint == null) return;

      final penalty = hint.hintType == HintType.directReveal ? 30 : 15;

      // setValue does the grid/mistake/notes/completion work; its own
      // moveHistory entry (a plain `value` move) is intentionally replaced
      // below by a `hint` move instead, so undo() later restores this cell
      // (and decrements hintsUsed) rather than treating it as a normal
      // player move — same trade GameController.useHint makes.
      setValue(face, hint.row, hint.col, hint.value);

      final postSetValueFaceState = state!.faceState(face);
      final updatedFaceState = postSetValueFaceState.copyWith(
        hintsUsed: currentFaceState.hintsUsed + 1,
        penaltyTime: currentFaceState.penaltyTime + penalty,
        hintState: HintState(
          type: hint.hintType,
          cell: CellPosition(row: hint.row, col: hint.col),
          value: hint.value,
          explanation: hint.explanation,
          shownAt: DateTime.now(),
        ),
        moveHistory: [
          ...currentFaceState.moveHistory,
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

      // The hint penalty lands on the cube's one shared clock, not a
      // per-face timer — mirrors timeElapsed being tracked once for the
      // whole session (see CubeGameState.timeElapsed).
      state = state!
          .withFaceState(face, updatedFaceState)
          .copyWith(timeElapsed: state!.timeElapsed + penalty);

      ref.read(audioServiceProvider).playHint();
      SemanticsService.announce('Hint: ${hint.explanation}', TextDirection.ltr);
      _saveGame();
    });
  }

  void undo(CubeFace face) {
    if (state == null) return;
    final faceState = state!.faceState(face);
    if (faceState.moveHistory.isEmpty) return;

    final lastMove = faceState.moveHistory.last;
    final previousMoves = faceState.moveHistory.sublist(
      0,
      faceState.moveHistory.length - 1,
    );
    final applied = _ops[face]!.applyHistoryMove(
      faceState,
      lastMove,
      isUndo: true,
    );

    final updated = faceState.copyWith(
      userGrid: applied.grid,
      notes: applied.notes,
      mistakes: applied.mistakes,
      hintsUsed: applied.hintsUsed,
      moveHistory: previousMoves,
      redoStack: [lastMove, ...faceState.redoStack],
      status: GameStatus.playing,
      lastPlayed: DateTime.now(),
      lastSaved: DateTime.now(),
    );
    state = state!.withFaceState(face, updated);
    ref.read(audioServiceProvider).playClick();
    _saveGame();
  }

  void redo(CubeFace face) {
    if (state == null) return;
    final faceState = state!.faceState(face);
    if (faceState.redoStack.isEmpty) return;

    final nextMove = faceState.redoStack.first;
    final remainingRedo = faceState.redoStack.sublist(1);
    final applied = _ops[face]!.applyHistoryMove(
      faceState,
      nextMove,
      isUndo: false,
    );

    final updated = faceState.copyWith(
      userGrid: applied.grid,
      notes: applied.notes,
      mistakes: applied.mistakes,
      hintsUsed: applied.hintsUsed,
      moveHistory: [...faceState.moveHistory, nextMove],
      redoStack: remainingRedo,
      status: GameStatus.playing,
      lastPlayed: DateTime.now(),
      lastSaved: DateTime.now(),
    );
    state = state!.withFaceState(face, updated);
    ref.read(audioServiceProvider).playClick();
    _saveGame();
  }

  void toggleNoteMode(CubeFace face) {
    if (state == null) return;
    final faceState = state!.faceState(face);
    state = state!.withFaceState(
      face,
      faceState.copyWith(isNoteMode: !faceState.isNoteMode),
    );
    _saveGame();
  }

  void setSelectedNumber(CubeFace face, int? number) {
    if (state == null) return;
    final faceState = state!.faceState(face);
    state = state!.withFaceState(
      face,
      faceState.copyWith(selectedNumber: number),
    );
  }

  void clearHintState(CubeFace face) {
    if (state == null) return;
    final faceState = state!.faceState(face);
    state = state!.withFaceState(face, faceState.copyWith(hintState: null));
  }

  /// Regenerates just [face]'s puzzle at its current difficulty, leaving
  /// every other face (and overall progress) untouched — the "Retry this
  /// face" action for a face that hit its 3-mistake limit.
  Future<void> retryFace(CubeFace face) async {
    if (state == null) return;
    final currentDifficulty = state!.faceState(face).difficulty;

    final generate = ref.read(generateCubePuzzlesUseCaseProvider);
    final result = await generate({face: currentDifficulty});

    result.fold((failure) => null, (puzzles) {
      final freshFaceState = _ops[face]!.buildFreshGameState(
        puzzles[face]!,
        currentDifficulty,
      );
      state = state!.withFaceState(face, freshFaceState);
      _saveGame();
    });
  }

  void incrementTimer() {
    if (state == null) return;
    if (state!.isComplete) return;
    state = state!.copyWith(
      timeElapsed: state!.timeElapsed + 1,
      lastPlayed: DateTime.now(),
    );
  }

  void _saveGame() {
    if (state == null) return;
    final saveGame = ref.read(saveCubeGameStateUseCaseProvider);
    saveGame(state!.copyWith(lastSaved: DateTime.now()));
  }

  /// Forces an immediate save of whatever cube session is currently live —
  /// see [GameController.saveNow]'s doc comment for why this needs to exist
  /// alongside the per-move and 30s-backup autosaves.
  void saveNow() => _saveGame();

  void _startAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(seconds: 30), () {
      if (state != null && !state!.isComplete) {
        _saveGame();
        _startAutoSave();
      }
    });
  }

  bool _isGridComplete(List<List<int>> grid, List<List<int>> solution) {
    final result = ref.read(checkCompletionUseCaseProvider)(
      grid: grid,
      solution: solution,
    );
    return result.fold((_) => false, (complete) => complete);
  }
}

/// Ticks cubeGameControllerProvider's shared timeElapsed once a second
/// while the cube isn't fully solved — mirrors [TimerController], but keyed
/// off [CubeGameState.isComplete] instead of a single [GameStatus] since a
/// failed face must not stop the clock for the other five.
class CubeTimerController {
  CubeTimerController(this.ref);

  final Ref ref;
  Timer? _timer;

  void start() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final cubeState = ref.read(cubeGameControllerProvider);
      if (cubeState != null && !cubeState.isComplete) {
        ref.read(cubeGameControllerProvider.notifier).incrementTimer();
      }
    });
  }

  void pause() {
    _timer?.cancel();
    _timer = null;
  }

  void resume() => start();

  void reset() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() {
    _timer?.cancel();
  }
}

final cubeTimerControllerProvider = Provider<CubeTimerController>((ref) {
  final controller = CubeTimerController(ref);
  ref.onDispose(controller.dispose);
  return controller;
});

/// The player's manual choice between the live 3D cube and the flat
/// carousel. [CubeGameScreen] overrides this to flat whenever
/// `MediaQuery.disableAnimations` or `MediaQuery.accessibleNavigation` is
/// true, regardless of what this holds — this only matters when neither of
/// those is forcing the choice.
final show3DCubeProvider = StateProvider<bool>((ref) => true);
