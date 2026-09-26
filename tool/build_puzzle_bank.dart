// Builds assets/puzzles/<difficulty>.txt — the pre-graded puzzle banks the
// app draws new games from (see PuzzleBank).
//
//   dart run tool/build_puzzle_bank.dart [puzzlesPerDifficulty=300]
//
// Generates puzzles at each difficulty's clue target, grades them with
// TechniqueGrader, and keeps only those whose hardest technique fits the
// difficulty. At most a third of Evil may be `beyond` (needing chains or
// trial and error) so most Evil puzzles are hard but learnable with named
// techniques. Seeds are fixed, so a rebuild with the same code gives the
// same banks. Takes a few minutes; Evil is the slow one.

import 'dart:io';
import 'dart:isolate';

import 'package:m6_sudoku/features/sudoku/engine/generator/puzzle_generator.dart';
import 'package:m6_sudoku/features/sudoku/engine/grader/technique_grader.dart';
import 'package:m6_sudoku/features/sudoku/engine/models/difficulty.dart';

typedef _Entry = ({String puzzle, String solution, SolvingTechnique grade});

Future<void> main(List<String> args) async {
  final perDifficulty = args.isEmpty ? 300 : int.parse(args.first);
  final workers = Platform.numberOfProcessors;
  Directory('assets/puzzles').createSync(recursive: true);

  for (final difficulty in Difficulty.values) {
    final stopwatch = Stopwatch()..start();
    final accepted = <String, _Entry>{};
    final maxBeyond = perDifficulty ~/ 3;
    var beyond = 0;
    var nextSeed = 0;

    while (accepted.length < perDifficulty) {
      // Each round, every worker tries a disjoint batch of seeds.
      const batch = 20;
      final rounds = [
        for (var w = 0; w < workers; w++)
          _spawn(difficulty, nextSeed + w * batch, batch),
      ];
      nextSeed += workers * batch;
      for (final found in await Future.wait(rounds)) {
        for (final entry in found) {
          if (accepted.length >= perDifficulty ||
              accepted.containsKey(entry.puzzle)) {
            continue;
          }
          if (entry.grade == SolvingTechnique.beyond) {
            if (beyond >= maxBeyond) continue;
            beyond++;
          }
          accepted[entry.puzzle] = entry;
        }
      }
    }

    final techniques = <String, int>{};
    for (final entry in accepted.values) {
      techniques.update(entry.grade.name, (n) => n + 1, ifAbsent: () => 1);
    }
    File('assets/puzzles/${difficulty.name}.txt').writeAsStringSync(
      [
        '# ${difficulty.name}: ${accepted.length} puzzles, built by '
            'tool/build_puzzle_bank.dart — do not edit by hand.',
        '# <puzzle> <solution> <hardest technique>',
        for (final e in accepted.values)
          '${e.puzzle} ${e.solution} ${e.grade.name}',
        '',
      ].join('\n'),
    );
    stdout.writeln(
      '${difficulty.name}: ${accepted.length} from $nextSeed tries in '
      '${stopwatch.elapsed.inSeconds}s  $techniques',
    );
  }
}

// A separate function so the isolate closure captures only these three
// values, not main's changing loop state.
Future<List<_Entry>> _spawn(Difficulty difficulty, int firstSeed, int count) =>
    Isolate.run(() => _search(difficulty, firstSeed, count));

/// Seeds are offset per difficulty so banks don't share complete grids.
List<_Entry> _search(Difficulty difficulty, int firstSeed, int count) {
  final found = <_Entry>[];
  for (var i = 0; i < count; i++) {
    final seed = difficulty.index * 1000000007 + firstSeed + i;
    final result = generatePuzzleInBackground((
      difficulty: difficulty,
      seed: seed,
    ));
    final analysis = TechniqueGrader.analyse(result.grid);
    if (!analysis.hardest.fits(difficulty)) continue;

    final solution = result.solution.expand((row) => row).toList();
    // A logical solve that disagrees with the real solution means a grader
    // bug, not a hard puzzle — never ship it.
    for (var pos = 0; pos < 81; pos++) {
      final value = analysis.values[pos];
      if (value != 0 && value != solution[pos]) {
        throw StateError('Grader contradicted the solution (seed $seed)');
      }
    }

    found.add((
      puzzle: result.grid.expand((row) => row).join(),
      solution: solution.join(),
      grade: analysis.hardest,
    ));
  }
  return found;
}
