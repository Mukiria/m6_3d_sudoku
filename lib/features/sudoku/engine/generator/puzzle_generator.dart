import 'dart:math';

import 'package:m6_sudoku/features/sudoku/engine/models/board.dart';
import 'package:m6_sudoku/features/sudoku/engine/models/difficulty.dart';
import 'package:m6_sudoku/features/sudoku/engine/solver/sudoku_solver.dart';

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

  Board generatePuzzle({
    int clues = 30,
    int maxAttempts = 100,
    Duration? timeBudget,
  }) {
    final fullGrid = generateCompleteGrid();
    return _removeClues(fullGrid, clues, maxAttempts, timeBudget);
  }

  /// Carves clues out of [fullGrid] until [targetClues] remain, retrying
  /// with a fresh removal order up to [maxAttempts] times and keeping the
  /// sparsest result. [timeBudget], when set, stops retrying once exceeded
  /// (checked between attempts) — only ever pass it for unseeded
  /// generation, since where it cuts off depends on device speed and would
  /// break the daily challenge's same-puzzle-for-everyone guarantee.
  Board _removeClues(
    Board fullGrid,
    int targetClues,
    int maxAttempts,
    Duration? timeBudget,
  ) {
    final stopwatch = Stopwatch()..start();
    final random = _FastRandom(seed);
    final positions = List<int>.generate(81, (i) => i);
    final solution = fullGrid.toGrid().expand((row) => row).toList();

    List<int> bestCells = solution;
    int bestClues = 81;

    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final grid = _BitGrid(solution);
      _shuffle(positions, random);

      int clues = 81;

      for (final pos in positions) {
        if (clues <= targetClues) break;
        if (grid.cells[pos] == 0) continue;

        if (grid.staysUniqueWithout(pos)) {
          clues--;
        }
      }

      if (clues < bestClues) {
        bestClues = clues;
        bestCells = grid.cells;
      }

      if (clues <= targetClues) break;
      if (timeBudget != null && stopwatch.elapsed >= timeBudget) break;
    }

    final bestBoard = fullGrid.copy();
    for (var pos = 0; pos < 81; pos++) {
      if (bestCells[pos] == 0) bestBoard.setValue(pos ~/ 9, pos % 9, 0);
    }
    return bestBoard;
  }

  Board generatePuzzleWithDifficulty(Difficulty difficulty) {
    final params = _paramsFor(difficulty);
    return generatePuzzle(
      clues: params.clues,
      maxAttempts: params.maxAttempts,
      timeBudget: seed == null ? unseededTimeBudget : null,
    );
  }

  /// How long unseeded generation keeps retrying for a sparser puzzle
  /// before settling for the best one found so far. Seeded generation
  /// ignores it (see [_removeClues]).
  static const Duration unseededTimeBudget = Duration(seconds: 2);

  /// Generates a puzzle for [difficulty] together with the full solved grid
  /// it was carved from, so callers that need both (e.g. [PuzzleLocalDataSource]
  /// and [DailyChallengeLocalDataSource]) don't have to re-derive or re-solve
  /// the solution separately.
  ({Board puzzle, Board solution}) generatePuzzleWithSolution(
    Difficulty difficulty,
  ) {
    final params = _paramsFor(difficulty);
    final fullGrid = generateCompleteGrid();
    final puzzle = _removeClues(
      fullGrid,
      params.clues,
      params.maxAttempts,
      seed == null ? unseededTimeBudget : null,
    );
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
        return (clues: 21, maxAttempts: 200);
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

/// A flat 81-cell grid with row/column/box bitmasks, used only for clue
/// removal. Deliberately separate from [Board]: `Board.setValue` allocates
/// a new `Cell` per write, and the uniqueness search below does millions
/// of writes on Expert/Evil.
class _BitGrid {
  _BitGrid(List<int> solution) : cells = List<int>.of(solution) {
    for (var pos = 0; pos < 81; pos++) {
      _place(pos, cells[pos]);
    }
  }

  final List<int> cells;
  final List<int> _rowMasks = List<int>.filled(9, 0);
  final List<int> _colMasks = List<int>.filled(9, 0);
  final List<int> _boxMasks = List<int>.filled(9, 0);

  static int _boxOf(int pos) => (pos ~/ 27) * 3 + (pos % 9) ~/ 3;

  static final List<int> _bitCounts = List<int>.generate(512, (mask) {
    var count = 0;
    for (var m = mask; m != 0; m &= m - 1) {
      count++;
    }
    return count;
  });

  void _place(int pos, int value) {
    final bit = 1 << (value - 1);
    cells[pos] = value;
    _rowMasks[pos ~/ 9] |= bit;
    _colMasks[pos % 9] |= bit;
    _boxMasks[_boxOf(pos)] |= bit;
  }

  void _clear(int pos) {
    final bit = ~(1 << (cells[pos] - 1));
    cells[pos] = 0;
    _rowMasks[pos ~/ 9] &= bit;
    _colMasks[pos % 9] &= bit;
    _boxMasks[_boxOf(pos)] &= bit;
  }

  int _candidates(int pos) =>
      0x1FF &
      ~(_rowMasks[pos ~/ 9] | _colMasks[pos % 9] | _boxMasks[_boxOf(pos)]);

  /// Empties [pos] if the puzzle keeps a unique solution without it, and
  /// reports whether it did.
  ///
  /// Relies on the grid being uniquely solvable before the call (true from
  /// the full grid onward, since only uniqueness-preserving removals are
  /// kept). Given that, any second solution must put a different digit at
  /// [pos] — otherwise it would also solve the pre-removal grid — so it's
  /// enough to try each other legal digit there and ask whether the rest
  /// can still be completed.
  bool staysUniqueWithout(int pos) {
    final original = cells[pos];
    _clear(pos);

    final alternatives = _candidates(pos) & ~(1 << (original - 1));
    for (var m = alternatives; m != 0; m &= m - 1) {
      final bit = m & -m;
      _place(pos, bit.bitLength);
      final solvable = _solve();
      _clear(pos);
      if (solvable) {
        _place(pos, original);
        return false;
      }
    }
    return true;
  }

  /// Whether the empty cells can be filled consistently. Backtracking with
  /// the minimum-remaining-values heuristic; leaves the grid as it found it.
  bool _solve() {
    var bestPos = -1;
    var bestMask = 0;
    var bestCount = 10;

    for (var pos = 0; pos < 81; pos++) {
      if (cells[pos] != 0) continue;
      final mask = _candidates(pos);
      final count = _bitCounts[mask];
      if (count == 0) return false;
      if (count < bestCount) {
        bestPos = pos;
        bestMask = mask;
        bestCount = count;
        if (count == 1) break;
      }
    }

    if (bestPos == -1) return true;

    for (var m = bestMask; m != 0; m &= m - 1) {
      final bit = m & -m;
      _place(bestPos, bit.bitLength);
      final solved = _solve();
      _clear(bestPos);
      if (solved) return true;
    }
    return false;
  }
}

class _FastRandom {
  _FastRandom([int? seed])
    : _seed = seed ?? DateTime.now().microsecondsSinceEpoch;
  int _seed;

  int nextInt(int max) {
    _seed = (_seed * 1664525 + 1013904223) & 0xFFFFFFFF;
    return (_seed % max).abs();
  }
}
