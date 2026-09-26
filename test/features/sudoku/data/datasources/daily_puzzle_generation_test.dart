import 'package:flutter_test/flutter_test.dart';
import 'package:m6_sudoku/features/sudoku/data/datasources/daily_challenge_local_datasource.dart';
import 'package:m6_sudoku/features/sudoku/engine/generator/puzzle_generator.dart';
import 'package:m6_sudoku/features/sudoku/engine/grader/technique_grader.dart';
import 'package:m6_sudoku/features/sudoku/engine/models/difficulty.dart';

String _cells(PuzzleGenerationResult result) =>
    result.grid.expand((row) => row).join();

void main() {
  // Every day of a year, as YYYYMMDD seeds.
  final seeds = [
    for (
      var d = DateTime.utc(2026);
      d.year == 2026;
      d = d.add(const Duration(days: 1))
    )
      d.year * 10000 + d.month * 100 + d.day,
  ];

  group('generateDailyPuzzle', () {
    test('is deterministic for a date', () {
      expect(
        _cells(generateDailyPuzzle(20260926)),
        _cells(generateDailyPuzzle(20260926)),
      );
    });

    test('every day of a year grades as Medium', () {
      var replaced = 0;
      for (final seed in seeds) {
        final daily = generateDailyPuzzle(seed);
        expect(
          TechniqueGrader.grade(daily.grid).fits(Difficulty.medium),
          true,
          reason: 'date $seed',
        );

        final original = generatePuzzleInBackground((
          difficulty: Difficulty.medium,
          seed: seed,
        ));
        if (TechniqueGrader.grade(original.grid).fits(Difficulty.medium)) {
          // Days that were already fine keep the puzzle they always had.
          expect(_cells(daily), _cells(original), reason: 'date $seed');
        } else {
          replaced++;
        }
      }
      // Sanity check that the grading actually matters for some days.
      expect(replaced, greaterThan(0));
    });

    test('different dates get different puzzles', () {
      final puzzles = seeds.take(60).map(generateDailyPuzzle).map(_cells);
      expect(puzzles.toSet(), hasLength(60));
    });
  });
}
