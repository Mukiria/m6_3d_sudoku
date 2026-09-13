import 'package:m6_sudoku/features/sudoku/engine/models/board.dart';

class UniqueSolutionValidator {
  static bool hasUniqueSolution(Board board) {
    final counter = _SolutionCounter();
    _countSolutions(board, counter, limit: 2);
    return counter.count == 1;
  }

  static void _countSolutions(
    Board board,
    _SolutionCounter counter, {
    int limit = 2,
  }) {
    if (counter.count >= limit) return;

    int bestRow = -1;
    int bestCol = -1;
    int minCandidates = 10;

    // Find cell with minimum remaining values (MRV heuristic)
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        if (board.getValue(r, c) == 0) {
          final candidates = board.getCandidates(r, c);
          if (candidates.isEmpty) return; // Dead end
          final count = candidates.length;
          if (count < minCandidates) {
            minCandidates = count;
            bestRow = r;
            bestCol = c;
            if (count == 1) break;
          }
        }
      }
      if (minCandidates == 1) break;
    }

    if (bestRow == -1) {
      counter.count++;
      return;
    }

    final candidates = board.getCandidates(bestRow, bestCol);
    for (final value in candidates) {
      if (counter.count >= limit) return;
      board.setValue(bestRow, bestCol, value);
      _countSolutions(board, counter, limit: limit);
      board.setValue(bestRow, bestCol, 0);
    }
  }

  static int countSolutions(Board board, {int maxCount = 100}) {
    final counter = _SolutionCounter();
    _countSolutions(board, counter, limit: maxCount);
    return counter.count;
  }

  static bool hasExactlyOneSolution(Board board) {
    return countSolutions(board, maxCount: 2) == 1;
  }
}

class _SolutionCounter {
  int count = 0;
}
