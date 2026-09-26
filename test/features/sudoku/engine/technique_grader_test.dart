import 'package:flutter_test/flutter_test.dart';
import 'package:m6_sudoku/features/sudoku/engine/grader/technique_grader.dart';
import 'package:m6_sudoku/features/sudoku/engine/models/difficulty.dart';

List<List<int>> _grid(String cells) => List.generate(
  9,
  (r) => List.generate(9, (c) => cells.codeUnitAt(r * 9 + c) - 0x30),
);

void main() {
  // Project Euler #96, grid 01 — a classic singles-only puzzle.
  const singlesPuzzle =
      '003020600900305001001806400008102900700000008006708200002609500800203009005010300';
  const singlesSolution =
      '483921657967345821251876493548132976729564138136798245372689514814253769695417382';

  // Arto Inkala's widely published "world's hardest sudoku".
  const inkala =
      '800000000003600000070090200050007000000045700000100030001000068008500010090000400';

  group('TechniqueGrader', () {
    test('grades a singles-only puzzle as needing singles', () {
      final grade = TechniqueGrader.grade(_grid(singlesPuzzle));

      expect(
        grade.index,
        lessThanOrEqualTo(SolvingTechnique.hiddenSingle.index),
      );
    });

    test('logical solve reaches the real solution', () {
      final analysis = TechniqueGrader.analyse(_grid(singlesPuzzle));

      expect(analysis.values.join(), singlesSolution);
    });

    test('grades a notoriously hard puzzle as beyond basic techniques', () {
      expect(TechniqueGrader.grade(_grid(inkala)), SolvingTechnique.beyond);
    });

    test('a solved grid needs nothing beyond a naked single', () {
      expect(
        TechniqueGrader.grade(_grid(singlesSolution)),
        SolvingTechnique.nakedSingle,
      );
    });
  });

  group('SolvingTechnique.fits', () {
    test('each technique fits exactly one of Hard/Expert/Evil, or Easy and '
        'Medium together', () {
      for (final technique in SolvingTechnique.values) {
        final tiers = Difficulty.values.where((d) => technique.fits(d)).toSet();
        final singles = technique.index <= SolvingTechnique.hiddenSingle.index;
        expect(
          tiers,
          singles ? {Difficulty.easy, Difficulty.medium} : hasLength(1),
          reason: technique.name,
        );
      }
    });

    test('difficulty rises with technique', () {
      expect(SolvingTechnique.hiddenSingle.fits(Difficulty.medium), true);
      expect(SolvingTechnique.lockedCandidates.fits(Difficulty.hard), true);
      expect(SolvingTechnique.xWing.fits(Difficulty.expert), true);
      expect(SolvingTechnique.swordfish.fits(Difficulty.evil), true);
      expect(SolvingTechnique.beyond.fits(Difficulty.evil), true);
    });
  });
}
