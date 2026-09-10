import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:m6_sudoku/features/sudoku/domain/entities/puzzle.dart';
import 'package:m6_sudoku/features/sudoku/domain/entities/game_state.dart';
import 'package:m6_sudoku/features/sudoku/engine/models/difficulty.dart';
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
  GameState? build() => null;

  // Cache for highlighted cells computation
  final Map<int, Set<CellPosition>> _highlightedCache = {};
  // Cache for conflict cells computation
  final Map<String, Set<CellPosition>> _conflictCache = {};

  // Bitmask constants for notes (bits 0-8 represent digits 1-9)
  static const int _allCandidates = 0x1FF; // bits 0-8 set (1-9)

  Future<void> newGame(Difficulty difficulty) async {
    final generatePuzzle = ref.read(generatePuzzleUseCaseProvider);
    final result = await generatePuzzle(difficulty.name);

    state = result.fold((failure) => throw Exception(failure.message), (
      puzzle,
    ) {
      final initialNotes = _recomputeNotesBitmask(
        puzzle.grid.map((row) => List<int>.from(row)).toList(),
        puzzle,
      );
      return GameState(
        puzzleId: puzzle.id,
        puzzle: puzzle,
        userGrid: puzzle.grid.map((row) => List<int>.from(row)).toList(),
        notes: initialNotes,
        timeElapsed: 0,
        mistakes: 0,
        hintsUsed: 0,
        penaltyTime: 0,
        moveHistory: [],
        redoStack: [],
        status: GameStatus.playing,
        lastPlayed: DateTime.now(),
        difficulty: difficulty,
        selectedCell: null,
        selectedNumber: null,
        isNoteMode: false,
        highlightedCells: {},
        conflictCells: {},
        hintState: null,
        lastSaved: DateTime.now(),
      );
    });
    ref.read(showPencilMarksProvider.notifier).state = true;
    _startAutoSave();
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
    final initialNotes = _recomputeNotesBitmask(
      puzzle.grid.map((row) => List<int>.from(row)).toList(),
      puzzle,
    );
    state = GameState(
      puzzleId: puzzle.id,
      puzzle: puzzle,
      userGrid: puzzle.grid.map((row) => List<int>.from(row)).toList(),
      notes: initialNotes,
      timeElapsed: 0,
      mistakes: 0,
      hintsUsed: 0,
      penaltyTime: 0,
      moveHistory: [],
      redoStack: [],
      status: GameStatus.playing,
      lastPlayed: DateTime.now(),
      difficulty: difficulty,
      selectedCell: null,
      selectedNumber: null,
      isNoteMode: false,
      highlightedCells: {},
      conflictCells: {},
      hintState: null,
      lastSaved: DateTime.now(),
    );
    ref.read(showPencilMarksProvider.notifier).state = true;
    _startAutoSave();
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
      highlightedCells: _getHighlightedCells(row, col),
      conflictCells: _getConflicts(state!.userGrid),
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

    final newGrid = _copyGrid(currentState.userGrid);
    newGrid[row][col] = value;

    final isCorrect = puzzle.solution[row][col] == value;
    final newMistakes =
        isCorrect ? currentState.mistakes : currentState.mistakes + 1;

    // Auto-remove candidates from affected cells using bitmasks
    final newNotesGrid = _autoRemoveCandidatesBitmask(
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
      conflictCells: _getConflicts(newGrid),
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
    }

    if (newMistakes >= 3) {
      state = state!.copyWith(status: GameStatus.failed);
    } else if (_checkCompletion(newGrid, puzzle.solution)) {
      state = state!.copyWith(status: GameStatus.completed);
      _saveGame();
      _checkAndUnlockAchievements(currentState);
      _completeDailyChallengeIfNeeded(currentState);
      ref.read(audioServiceProvider).playWin();
    }
  }

  /// Records completion + streak/stats for the daily challenge, and blocks
  /// the puzzle from being replayed for credit: [CompleteDailyChallengeUseCase]
  /// rejects a second completion for the same date at the storage layer.
  void _completeDailyChallengeIfNeeded(GameState completedState) {
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
    _incrementAchievement('daily_champion', 1);
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

    final newNotesGrid = _copyNotesGrid(currentState.notes);
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

    final newGrid = _copyGrid(currentState.userGrid);
    newGrid[row][col] = 0;

    final newNotesGrid = _copyNotesGrid(currentState.notes);
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

    final newGrid = _copyGrid(currentState.userGrid);
    int newMistakes = currentState.mistakes;
    int newHintsUsed = currentState.hintsUsed;

    switch (lastMove.type) {
      case MoveType.value:
        newGrid[lastMove.row][lastMove.col] = lastMove.previousValue ?? 0;
        newMistakes = _calculateMistakes(newGrid, currentState.puzzle.solution);
        break;
      case MoveType.note:
        // Notes are handled by recomputing
        break;
      case MoveType.hint:
        newGrid[lastMove.row][lastMove.col] = lastMove.previousValue ?? 0;
        newHintsUsed = (currentState.hintsUsed - 1).clamp(0, 999);
        newMistakes = _calculateMistakes(newGrid, currentState.puzzle.solution);
        break;
      case MoveType.clear:
        if (lastMove.previousValue != null) {
          newGrid[lastMove.row][lastMove.col] = lastMove.previousValue!;
        }
        newMistakes = _calculateMistakes(newGrid, currentState.puzzle.solution);
        break;
      default:
        break;
    }

    // Recompute notes from scratch based on new grid using bitmasks
    final newNotesGrid = _recomputeNotesBitmask(newGrid, currentState.puzzle);

    state = currentState.copyWith(
      userGrid: newGrid,
      notes: newNotesGrid,
      mistakes: newMistakes,
      hintsUsed: newHintsUsed,
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

    final newGrid = _copyGrid(currentState.userGrid);
    int newMistakes = currentState.mistakes;
    int newHintsUsed = currentState.hintsUsed;

    switch (nextMove.type) {
      case MoveType.value:
        newGrid[nextMove.row][nextMove.col] = nextMove.newValue ?? 0;
        newMistakes = _calculateMistakes(newGrid, currentState.puzzle.solution);
        break;
      case MoveType.note:
        // Notes are handled by recomputing
        break;
      case MoveType.hint:
        newGrid[nextMove.row][nextMove.col] = nextMove.newValue ?? 0;
        newHintsUsed = (currentState.hintsUsed - 1).clamp(0, 999);
        newMistakes = _calculateMistakes(newGrid, currentState.puzzle.solution);
        break;
      case MoveType.clear:
        if (nextMove.previousValue != null) {
          newGrid[nextMove.row][nextMove.col] = nextMove.previousValue!;
        }
        newMistakes = _calculateMistakes(newGrid, currentState.puzzle.solution);
        break;
      default:
        break;
    }

    // Recompute notes from scratch based on new grid using bitmasks
    final newNotesGrid = _recomputeNotesBitmask(newGrid, currentState.puzzle);

    state = currentState.copyWith(
      userGrid: newGrid,
      notes: newNotesGrid,
      mistakes: newMistakes,
      hintsUsed: newHintsUsed,
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

  void _startAutoSave() {
    // Periodic auto-save as backup (every 30 seconds)
    Future.delayed(const Duration(seconds: 30), () {
      if (state != null && state!.status == GameStatus.playing) {
        _saveGame();
        _startAutoSave();
      }
    });
  }

  Set<CellPosition> _getHighlightedCells(int row, int col) {
    final key = row * 9 + col;
    return _highlightedCache.putIfAbsent(key, () {
      final highlighted = <CellPosition>{};

      // Highlight row
      for (int c = 0; c < 9; c++) {
        if (c != col) highlighted.add(CellPosition(row: row, col: c));
      }

      // Highlight column
      for (int r = 0; r < 9; r++) {
        if (r != row) highlighted.add(CellPosition(row: r, col: col));
      }

      // Highlight 3x3 box
      final boxRow = (row ~/ 3) * 3;
      final boxCol = (col ~/ 3) * 3;
      for (int r = boxRow; r < boxRow + 3; r++) {
        for (int c = boxCol; c < boxCol + 3; c++) {
          if (r != row || c != col) {
            highlighted.add(CellPosition(row: r, col: c));
          }
        }
      }

      return highlighted;
    });
  }

  Set<CellPosition> _getConflicts(List<List<int>> grid) {
    // Create a hash of the grid for caching
    final hash = _gridHash(grid);
    return _conflictCache.putIfAbsent(hash, () {
      final conflicts = <CellPosition>{};

      // Check rows
      for (int r = 0; r < 9; r++) {
        final seen = <int, int>{};
        for (int c = 0; c < 9; c++) {
          final val = grid[r][c];
          if (val != 0) {
            if (seen.containsKey(val)) {
              conflicts.add(CellPosition(row: r, col: seen[val]!));
              conflicts.add(CellPosition(row: r, col: c));
            } else {
              seen[val] = c;
            }
          }
        }
      }

      // Check columns
      for (int c = 0; c < 9; c++) {
        final seen = <int, int>{};
        for (int r = 0; r < 9; r++) {
          final val = grid[r][c];
          if (val != 0) {
            if (seen.containsKey(val)) {
              conflicts.add(CellPosition(row: seen[val]!, col: c));
              conflicts.add(CellPosition(row: r, col: c));
            } else {
              seen[val] = r;
            }
          }
        }
      }

      // Check 3x3 boxes
      for (int boxRow = 0; boxRow < 3; boxRow++) {
        for (int boxCol = 0; boxCol < 3; boxCol++) {
          final seen = <int, CellPosition>{};
          for (int r = 0; r < 3; r++) {
            for (int c = 0; c < 3; c++) {
              final rIdx = boxRow * 3 + r;
              final cIdx = boxCol * 3 + c;
              final val = grid[rIdx][cIdx];
              if (val != 0) {
                if (seen.containsKey(val)) {
                  conflicts.add(seen[val]!);
                  conflicts.add(CellPosition(row: rIdx, col: cIdx));
                } else {
                  seen[val] = CellPosition(row: rIdx, col: cIdx);
                }
              }
            }
          }
        }
      }

      return conflicts;
    });
  }

  String _gridHash(List<List<int>> grid) {
    final buffer = StringBuffer();
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        buffer.write(grid[r][c]);
      }
    }
    return buffer.toString();
  }

  bool _checkCompletion(List<List<int>> grid, List<List<int>> solution) {
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (grid[r][c] != solution[r][c]) return false;
      }
    }
    return true;
  }

  int _calculateMistakes(List<List<int>> grid, List<List<int>> solution) {
    int mistakes = 0;
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (grid[r][c] != 0 && grid[r][c] != solution[r][c]) {
          mistakes++;
        }
      }
    }
    return mistakes;
  }

  // Bitmask-based notes computation - much faster than Set-based
  List<List<Set<int>>> _recomputeNotesBitmask(
    List<List<int>> grid,
    Puzzle puzzle,
  ) {
    final newNotesBitmask = List.generate(9, (_) => List.generate(9, (_) => 0));

    // Precompute row, col, box masks for the current grid + puzzle givens
    final rowMasks = List.filled(9, 0);
    final colMasks = List.filled(9, 0);
    final boxMasks = List.filled(9, 0);

    // Fill masks with fixed values (user entries + puzzle givens)
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        final val = grid[r][c] != 0 ? grid[r][c] : puzzle.grid[r][c];
        if (val != 0) {
          final bit = 1 << (val - 1);
          rowMasks[r] |= bit;
          colMasks[c] |= bit;
          boxMasks[(r ~/ 3) * 3 + (c ~/ 3)] |= bit;
        }
      }
    }

    // Compute candidates for each empty cell
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (grid[r][c] == 0 && puzzle.grid[r][c] == 0) {
          final boxIndex = (r ~/ 3) * 3 + (c ~/ 3);
          final usedMask = rowMasks[r] | colMasks[c] | boxMasks[boxIndex];
          newNotesBitmask[r][c] = _allCandidates & ~usedMask;
        }
      }
    }

    // Convert bitmasks to Sets for the GameState
    return List.generate(
      9,
      (r) => List.generate(9, (c) {
        final mask = newNotesBitmask[r][c];
        if (mask == 0) return <int>{};
        final set = <int>{};
        var m = mask;
        while (m != 0) {
          final bit = m & -m;
          set.add(_bitToDigit(bit));
          m &= m - 1;
        }
        return set;
      }),
    );
  }

  List<List<Set<int>>> _autoRemoveCandidatesBitmask(
    List<List<Set<int>>> notes,
    int row,
    int col,
    int value,
  ) {
    final newNotes = _copyNotesGrid(notes);

    // Remove from row
    for (int c = 0; c < 9; c++) {
      newNotes[row][c].remove(value);
    }

    // Remove from column
    for (int r = 0; r < 9; r++) {
      newNotes[r][col].remove(value);
    }

    // Remove from box
    final boxRow = (row ~/ 3) * 3;
    final boxCol = (col ~/ 3) * 3;
    for (int r = boxRow; r < boxRow + 3; r++) {
      for (int c = boxCol; c < boxCol + 3; c++) {
        newNotes[r][c].remove(value);
      }
    }

    // Clear the cell itself
    newNotes[row][col].clear();

    return newNotes;
  }

  static int _bitToDigit(int bit) {
    switch (bit) {
      case 0x001:
        return 1;
      case 0x002:
        return 2;
      case 0x004:
        return 3;
      case 0x008:
        return 4;
      case 0x010:
        return 5;
      case 0x020:
        return 6;
      case 0x040:
        return 7;
      case 0x080:
        return 8;
      case 0x100:
        return 9;
      default:
        return 0;
    }
  }

  List<List<int>> _copyGrid(List<List<int>> grid) {
    return grid.map((row) => List<int>.from(row)).toList();
  }

  List<List<Set<int>>> _copyNotesGrid(List<List<Set<int>>> notes) {
    return notes.map((row) => List<Set<int>>.from(row)).toList();
  }

  void clearHintState() {
    if (state == null) return;
    state = state!.copyWith(hintState: null);
  }

  void _checkAndUnlockAchievements(GameState completedState) {
    final currentState = state!;
    final difficulty = currentState.difficulty.name;
    final timeElapsed = currentState.timeElapsed;
    final mistakes = currentState.mistakes;
    final hintsUsed = currentState.hintsUsed;
    final hour = DateTime.now().hour;

    // First Win
    _incrementAchievement('first_win', 1);

    // Ten Wins
    _incrementAchievement('ten_wins', 1);

    // Hundred Wins
    _incrementAchievement('hundred_wins', 1);

    // Perfect Game (0 mistakes, 0 hints)
    if (mistakes == 0 && hintsUsed == 0) {
      _incrementAchievement('perfect_game', 1);
      _incrementAchievement('five_perfect', 1);
    }

    // No Hints
    if (hintsUsed == 0) {
      _incrementAchievement('no_hints', 1);
      _incrementAchievement('ten_no_hints', 1);
    }

    // Expert Winner
    if (difficulty == 'expert') {
      _incrementAchievement('expert_winner', 1);
    }

    // Evil Conqueror (secret)
    if (difficulty == 'evil') {
      _incrementAchievement('evil_conqueror', 1);
    }

    // All Difficulties - check what difficulties have been won
    // This would need to track which difficulties have been won
    // For now, increment and let the progress system handle it
    // TODO: Implement difficulty tracking

    // Speed Runner (under 3 minutes = 180 seconds)
    if (timeElapsed < 180) {
      _incrementAchievement('speed_runner', 1);
    }

    // Lightning Fast (Easy under 1 minute = 60 seconds)
    if (difficulty == 'easy' && timeElapsed < 60) {
      _incrementAchievement('lightning', 1);
    }

    // Streaks are handled by statistics

    // Daily Champion - handled by daily challenge

    // Night Owl (midnight - 4 AM)
    if (hour >= 0 && hour < 4) {
      _incrementAchievement('night_owl', 1);
    }

    // Early Bird (4 AM - 7 AM)
    if (hour >= 4 && hour < 7) {
      _incrementAchievement('early_bird', 1);
    }
  }

  /// Increments achievement [id]'s progress and, if this is the call that
  /// crosses its target, queues it for [AchievementUnlockBanner] to animate.
  Future<void> _incrementAchievement(String id, int amount) async {
    final result = await ref.read(incrementAchievementProgressUseCaseProvider)(
      id,
      amount,
    );
    result.fold((_) {}, (unlocked) {
      if (unlocked == null) return;
      try {
        ref.read(achievementUnlockQueueProvider.notifier).push(unlocked);
      } on StateError {
        // gameControllerProvider is autodispose: completing a game
        // navigates away almost immediately, which can dispose this
        // controller before this await resumes. The achievement is
        // already persisted at this point; there's just no screen left
        // to animate the unlock on.
      }
    });
  }
}

class TimerController extends StateNotifier<int> {
  TimerController(this.ref) : super(0);

  final Ref ref;
  Timer? _timer;

  void start() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final gameState = ref.read(gameControllerProvider);
      if (gameState != null && gameState.status == GameStatus.playing) {
        state = state + 1;
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
    state = 0;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final timerControllerProvider = StateNotifierProvider<TimerController, int>((
  ref,
) {
  return TimerController(ref);
});
