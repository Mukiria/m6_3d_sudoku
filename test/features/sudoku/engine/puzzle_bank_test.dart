import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:m6_sudoku/features/sudoku/engine/bank/puzzle_bank.dart';
import 'package:m6_sudoku/features/sudoku/engine/grader/technique_grader.dart';
import 'package:m6_sudoku/features/sudoku/engine/models/board.dart';
import 'package:m6_sudoku/features/sudoku/engine/models/difficulty.dart';
import 'package:m6_sudoku/features/sudoku/engine/validator/unique_solution_validator.dart';

const _puzzle =
    '003020600900305001001806400008102900700000008006708200002609500800203009005010300';
const _solution =
    '483921657967345821251876493548132976729564138136798245372689514814253769695417382';

bool _isValidSolution(List<List<int>> grid) =>
    Board.fromGrid(grid).isValid && Board.fromGrid(grid).isComplete;

void main() {
  group('PuzzleBank.parse', () {
    test('skips comments and blank lines', () {
      final bank = PuzzleBank.parse(
        '# header\n\n$_puzzle $_solution hiddenSingle\n',
      );

      expect(bank.length, 1);
    });

    test('rejects malformed lines', () {
      expect(() => PuzzleBank.parse('123 456'), throwsFormatException);
      expect(
        () => PuzzleBank.parse('$_puzzle $_puzzle'),
        throwsFormatException,
        reason: 'a solution may not contain empty cells',
      );
    });
  });

  group('PuzzleBank.draw', () {
    test('transformed puzzles stay consistent, unique and equally hard', () {
      final bank = PuzzleBank.parse('$_puzzle $_solution hiddenSingle');
      final original = TechniqueGrader.grade(
        List.generate(
          9,
          (r) => List.generate(9, (c) => _puzzle.codeUnitAt(r * 9 + c) - 48),
        ),
      );
      final random = Random(1);

      for (var i = 0; i < 20; i++) {
        final drawn = bank.draw(random);

        expect(_isValidSolution(drawn.solution), true);
        for (var r = 0; r < 9; r++) {
          for (var c = 0; c < 9; c++) {
            final given = drawn.grid[r][c];
            if (given != 0) expect(given, drawn.solution[r][c]);
          }
        }
        expect(drawn.cluesCount, 32);
        expect(
          UniqueSolutionValidator.hasUniqueSolution(Board.fromGrid(drawn.grid)),
          true,
        );
        expect(TechniqueGrader.grade(drawn.grid), original);
      }
    });

    test('disguises repeats of the same entry', () {
      final bank = PuzzleBank.parse('$_puzzle $_solution hiddenSingle');
      final random = Random(2);
      final seen = {
        for (var i = 0; i < 20; i++)
          bank.draw(random).grid.expand((row) => row).join(),
      };

      expect(seen.length, greaterThan(15));
    });
  });

  // The shipped banks, read straight from disk so a bad rebuild of
  // tool/build_puzzle_bank.dart fails here rather than on a player's phone.
  group('bundled banks', () {
    for (final difficulty in Difficulty.values) {
      test('${difficulty.name} bank is well-formed and correctly graded', () {
        final text =
            File('assets/puzzles/${difficulty.name}.txt').readAsStringSync();
        final bank = PuzzleBank.parse(text);
        expect(bank.length, greaterThanOrEqualTo(100));

        final lines =
            text
                .split('\n')
                .where((l) => l.isNotEmpty && !l.startsWith('#'))
                .toList();
        final beyond = lines.where(
          (l) => l.endsWith(' ${SolvingTechnique.beyond.name}'),
        );
        expect(
          beyond.length,
          lessThanOrEqualTo(lines.length ~/ 3),
          reason: 'most puzzles should be solvable with named techniques',
        );

        for (final line in lines) {
          final [puzzle, solution, technique] = line.split(' ');
          final grid = List.generate(
            9,
            (r) => List.generate(9, (c) => puzzle.codeUnitAt(r * 9 + c) - 48),
          );
          final analysis = TechniqueGrader.analyse(grid);

          expect(analysis.hardest.name, technique, reason: puzzle);
          expect(analysis.hardest.fits(difficulty), true, reason: puzzle);
          for (var pos = 0; pos < 81; pos++) {
            final given = puzzle.codeUnitAt(pos) - 48;
            if (given != 0) {
              expect(given, solution.codeUnitAt(pos) - 48, reason: puzzle);
            }
          }
          // A complete logical solve already proves uniqueness; only
          // puzzles the grader couldn't finish need the brute-force check.
          if (analysis.hardest == SolvingTechnique.beyond) {
            expect(
              UniqueSolutionValidator.hasUniqueSolution(Board.fromGrid(grid)),
              true,
              reason: puzzle,
            );
          } else {
            expect(analysis.values.join(), solution, reason: puzzle);
          }
        }
      });
    }
  });
}
