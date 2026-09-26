import 'package:flutter_test/flutter_test.dart';
import 'package:m6_sudoku/features/sudoku/engine/generator/puzzle_generator.dart';
import 'package:m6_sudoku/features/sudoku/engine/models/board.dart';
import 'package:m6_sudoku/features/sudoku/engine/models/difficulty.dart';
import 'package:m6_sudoku/features/sudoku/engine/solver/sudoku_solver.dart';
import 'package:m6_sudoku/features/sudoku/engine/validator/unique_solution_validator.dart';

void main() {
  group('PuzzleGenerator - Basic Tests', () {
    group('generateCompleteGrid', () {
      test('generates valid complete grid', () {
        final generator = PuzzleGenerator(seed: 42);
        final board = generator.generateCompleteGrid();

        expect(board.isComplete, true);
        expect(board.isValid, true);
        expect(board.filledCount, 81);
      });

      test('generates different grids with different seeds', () {
        final generator1 = PuzzleGenerator(seed: 1);
        final generator2 = PuzzleGenerator(seed: 2);

        final board1 = generator1.generateCompleteGrid();
        final board2 = generator2.generateCompleteGrid();

        // Grids should be different (extremely high probability)
        final grid1 = board1.toGrid();
        final grid2 = board2.toGrid();

        bool different = false;
        for (int r = 0; r < 9; r++) {
          for (int c = 0; c < 9; c++) {
            if (grid1[r][c] != grid2[r][c]) {
              different = true;
              break;
            }
          }
        }
        expect(different, true);
      });
    });

    group('generatePuzzle', () {
      test('generates puzzle with correct clue count', () {
        final generator = PuzzleGenerator(seed: 42);
        final board = generator.generatePuzzle(clues: 30, maxAttempts: 10);

        expect(board.filledCount, 30);
        expect(board.isValid, true);
      });

      test('generated puzzle has unique solution', () {
        final generator = PuzzleGenerator(seed: 42);
        final board = generator.generatePuzzle(clues: 25, maxAttempts: 10);

        expect(UniqueSolutionValidator.hasUniqueSolution(board), true);
      });

      test('puzzle solution is valid', () {
        final generator = PuzzleGenerator(seed: 42);
        final board = generator.generatePuzzle(clues: 25, maxAttempts: 10);

        // Solve the puzzle
        final solutionBoard = board.copy();
        final solved = SudokuSolver.solve(solutionBoard);
        expect(solved, true);
        expect(solutionBoard.isValid, true);
      });
    });

    group('generatePuzzleWithDifficulty', () {
      test('generates easy puzzle', () {
        final generator = PuzzleGenerator(seed: 42);
        final board = generator.generatePuzzleWithDifficulty(Difficulty.easy);

        expect(board.isValid, true);
        expect(UniqueSolutionValidator.hasUniqueSolution(board), true);
      });
    });

    group('time budget', () {
      test('stops retrying once the budget is spent', () {
        final generator = PuzzleGenerator(seed: 42);
        final stopwatch = Stopwatch()..start();
        // An unreachable target would otherwise run all 10,000 attempts.
        final board = generator.generatePuzzle(
          clues: 17,
          maxAttempts: 10000,
          timeBudget: const Duration(milliseconds: 200),
        );

        expect(stopwatch.elapsed, lessThan(const Duration(seconds: 5)));
        expect(board.isValid, true);
        expect(UniqueSolutionValidator.hasUniqueSolution(board), true);
      });

      test('unseeded evil puzzle generates quickly and is unique', () {
        final stopwatch = Stopwatch()..start();
        final result = generatePuzzleInBackground((
          difficulty: Difficulty.evil,
          seed: null,
        ));

        expect(
          stopwatch.elapsed,
          lessThan(
            PuzzleGenerator.unseededTimeBudget + const Duration(seconds: 3),
          ),
        );
        expect(result.cluesCount, lessThanOrEqualTo(24));
        expect(
          UniqueSolutionValidator.hasUniqueSolution(
            Board.fromGrid(result.grid),
          ),
          true,
        );
      });
    });

    group('Edge Cases', () {
      test('generates puzzle with 25 clues', () {
        final generator = PuzzleGenerator(seed: 42);
        final board = generator.generatePuzzle(clues: 25, maxAttempts: 10);

        expect(board.filledCount, greaterThanOrEqualTo(25));
        expect(board.isValid, true);
      });
    });
  });
}
