import 'package:m6_sudoku/features/sudoku/domain/entities/game_state.dart';
import 'package:m6_sudoku/features/sudoku/domain/entities/puzzle.dart';
import 'package:m6_sudoku/features/sudoku/engine/candidates.dart';
import 'package:m6_sudoku/features/sudoku/engine/models/difficulty.dart';

/// Shared single-puzzle session logic: highlighted-cell computation,
/// conflict detection, notes/candidate recomputation, and move-history
/// replay for undo/redo.
///
/// Extracted out of `GameController` (which owned one board) so the
/// cube-sudoku feature can reuse the exact same rules — one `PuzzleSessionOps`
/// instance per cube face — instead of a second, hand-copied implementation
/// that could silently drift out of agreement with the original.
///
/// Each instance keeps its own highlighted/conflict caches, matching the
/// per-board caching `GameController` did before this was extracted — a
/// cube session gets one instance per face rather than one cache shared
/// (and thrashed) across all six.
class PuzzleSessionOps {
  final Map<int, Set<CellPosition>> _highlightedCache = {};
  final Map<String, Set<CellPosition>> _conflictCache = {};

  Set<CellPosition> getHighlightedCells(int row, int col) {
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

  Set<CellPosition> getConflicts(List<List<int>> grid) {
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

  // Delegates to the shared bitmask candidate engine (see
  // engine/candidates.dart) rather than keeping its own copy.
  List<List<Set<int>>> recomputeNotesBitmask(
    List<List<int>> grid,
    Puzzle puzzle,
  ) {
    return computeCandidateGrid(grid, puzzle.grid);
  }

  List<List<Set<int>>> autoRemoveCandidatesBitmask(
    List<List<Set<int>>> notes,
    int row,
    int col,
    int value,
  ) {
    final newNotes = copyNotesGrid(notes);

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

  List<List<int>> copyGrid(List<List<int>> grid) {
    return grid.map((row) => List<int>.from(row)).toList();
  }

  List<List<Set<int>>> copyNotesGrid(List<List<Set<int>>> notes) {
    return notes.map((row) => List<Set<int>>.from(row)).toList();
  }

  /// The starting [GameState] for a brand-new session on [puzzle] at
  /// [difficulty] — shared by `GameController` (a single board) and the
  /// cube-sudoku controller (one call per face), which otherwise duplicated
  /// this exact field list.
  GameState buildFreshGameState(Puzzle puzzle, Difficulty difficulty) {
    final initialNotes = recomputeNotesBitmask(
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
  }

  int calculateMistakes(List<List<int>> grid, List<List<int>> solution) {
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

  /// The grid/notes/mistakes/hintsUsed that result from applying [move] to
  /// [currentState] — shared by undo and redo, which differ only in which
  /// value the move contributes and how the caller bookkeeps
  /// moveHistory/redoStack.
  ({
    List<List<int>> grid,
    List<List<Set<int>>> notes,
    int mistakes,
    int hintsUsed,
  })
  applyHistoryMove(GameState currentState, Move move, {required bool isUndo}) {
    final newGrid = copyGrid(currentState.userGrid);
    int newMistakes = currentState.mistakes;
    int newHintsUsed = currentState.hintsUsed;

    switch (move.type) {
      case MoveType.value:
        newGrid[move.row][move.col] =
            (isUndo ? move.previousValue : move.newValue) ?? 0;
        newMistakes = calculateMistakes(newGrid, currentState.puzzle.solution);
        break;
      case MoveType.note:
        // Notes are handled by recomputing below, not per-move.
        break;
      case MoveType.hint:
        newGrid[move.row][move.col] =
            (isUndo ? move.previousValue : move.newValue) ?? 0;
        newHintsUsed = (currentState.hintsUsed - 1).clamp(0, 999);
        newMistakes = calculateMistakes(newGrid, currentState.puzzle.solution);
        break;
      case MoveType.clear:
        // Undo restores the value that was cleared; redo re-applies the
        // clear (newValue is always 0 for a clear move).
        final clearedValue = isUndo ? move.previousValue : move.newValue;
        if (clearedValue != null) {
          newGrid[move.row][move.col] = clearedValue;
        }
        newMistakes = calculateMistakes(newGrid, currentState.puzzle.solution);
        break;
      default:
        break;
    }

    // Recompute notes from scratch based on the new grid using bitmasks.
    final newNotesGrid = recomputeNotesBitmask(newGrid, currentState.puzzle);

    return (
      grid: newGrid,
      notes: newNotesGrid,
      mistakes: newMistakes,
      hintsUsed: newHintsUsed,
    );
  }
}
