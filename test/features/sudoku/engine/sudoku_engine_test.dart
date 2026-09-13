import 'package:flutter_test/flutter_test.dart';
import 'package:m6_sudoku/features/sudoku/engine/generator/puzzle_generator.dart';
import 'package:m6_sudoku/features/sudoku/engine/models/board.dart';
import 'package:m6_sudoku/features/sudoku/engine/models/cell.dart';
import 'package:m6_sudoku/features/sudoku/engine/models/difficulty.dart';
import 'package:m6_sudoku/features/sudoku/engine/solver/sudoku_solver.dart';
import 'package:m6_sudoku/features/sudoku/engine/validator/unique_solution_validator.dart';

void main() {
  group('Cell', () {
    test('creates empty cell with value 0', () {
      const cell = Cell(row: 0, col: 0);
      expect(cell.value, 0);
      expect(cell.isEmpty, true);
      expect(cell.isFilled, false);
    });

    test('creates filled cell', () {
      const cell = Cell(row: 0, col: 0, value: 5);
      expect(cell.value, 5);
      expect(cell.isEmpty, false);
      expect(cell.isFilled, true);
    });

    test('copyWith updates value', () {
      const cell = Cell(row: 0, col: 0, value: 0);
      final newCell = cell.copyWith(value: 5);
      expect(newCell.value, 5);
      expect(newCell.row, 0);
      expect(newCell.col, 0);
    });
  });

  group('Board', () {
    test('creates empty 9x9 grid', () {
      final board = Board();
      expect(board.cells.length, 9);
      expect(board.cells[0].length, 9);
    });

    test('getValue and setValue work correctly', () {
      final board = Board();
      board.setValue(0, 0, 5);
      expect(board.getValue(0, 0), 5);
    });

    test('getRow returns correct values', () {
      final board = Board();
      board.setValue(0, 0, 1);
      board.setValue(0, 1, 2);
      board.setValue(0, 2, 3);
      expect(board.getRow(0).take(3).toList(), [1, 2, 3]);
    });

    test('getCol returns correct values', () {
      final board = Board();
      board.setValue(0, 0, 1);
      board.setValue(1, 0, 2);
      board.setValue(2, 0, 3);
      expect(board.getCol(0).take(3).toList(), [1, 2, 3]);
    });

    test('getBox returns correct values', () {
      final board = Board();
      board.setValue(0, 0, 1);
      board.setValue(0, 1, 2);
      board.setValue(1, 0, 3);
      expect(board.getBox(0, 0), containsAll([1, 2, 3]));
    });

    test('isValidPlacement checks row constraint', () {
      final board = Board();
      board.setValue(0, 0, 5);
      expect(board.isValidPlacement(0, 1, 5), false);
      expect(board.isValidPlacement(0, 1, 6), true);
    });

    test('isValidPlacement checks column constraint', () {
      final board = Board();
      board.setValue(0, 0, 5);
      expect(board.isValidPlacement(1, 0, 5), false);
      expect(board.isValidPlacement(1, 0, 6), true);
    });

    test('isValidPlacement checks box constraint', () {
      final board = Board();
      board.setValue(0, 0, 5);
      expect(board.isValidPlacement(1, 1, 5), false);
      expect(board.isValidPlacement(2, 2, 5), false);
      expect(board.isValidPlacement(3, 3, 5), true);
    });

    test('isValid checks for duplicates', () {
      final board = Board();
      board.setValue(0, 0, 5);
      board.setValue(0, 1, 5);
      expect(board.isValid, false);
    });

    test('fromGrid creates board from grid', () {
      final grid = List.generate(9, (i) => List.generate(9, (j) => 0));
      grid[0][0] = 5;
      grid[1][1] = 3;
      final board = Board.fromGrid(grid);
      expect(board.getValue(0, 0), 5);
      expect(board.getValue(1, 1), 3);
      expect(board.cells[0][0].isGiven, true);
      expect(board.cells[1][1].isGiven, true);
    });

    test('copy creates deep copy', () {
      final board = Board();
      board.setValue(0, 0, 5);
      final copy = board.copy();
      expect(copy.getValue(0, 0), 5);
      copy.setValue(0, 0, 7);
      expect(board.getValue(0, 0), 5);
    });

    test('isComplete returns true when all cells filled', () {
      final board = Board();
      for (var r = 0; r < 9; r++) {
        for (var c = 0; c < 9; c++) {
          board.setValue(r, c, (r + c) % 9 + 1);
        }
      }
      expect(board.isComplete, true);
    });
  });

  group('SudokuSolver', () {
    test('solves empty board', () {
      final board = Board();
      final result = SudokuSolver.solve(board);
      expect(result, true);
      expect(board.isComplete, true);
      expect(board.isValid, true);
    });

    test('solves partially filled board', () {
      final board = Board();
      board.setValue(0, 0, 5);
      board.setValue(0, 1, 3);
      board.setValue(1, 0, 6);
      final result = SudokuSolver.solve(board);
      expect(result, true);
      expect(board.isComplete, true);
      expect(board.isValid, true);
    });

    test('solveWithCandidates works', () {
      final board = Board();
      final result = SudokuSolver.solveWithCandidates(board);
      expect(result, true);
      expect(board.isComplete, true);
      expect(board.isValid, true);
    });
  });

  group('UniqueSolutionValidator', () {
    test('validates unique solution for solved board', () {
      final board = Board();
      SudokuSolver.solve(board);
      expect(UniqueSolutionValidator.hasUniqueSolution(board), true);
    });

    test('validates unique solution for partially filled board', () {
      final board = Board();
      board.setValue(0, 0, 5);
      board.setValue(0, 1, 3);
      board.setValue(1, 0, 6);
      SudokuSolver.solve(board);
      expect(UniqueSolutionValidator.hasUniqueSolution(board), true);
    });

    test('rejects board with multiple solutions (simple case)', () {
      final board = Board();
      // Fill some cells but leave most empty - should have many solutions
      board.setValue(0, 0, 5);
      board.setValue(1, 1, 3);
      board.setValue(2, 2, 7);
      // Only 3 givens - many solutions
      expect(UniqueSolutionValidator.hasUniqueSolution(board), false);
    });
  });

  group('PuzzleGenerator', () {
    test('generates complete grid', () {
      final generator = PuzzleGenerator();
      final board = generator.generateCompleteGrid();
      expect(board.isComplete, true);
      expect(board.isValid, true);
    });

    test(
      'generates puzzle with target clues',
      () {
        final generator = PuzzleGenerator();
        final board = generator.generatePuzzle(clues: 30, maxAttempts: 5);
        expect(board.filledCount, lessThanOrEqualTo(35));
        expect(board.isValid, true);
        expect(UniqueSolutionValidator.hasUniqueSolution(board), true);
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'generates puzzle with different difficulties',
      () {
        final generator = PuzzleGenerator();
        for (final diff in Difficulty.values) {
          final board = generator.generatePuzzleWithDifficulty(diff);
          expect(board.isValid, true);
          expect(UniqueSolutionValidator.hasUniqueSolution(board), true);
        }
      },
      timeout: const Timeout(Duration(minutes: 5)),
    );

    test('same seed produces an identical complete grid every time', () {
      final gridA =
          PuzzleGenerator(seed: 20260816).generateCompleteGrid().toGrid();
      final gridB =
          PuzzleGenerator(seed: 20260816).generateCompleteGrid().toGrid();
      expect(gridA, equals(gridB));
    });

    test(
      'same seed produces an identical puzzle every time (daily challenge determinism)',
      () {
        final puzzleA =
            PuzzleGenerator(
              seed: 20260816,
            ).generatePuzzleWithDifficulty(Difficulty.medium).toGrid();
        final puzzleB =
            PuzzleGenerator(
              seed: 20260816,
            ).generatePuzzleWithDifficulty(Difficulty.medium).toGrid();
        expect(puzzleA, equals(puzzleB));
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test('different seeds produce different complete grids', () {
      final gridA =
          PuzzleGenerator(seed: 20260816).generateCompleteGrid().toGrid();
      final gridB =
          PuzzleGenerator(seed: 20260817).generateCompleteGrid().toGrid();
      expect(gridA, isNot(equals(gridB)));
    });
  });
}
