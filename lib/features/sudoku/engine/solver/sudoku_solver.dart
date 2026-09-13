import 'dart:math';

import 'package:m6_sudoku/features/sudoku/engine/models/board.dart';

class SudokuSolver {
  static bool solve(Board board, {Random? random}) {
    return _backtrack(board, random ?? _random);
  }

  static bool _backtrack(Board board, Random random) {
    // Find empty cell with minimum candidates (MRV heuristic)
    int bestRow = -1;
    int bestCol = -1;
    int minCandidates = 10;

    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        if (board.getValue(r, c) == 0) {
          final candidates = board.getCandidates(r, c);
          final count = candidates.length;
          if (count == 0) return false; // Dead end
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

    if (bestRow == -1) return true; // Solved

    final candidates = board.getCandidates(bestRow, bestCol);
    // Shuffle candidates for different solutions
    final shuffled = List<int>.from(candidates)..shuffle(random);
    for (final value in shuffled) {
      board.setValue(bestRow, bestCol, value);
      if (_backtrack(board, random)) return true;
      board.setValue(bestRow, bestCol, 0);
    }

    return false;
  }

  static List<int> _getEmptyCells(Board board) {
    final empty = <int>[];
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        if (board.getValue(r, c) == 0) {
          empty.add(r * 9 + c);
        }
      }
    }
    return empty;
  }

  static bool solveWithCandidates(Board board) {
    final emptyCells = _getEmptyCells(board);
    return _backtrackWithMRV(board, emptyCells);
  }

  static bool _backtrackWithMRV(Board board, List<int> emptyCells) {
    if (emptyCells.isEmpty) return true;

    emptyCells.sort((a, b) {
      final ca = board.getCandidates(a ~/ 9, a % 9).length;
      final cb = board.getCandidates(b ~/ 9, b % 9).length;
      return ca.compareTo(cb);
    });

    final index = emptyCells.removeAt(0);
    final row = index ~/ 9;
    final col = index % 9;

    final candidates = board.getCandidates(row, col);
    final shuffled = List<int>.from(candidates)..shuffle(_random);

    for (final value in shuffled) {
      board.setValue(row, col, value);
      if (_backtrackWithMRV(board, emptyCells)) return true;
      board.setValue(row, col, 0);
    }

    emptyCells.insert(0, index);
    return false;
  }

  static final _random = Random();
}
