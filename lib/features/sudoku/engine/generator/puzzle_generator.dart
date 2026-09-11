import 'dart:math';

import 'package:m6_sudoku/features/sudoku/engine/models/difficulty.dart';
import '../models/board.dart';
import '../solver/sudoku_solver.dart';

/// Input for [generatePuzzleInBackground]. Kept to plain, isolate-sendable
/// fields only (an enum and a nullable int) — no closures, no [Board] or
/// [PuzzleGenerator] instances — since this crosses an isolate boundary via
/// [compute].
typedef PuzzleGenerationRequest = ({Difficulty difficulty, int? seed});

/// Raw output of [generatePuzzleInBackground]: just the two grids and the
/// clue count. Callers wrap this into their own `Puzzle` entity, since the
/// `id`/`createdAt`/difficulty-label differ between a regular new game and
/// the deterministic daily challenge.
typedef PuzzleGenerationResult =
    ({List<List<int>> grid, List<List<int>> solution, int cluesCount});

/// Top-level [compute] entry point that runs puzzle generation off the UI
/// isolate. Generation is a backtracking solve plus, depending on
/// difficulty, up to ~200 clue-removal attempts each re-verifying unique
/// solvability with a second recursive solve — expensive enough (especially
/// on Expert/Evil) to visibly freeze the UI if run in-place on "New Game".
/// `compute` requires a top-level or static function, which is why this
/// isn't a method on [PuzzleGenerator].
PuzzleGenerationResult generatePuzzleInBackground(
  PuzzleGenerationRequest request,
) {
  final generator = PuzzleGenerator(seed: request.seed);
  final (:puzzle, :solution) = generator.generatePuzzleWithSolution(
    request.difficulty,
  );
  return (
    grid: puzzle.toGrid(),
    solution: solution.toGrid(),
    cluesCount: puzzle.filledCount,
  );
}

class PuzzleGenerator {
  PuzzleGenerator({this.seed});

  final int? seed;

  /// With a [seed], the complete grid is fully deterministic — solving the
  /// same empty board with the same seeded shuffle order always produces
  /// the same grid, which the daily challenge relies on to give every
  /// player an identical puzzle. Without a seed, generation stays random.
  Board generateCompleteGrid() {
    final board = Board();
    SudokuSolver.solve(board, random: seed != null ? Random(seed) : null);
    return board;
  }

  Board generatePuzzle({int clues = 30, int maxAttempts = 100}) {
    final fullGrid = generateCompleteGrid();
    return _removeClues(fullGrid, clues, maxAttempts);
  }

  Board _removeClues(Board fullGrid, int targetClues, int maxAttempts) {
    Board bestBoard = fullGrid.copy();
    int bestClues = 81;

    final random = _FastRandom(seed);
    final positions = List<int>.generate(81, (i) => i);
    final solution = fullGrid.toGrid();

    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final board = fullGrid.copy();
      _shuffle(positions, random);

      int clues = 81;

      for (final pos in positions) {
        if (clues <= targetClues) break;

        final row = pos ~/ 9;
        final col = pos % 9;

        if (board.getValue(row, col) == 0) continue;

        final originalValue = board.getValue(row, col);
        board.setValue(row, col, 0);

        if (_hasUniqueSolutionFast(board, solution)) {
          clues--;
        } else {
          board.setValue(row, col, originalValue);
        }
      }

      if (clues < bestClues) {
        bestClues = clues;
        bestBoard = board;
      }

      if (clues <= targetClues) break;
    }

    return bestBoard;
  }

  /// Fast uniqueness check using the known solution as reference.
  /// Tries to find a solution different from the known one.
  bool _hasUniqueSolutionFast(Board board, List<List<int>> knownSolution) {
    return !_findDifferentSolution(board, knownSolution, 0);
  }

  /// Attempts to find a solution different from the known one.
  /// Returns true if a different solution exists.
  bool _findDifferentSolution(
    Board board,
    List<List<int>> knownSolution,
    int index,
  ) {
    if (index >= 81) {
      // Found a complete solution - check if it's different from known
      for (var r = 0; r < 9; r++) {
        for (var c = 0; c < 9; c++) {
          if (board.getValue(r, c) != knownSolution[r][c]) {
            return true; // Different solution found
          }
        }
      }
      return false; // Same solution
    }

    final row = index ~/ 9;
    final col = index % 9;

    if (board.getValue(row, col) != 0) {
      return _findDifferentSolution(board, knownSolution, index + 1);
    }

    final candidates = board.getCandidates(row, col);

    // Try candidates that differ from known solution first (more likely to find alternative)
    final knownValue = knownSolution[row][col];
    final orderedCandidates = <int>[];

    // First try values different from known solution
    for (final v in candidates) {
      if (v != knownValue) orderedCandidates.add(v);
    }
    // Then try the known value
    if (candidates.contains(knownValue)) {
      orderedCandidates.add(knownValue);
    }

    for (final value in orderedCandidates) {
      board.setValue(row, col, value);
      if (_findDifferentSolution(board, knownSolution, index + 1)) {
        board.setValue(row, col, 0);
        return true;
      }
      board.setValue(row, col, 0);
    }

    return false;
  }

  Board generatePuzzleWithDifficulty(Difficulty difficulty) {
    final params = _paramsFor(difficulty);
    return generatePuzzle(clues: params.clues, maxAttempts: params.maxAttempts);
  }

  /// Generates a puzzle for [difficulty] together with the full solved grid
  /// it was carved from, so callers that need both (e.g. [PuzzleLocalDataSource]
  /// and [DailyChallengeLocalDataSource]) don't have to re-derive or re-solve
  /// the solution separately.
  ({Board puzzle, Board solution}) generatePuzzleWithSolution(
    Difficulty difficulty,
  ) {
    final params = _paramsFor(difficulty);
    final fullGrid = generateCompleteGrid();
    final puzzle = _removeClues(fullGrid, params.clues, params.maxAttempts);
    return (puzzle: puzzle, solution: fullGrid);
  }

  ({int clues, int maxAttempts}) _paramsFor(Difficulty difficulty) {
    switch (difficulty) {
      case Difficulty.easy:
        return (clues: 36, maxAttempts: 50);
      case Difficulty.medium:
        return (clues: 30, maxAttempts: 80);
      case Difficulty.hard:
        return (clues: 26, maxAttempts: 100);
      case Difficulty.expert:
        return (clues: 22, maxAttempts: 150);
      case Difficulty.evil:
        return (clues: 20, maxAttempts: 200);
    }
  }

  static void _shuffle(List<int> list, _FastRandom random) {
    for (var i = list.length - 1; i > 0; i--) {
      final j = random.nextInt(i + 1);
      final temp = list[i];
      list[i] = list[j];
      list[j] = temp;
    }
  }
}

class _FastRandom {
  int _seed;

  _FastRandom([int? seed])
    : _seed = seed ?? DateTime.now().microsecondsSinceEpoch;

  int nextInt(int max) {
    _seed = (_seed * 1664525 + 1013904223) & 0xFFFFFFFF;
    return (_seed % max).abs();
  }
}
