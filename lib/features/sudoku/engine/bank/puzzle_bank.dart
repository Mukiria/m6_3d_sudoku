import 'dart:math';

import 'package:m6_sudoku/features/sudoku/engine/generator/puzzle_generator.dart';

/// A pre-built set of puzzles for one difficulty, graded offline by
/// `tool/build_puzzle_bank.dart` so that each one genuinely needs its
/// difficulty's techniques (see `TechniqueGrader`). Finding those — Evil
/// especially — takes far too long to do on the phone.
///
/// Text format, one puzzle per line: 81 digits of puzzle (0 = empty), a
/// space, 81 digits of solution, a space, the technique it was graded by.
/// Blank lines and lines starting with `#` are ignored.
class PuzzleBank {
  PuzzleBank._(this._entries);

  factory PuzzleBank.parse(String text) {
    final entries = <({String puzzle, String solution})>[];
    for (final raw in text.split('\n')) {
      final line = raw.trim();
      if (line.isEmpty || line.startsWith('#')) continue;
      final parts = line.split(' ');
      if (parts.length < 2 ||
          !_isGrid(parts[0], allowEmpty: true) ||
          !_isGrid(parts[1], allowEmpty: false)) {
        throw FormatException('Bad puzzle bank line', line);
      }
      entries.add((puzzle: parts[0], solution: parts[1]));
    }
    return PuzzleBank._(entries);
  }

  final List<({String puzzle, String solution})> _entries;

  int get length => _entries.length;

  bool get isEmpty => _entries.isEmpty;

  static bool _isGrid(String s, {required bool allowEmpty}) =>
      s.length == 81 &&
      s.codeUnits.every((u) => u >= (allowEmpty ? 0x30 : 0x31) && u <= 0x39);

  /// A random puzzle from the bank, disguised by a random validity-
  /// preserving transform (digit relabelling, row/column swaps within a
  /// band/stack, band/stack swaps, transposition). The transform keeps the
  /// solution unique and the solving path — and so the grade — identical,
  /// while making repeats of the same bank entry unrecognisable.
  PuzzleGenerationResult draw(Random random) {
    final entry = _entries[random.nextInt(_entries.length)];
    final transform = _Transform.random(random);
    final grid = transform.apply(entry.puzzle);
    return (
      grid: grid,
      solution: transform.apply(entry.solution),
      cluesCount: grid.expand((row) => row).where((v) => v != 0).length,
    );
  }
}

class _Transform {
  _Transform(this._digits, this._rows, this._cols, this._transpose);

  factory _Transform.random(Random random) {
    final digits = List<int>.generate(9, (i) => i + 1)..shuffle(random);
    return _Transform(
      [0, ...digits],
      _lineOrder(random),
      _lineOrder(random),
      random.nextBool(),
    );
  }

  /// A permutation of 0-8 that shuffles the three bands and the three
  /// lines inside each band — the only line reorderings Sudoku allows.
  static List<int> _lineOrder(Random random) {
    final bands = [0, 1, 2]..shuffle(random);
    return [
      for (final band in bands)
        ...([0, 1, 2]..shuffle(random)).map((i) => band * 3 + i),
    ];
  }

  final List<int> _digits;
  final List<int> _rows;
  final List<int> _cols;
  final bool _transpose;

  List<List<int>> apply(String cells) {
    return List.generate(9, (r) {
      return List.generate(9, (c) {
        final sr = _transpose ? _cols[c] : _rows[r];
        final sc = _transpose ? _rows[r] : _cols[c];
        return _digits[cells.codeUnitAt(sr * 9 + sc) - 0x30];
      });
    });
  }
}
