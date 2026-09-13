import 'package:flutter_test/flutter_test.dart';
import 'package:m6_sudoku/features/sudoku/engine/models/board.dart';
import 'package:m6_sudoku/features/sudoku/engine/solver/sudoku_solver.dart';
import 'package:m6_sudoku/features/sudoku/engine/validator/unique_solution_validator.dart';

void main() {
  group('SudokuSolver - Basic Tests', () {
    group('solve - Basic Functionality', () {
      test('solves completely empty board', () {
        final board = Board();
        final result = SudokuSolver.solve(board);

        expect(result, true);
        expect(board.isComplete, true);
        expect(board.isValid, true);
      });

      test('solves board with single given', () {
        final board = Board();
        board.setValue(0, 0, 5);

        final result = SudokuSolver.solve(board);

        expect(result, true);
        expect(board.isComplete, true);
        expect(board.isValid, true);
      });

      test('solves board with multiple givens', () {
        final board = Board();
        board.setValue(0, 0, 5);
        board.setValue(0, 1, 3);
        board.setValue(1, 0, 6);
        board.setValue(1, 1, 2);

        final result = SudokuSolver.solve(board);

        expect(result, true);
        expect(board.isComplete, true);
        expect(board.isValid, true);
      });

      test('preserves given cells', () {
        final board = Board();
        board.setValue(0, 0, 5);
        board.setValue(1, 1, 3);
        board.setValue(2, 2, 7);

        final givenCells = <String, int>{};
        for (int r = 0; r < 9; r++) {
          for (int c = 0; c < 9; c++) {
            if (board.getValue(r, c) != 0) {
              givenCells['$r,$c'] = board.getValue(r, c);
            }
          }
        }

        SudokuSolver.solve(board);

        // Check given cells are preserved
        for (final entry in givenCells.entries) {
          final parts = entry.key.split(',');
          final r = int.parse(parts[0]);
          final c = int.parse(parts[1]);
          expect(board.getValue(r, c), entry.value);
        }
      });
    });

    group('solveWithCandidates', () {
      test('solves empty board with candidates', () {
        final board = Board();
        final result = SudokuSolver.solveWithCandidates(board);

        expect(result, true);
        expect(board.isComplete, true);
        expect(board.isValid, true);
      });

      test('solves partially filled board with candidates', () {
        final board = Board();
        board.setValue(0, 0, 5);
        board.setValue(0, 1, 3);
        board.setValue(1, 0, 6);

        final result = SudokuSolver.solveWithCandidates(board);

        expect(result, true);
        expect(board.isComplete, true);
        expect(board.isValid, true);
      });
    });
  });

  group('UniqueSolutionValidator - Basic Tests', () {
    test('validates unique solution for solved board', () {
      final board = Board();
      // Create a valid solved board
      for (int r = 0; r < 9; r++) {
        for (int c = 0; c < 9; c++) {
          board.setValue(r, c, (r + c) % 9 + 1);
        }
      }

      expect(UniqueSolutionValidator.hasUniqueSolution(board), true);
    });

    test('rejects board with multiple solutions', () {
      final board = Board();
      // Only a few givens - many solutions
      board.setValue(0, 0, 5);
      board.setValue(1, 1, 3);
      board.setValue(2, 2, 7);

      expect(UniqueSolutionValidator.hasUniqueSolution(board), false);
    });

    test('rejects empty board', () {
      final board = Board();

      expect(UniqueSolutionValidator.hasUniqueSolution(board), false);
    });

    test('validates minimal puzzle (17 clues)', () {
      // Known 17-clue puzzle
      final grid = [
        [0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 3, 0, 8, 5],
        [0, 0, 1, 0, 2, 0, 0, 0, 0],
        [0, 0, 0, 5, 0, 7, 0, 0, 0],
        [0, 0, 4, 0, 0, 0, 1, 0, 0],
        [0, 9, 0, 0, 0, 0, 0, 0, 0],
        [5, 0, 0, 0, 0, 0, 0, 7, 3],
        [0, 0, 2, 0, 1, 0, 0, 0, 0],
        [0, 0, 0, 0, 4, 0, 0, 0, 9],
      ];

      final board = Board.fromGrid(grid);
      expect(UniqueSolutionValidator.hasUniqueSolution(board), true);
    });
  });
}
