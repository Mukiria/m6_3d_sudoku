import 'package:flutter_test/flutter_test.dart';
import 'package:m6_sudoku/features/cube_sudoku/data/datasources/cube_game_local_datasource.dart';
import 'package:m6_sudoku/features/cube_sudoku/domain/entities/cube_face.dart';
import 'package:m6_sudoku/features/sudoku/data/datasources/puzzle_bank_source.dart';
import 'package:m6_sudoku/features/sudoku/data/datasources/puzzle_local_datasource.dart';
import 'package:m6_sudoku/features/sudoku/engine/models/difficulty.dart';

import '../../../../fakes/fake_services.dart';

// 32 clues — distinguishable from a live-generated Easy puzzle's 36.
const _bankLine =
    '003020600900305001001806400008102900700000008006708200002609500800203009005010300 '
    '483921657967345821251876493548132976729564138136798245372689514814253769695417382 '
    'hiddenSingle';

PuzzleBankSource _bankWith(Map<String, String> assets) {
  return PuzzleBankSource(
    loadAsset: (path) async {
      final text = assets[path];
      if (text == null) throw Exception('missing asset $path');
      return text;
    },
  );
}

void main() {
  group('PuzzleBankSource', () {
    test('draws from the difficulty\'s bank asset', () async {
      final source = _bankWith({'assets/puzzles/easy.txt': _bankLine});

      final result = await source.draw(Difficulty.easy);

      expect(result, isNotNull);
      expect(result!.cluesCount, 32);
    });

    test('returns null when the asset is missing or malformed', () async {
      final source = _bankWith({'assets/puzzles/hard.txt': 'not a puzzle'});

      expect(await source.draw(Difficulty.easy), isNull);
      expect(await source.draw(Difficulty.hard), isNull);
    });

    test('loads each asset only once', () async {
      var loads = 0;
      final source = PuzzleBankSource(
        loadAsset: (_) async {
          loads++;
          return _bankLine;
        },
      );

      await source.draw(Difficulty.easy);
      await source.draw(Difficulty.easy);

      expect(loads, 1);
    });
  });

  group('PuzzleLocalDataSource with a bank', () {
    test('serves new games from the bank', () async {
      final ds = PuzzleLocalDataSource(
        FakeStorageService(),
        null,
        _bankWith({'assets/puzzles/easy.txt': _bankLine}),
      );

      final result = await ds.generatePuzzle('easy');

      expect(result.getOrElse(() => throw 'failed').cluesCount, 32);
    });

    test('consecutive new games are different puzzles', () async {
      final ds = PuzzleLocalDataSource(
        FakeStorageService(),
        null,
        _bankWith({'assets/puzzles/easy.txt': _bankLine}),
      );

      final grids = <String>[];
      for (var i = 0; i < 4; i++) {
        final puzzle = (await ds.generatePuzzle(
          'easy',
        )).getOrElse(() => throw 'failed');
        grids.add(puzzle.grid.expand((row) => row).join());
      }

      expect(grids.toSet(), hasLength(4));
    });

    test('falls back to live generation without a bank', () async {
      final ds = PuzzleLocalDataSource(
        FakeStorageService(),
        null,
        _bankWith({}),
      );

      final result = await ds.generatePuzzle('easy');

      expect(result.getOrElse(() => throw 'failed').cluesCount, 36);
    });
  });

  test('CubeGameLocalDataSource serves every face from the bank', () async {
    final ds = CubeGameLocalDataSource(
      FakeStorageService(),
      null,
      _bankWith({'assets/puzzles/easy.txt': _bankLine}),
    );

    final result = await ds.generateCubePuzzles({
      for (final face in CubeFace.values) face: Difficulty.easy,
    });
    final puzzles = result.getOrElse(() => throw 'failed');

    expect(puzzles.length, 6);
    expect(puzzles.values.every((p) => p.cluesCount == 32), true);
  });
}
