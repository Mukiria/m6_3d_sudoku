import 'package:m6_sudoku/features/sudoku/engine/models/difficulty.dart';

/// Human solving techniques, ordered easiest to hardest. A puzzle's grade
/// is the hardest one a logical solve needs (see [TechniqueGrader]).
enum SolvingTechnique {
  nakedSingle,
  hiddenSingle,
  lockedCandidates,
  nakedPair,
  hiddenPair,
  nakedTriple,
  hiddenTriple,
  xWing,
  xyWing,
  swordfish,
  xyzWing,
  wWing,
  simpleColouring,

  /// Type 1 only. Relies on the puzzle having a unique solution, which
  /// every generated and banked puzzle does.
  uniqueRectangle,
  jellyfish,

  /// Not solvable with any technique above — needs chains, forcing or
  /// trial and error.
  beyond,
}

extension SolvingTechniqueDifficulty on SolvingTechnique {
  /// Whether a puzzle whose hardest technique is this one belongs in
  /// [difficulty]. Easy and Medium both solve with singles alone — clue
  /// count (36 vs 30) is what separates them.
  bool fits(Difficulty difficulty) {
    switch (difficulty) {
      case Difficulty.easy:
      case Difficulty.medium:
        return index <= SolvingTechnique.hiddenSingle.index;
      case Difficulty.hard:
        return this == SolvingTechnique.lockedCandidates;
      case Difficulty.expert:
        return index >= SolvingTechnique.nakedPair.index &&
            index <= SolvingTechnique.xWing.index;
      case Difficulty.evil:
        return index >= SolvingTechnique.xyWing.index;
    }
  }
}

/// Grades a puzzle by solving it the way a person would: repeatedly apply
/// the easiest technique that makes progress, and record the hardest one
/// that was ever needed.
///
/// Pure Dart with no Flutter dependencies, like the rest of `engine/`, so
/// it runs in the offline bank-building tool as well as in tests.
class TechniqueGrader {
  TechniqueGrader._(List<int> givens) : _values = List<int>.of(givens) {
    for (var pos = 0; pos < 81; pos++) {
      _candidates[pos] = _values[pos] == 0 ? _all : 0;
    }
    for (var pos = 0; pos < 81; pos++) {
      if (_values[pos] != 0) _eliminateFromPeers(pos, _values[pos]);
    }
  }

  /// The hardest technique needed to solve [grid] (9x9, 0 = empty).
  static SolvingTechnique grade(List<List<int>> grid) => analyse(grid).hardest;

  /// [grade] plus the 81 cell values the logical solve reached (0 where it
  /// got stuck) — lets callers cross-check the solve against a known
  /// solution, since a wrong elimination would otherwise just mis-grade.
  static ({SolvingTechnique hardest, List<int> values}) analyse(
    List<List<int>> grid,
  ) {
    final grader = TechniqueGrader._(grid.expand((row) => row).toList());
    final hardest = grader._solve();
    return (hardest: hardest, values: List<int>.unmodifiable(grader._values));
  }

  static const int _all = 0x1FF;

  final List<int> _values;
  final List<int> _candidates = List<int>.filled(81, 0);

  // Rows 0-8, columns 9-17, boxes 18-26 — each a list of 9 cell positions.
  static final List<List<int>> _units = [
    for (var r = 0; r < 9; r++) [for (var c = 0; c < 9; c++) r * 9 + c],
    for (var c = 0; c < 9; c++) [for (var r = 0; r < 9; r++) r * 9 + c],
    for (var b = 0; b < 9; b++)
      [
        for (var i = 0; i < 9; i++)
          ((b ~/ 3) * 3 + i ~/ 3) * 9 + (b % 3) * 3 + i % 3,
      ],
  ];

  static final List<List<int>> _peers = List.generate(81, (pos) {
    final peers = <int>{};
    for (final unit in _units) {
      if (unit.contains(pos)) peers.addAll(unit);
    }
    return (peers..remove(pos)).toList();
  });

  static bool _sees(int a, int b) => _peers[a].contains(b);

  static int _count(int mask) {
    var count = 0;
    for (var m = mask; m != 0; m &= m - 1) {
      count++;
    }
    return count;
  }

  static int _digitOf(int bit) => bit.bitLength;

  SolvingTechnique _solve() {
    var hardest = SolvingTechnique.nakedSingle;
    while (_values.contains(0)) {
      final used = _step();
      if (used == null) return SolvingTechnique.beyond;
      if (used.index > hardest.index) hardest = used;
    }
    return hardest;
  }

  /// Applies the easiest technique that makes progress; null when stuck.
  SolvingTechnique? _step() {
    if (_nakedSingle()) return SolvingTechnique.nakedSingle;
    if (_hiddenSingle()) return SolvingTechnique.hiddenSingle;
    if (_lockedCandidates()) return SolvingTechnique.lockedCandidates;
    if (_nakedSubset(2)) return SolvingTechnique.nakedPair;
    if (_hiddenSubset(2)) return SolvingTechnique.hiddenPair;
    if (_nakedSubset(3)) return SolvingTechnique.nakedTriple;
    if (_hiddenSubset(3)) return SolvingTechnique.hiddenTriple;
    if (_fish(2)) return SolvingTechnique.xWing;
    if (_xyWing()) return SolvingTechnique.xyWing;
    if (_fish(3)) return SolvingTechnique.swordfish;
    if (_xyzWing()) return SolvingTechnique.xyzWing;
    if (_wWing()) return SolvingTechnique.wWing;
    if (_simpleColouring()) return SolvingTechnique.simpleColouring;
    if (_uniqueRectangle()) return SolvingTechnique.uniqueRectangle;
    if (_fish(4)) return SolvingTechnique.jellyfish;
    return null;
  }

  void _place(int pos, int digit) {
    _values[pos] = digit;
    _candidates[pos] = 0;
    _eliminateFromPeers(pos, digit);
  }

  void _eliminateFromPeers(int pos, int digit) {
    final clear = ~(1 << (digit - 1));
    for (final peer in _peers[pos]) {
      _candidates[peer] &= clear;
    }
  }

  /// Removes [mask] from [pos]'s candidates; true if anything changed.
  bool _eliminate(int pos, int mask) {
    if (_candidates[pos] & mask == 0) return false;
    _candidates[pos] &= ~mask;
    return true;
  }

  bool _nakedSingle() {
    for (var pos = 0; pos < 81; pos++) {
      final mask = _candidates[pos];
      if (_values[pos] == 0 && mask != 0 && mask & (mask - 1) == 0) {
        _place(pos, _digitOf(mask));
        return true;
      }
    }
    return false;
  }

  bool _hiddenSingle() {
    for (final unit in _units) {
      for (var d = 0; d < 9; d++) {
        final bit = 1 << d;
        var found = -1;
        var count = 0;
        for (final pos in unit) {
          if (_candidates[pos] & bit != 0) {
            found = pos;
            count++;
          }
        }
        if (count == 1) {
          _place(found, d + 1);
          return true;
        }
      }
    }
    return false;
  }

  /// Pointing (a box's candidates for a digit all lie in one row/column)
  /// and claiming (a row/column's candidates all lie in one box).
  bool _lockedCandidates() {
    for (var b = 18; b < 27; b++) {
      for (var line = 0; line < 18; line++) {
        if (_lockedBetween(_units[b], _units[line])) return true;
        if (_lockedBetween(_units[line], _units[b])) return true;
      }
    }
    return false;
  }

  /// If every candidate for some digit in [source] also lies in [target],
  /// that digit can be removed from the rest of [target].
  bool _lockedBetween(List<int> source, List<int> target) {
    var progress = false;
    for (var d = 0; d < 9; d++) {
      final bit = 1 << d;
      var inSource = 0;
      var allInTarget = true;
      for (final pos in source) {
        if (_candidates[pos] & bit != 0) {
          inSource++;
          if (!target.contains(pos)) allInTarget = false;
        }
      }
      if (inSource < 2 || !allInTarget) continue;
      for (final pos in target) {
        if (!source.contains(pos) && _eliminate(pos, bit)) progress = true;
      }
    }
    return progress;
  }

  bool _nakedSubset(int size) {
    for (final unit in _units) {
      final open =
          unit.where((pos) {
            final n = _count(_candidates[pos]);
            return n >= 2 && n <= size;
          }).toList();
      for (final combo in _combinations(open, size)) {
        var union = 0;
        for (final pos in combo) {
          union |= _candidates[pos];
        }
        if (_count(union) != size) continue;
        var progress = false;
        for (final pos in unit) {
          if (!combo.contains(pos) && _eliminate(pos, union)) progress = true;
        }
        if (progress) return true;
      }
    }
    return false;
  }

  bool _hiddenSubset(int size) {
    for (final unit in _units) {
      // For each digit, which of the unit's 9 slots can hold it.
      final spots = List<int>.filled(9, 0);
      for (var i = 0; i < 9; i++) {
        final mask = _candidates[unit[i]];
        for (var d = 0; d < 9; d++) {
          if (mask & (1 << d) != 0) spots[d] |= 1 << i;
        }
      }
      final digits = [
        for (var d = 0; d < 9; d++)
          if (_count(spots[d]) >= 2 && _count(spots[d]) <= size) d,
      ];
      for (final combo in _combinations(digits, size)) {
        var slots = 0;
        var digitMask = 0;
        for (final d in combo) {
          slots |= spots[d];
          digitMask |= 1 << d;
        }
        if (_count(slots) != size) continue;
        var progress = false;
        for (var i = 0; i < 9; i++) {
          if (slots & (1 << i) != 0 && _eliminate(unit[i], _all & ~digitMask)) {
            progress = true;
          }
        }
        if (progress) return true;
      }
    }
    return false;
  }

  /// X-Wing (size 2), Swordfish (3) and Jellyfish (4), row- and
  /// column-based.
  bool _fish(int size) {
    for (var d = 0; d < 9; d++) {
      final bit = 1 << d;
      for (final rowBased in [true, false]) {
        // For each base line, the cross-line indices holding the digit.
        final lines = <int, int>{};
        for (var i = 0; i < 9; i++) {
          var cover = 0;
          for (var j = 0; j < 9; j++) {
            final pos = rowBased ? i * 9 + j : j * 9 + i;
            if (_candidates[pos] & bit != 0) cover |= 1 << j;
          }
          final n = _count(cover);
          if (n >= 2 && n <= size) lines[i] = cover;
        }
        for (final combo in _combinations(lines.keys.toList(), size)) {
          var cover = 0;
          for (final i in combo) {
            cover |= lines[i]!;
          }
          if (_count(cover) != size) continue;
          var progress = false;
          for (var j = 0; j < 9; j++) {
            if (cover & (1 << j) == 0) continue;
            for (var i = 0; i < 9; i++) {
              if (combo.contains(i)) continue;
              final pos = rowBased ? i * 9 + j : j * 9 + i;
              if (_eliminate(pos, bit)) progress = true;
            }
          }
          if (progress) return true;
        }
      }
    }
    return false;
  }

  /// A pivot {a,b} seeing pincers {a,c} and {b,c}: c can go in neither
  /// cell that sees both pincers.
  bool _xyWing() {
    final bivalue = [
      for (var pos = 0; pos < 81; pos++)
        if (_count(_candidates[pos]) == 2) pos,
    ];
    for (final pivot in bivalue) {
      final pivotMask = _candidates[pivot];
      final wings =
          bivalue
              .where(
                (pos) =>
                    _sees(pivot, pos) &&
                    _count(_candidates[pos] & pivotMask) == 1,
              )
              .toList();
      for (var i = 0; i < wings.length; i++) {
        for (var j = i + 1; j < wings.length; j++) {
          final a = _candidates[wings[i]];
          final b = _candidates[wings[j]];
          final shared = a & b & ~pivotMask;
          // Pincers must cover different pivot digits and share exactly c.
          if (_count(shared) != 1 || (a & b & pivotMask) != 0) continue;
          var progress = false;
          for (final pos in _peers[wings[i]]) {
            if (pos != pivot &&
                _sees(pos, wings[j]) &&
                _eliminate(pos, shared)) {
              progress = true;
            }
          }
          if (progress) return true;
        }
      }
    }
    return false;
  }

  /// A pivot {x,y,z} seeing pincers {x,z} and {y,z}: z can go in no cell
  /// that sees all three.
  bool _xyzWing() {
    for (var pivot = 0; pivot < 81; pivot++) {
      final pivotMask = _candidates[pivot];
      if (_count(pivotMask) != 3) continue;
      final wings = [
        for (final pos in _peers[pivot])
          if (_count(_candidates[pos]) == 2 &&
              _candidates[pos] & ~pivotMask == 0)
            pos,
      ];
      for (var i = 0; i < wings.length; i++) {
        for (var j = i + 1; j < wings.length; j++) {
          final a = _candidates[wings[i]];
          final b = _candidates[wings[j]];
          final z = a & b;
          if (_count(z) != 1 || (a | b) != pivotMask) continue;
          var progress = false;
          for (final pos in _peers[pivot]) {
            if (pos != wings[i] &&
                pos != wings[j] &&
                _sees(pos, wings[i]) &&
                _sees(pos, wings[j]) &&
                _eliminate(pos, z)) {
              progress = true;
            }
          }
          if (progress) return true;
        }
      }
    }
    return false;
  }

  /// Two {a,b} cells that don't see each other, joined by a strong link on
  /// a (a unit with exactly two a's, one seeing each cell): one of them
  /// must be b, so b can go in no cell that sees both.
  bool _wWing() {
    final bivalue = [
      for (var pos = 0; pos < 81; pos++)
        if (_count(_candidates[pos]) == 2) pos,
    ];
    for (var i = 0; i < bivalue.length; i++) {
      for (var j = i + 1; j < bivalue.length; j++) {
        final p = bivalue[i];
        final q = bivalue[j];
        final mask = _candidates[p];
        if (_candidates[q] != mask || _sees(p, q)) continue;
        for (var m = mask; m != 0; m &= m - 1) {
          final linkBit = m & -m;
          final other = mask & ~linkBit;
          if (!_hasStrongLinkBetween(p, q, linkBit)) continue;
          var progress = false;
          for (final pos in _peers[p]) {
            if (pos != q && _sees(pos, q) && _eliminate(pos, other)) {
              progress = true;
            }
          }
          if (progress) return true;
        }
      }
    }
    return false;
  }

  bool _hasStrongLinkBetween(int p, int q, int bit) {
    for (final unit in _units) {
      final ends = [
        for (final pos in unit)
          if (_candidates[pos] & bit != 0) pos,
      ];
      if (ends.length != 2 || ends.contains(p) || ends.contains(q)) continue;
      if ((_sees(ends[0], p) && _sees(ends[1], q)) ||
          (_sees(ends[1], p) && _sees(ends[0], q))) {
        return true;
      }
    }
    return false;
  }

  /// Single-digit colouring over strong links (units with exactly two
  /// candidates for the digit). Colour wrap: if two cells of one colour
  /// see each other, that whole colour is false. Colour trap: a cell
  /// seeing both colours can't hold the digit.
  bool _simpleColouring() {
    for (var d = 0; d < 9; d++) {
      final bit = 1 << d;
      final links = <int, List<int>>{};
      for (final unit in _units) {
        final ends = [
          for (final pos in unit)
            if (_candidates[pos] & bit != 0) pos,
        ];
        if (ends.length != 2) continue;
        links.putIfAbsent(ends[0], () => []).add(ends[1]);
        links.putIfAbsent(ends[1], () => []).add(ends[0]);
      }

      final colour = <int, int>{};
      for (final start in links.keys) {
        if (colour.containsKey(start)) continue;
        final component = <int>[start];
        colour[start] = 0;
        for (var k = 0; k < component.length; k++) {
          final pos = component[k];
          for (final next in links[pos]!) {
            if (colour.containsKey(next)) continue;
            colour[next] = 1 - colour[pos]!;
            component.add(next);
          }
        }
        if (component.length < 3) continue;

        for (final c in [0, 1]) {
          final same = component.where((pos) => colour[pos] == c).toList();
          final wraps = _combinations(
            same,
            2,
          ).any((pair) => _sees(pair[0], pair[1]));
          if (wraps) {
            for (final pos in same) {
              _eliminate(pos, bit);
            }
            return true;
          }
        }

        var progress = false;
        for (var pos = 0; pos < 81; pos++) {
          if (_candidates[pos] & bit == 0 || colour.containsKey(pos)) continue;
          var seesColours = 0;
          for (final other in component) {
            if (_sees(pos, other)) seesColours |= 1 << colour[other]!;
          }
          if (seesColours == 3 && _eliminate(pos, bit)) progress = true;
        }
        if (progress) return true;
      }
    }
    return false;
  }

  /// Type 1: three corners of a rectangle spanning two boxes are {a,b};
  /// the fourth can't also resolve to a or b, or the puzzle would have
  /// two solutions.
  bool _uniqueRectangle() {
    for (var r1 = 0; r1 < 9; r1++) {
      for (var r2 = r1 + 1; r2 < 9; r2++) {
        for (var c1 = 0; c1 < 9; c1++) {
          for (var c2 = c1 + 1; c2 < 9; c2++) {
            // Exactly two boxes: same band or same stack, not both.
            if ((r1 ~/ 3 == r2 ~/ 3) == (c1 ~/ 3 == c2 ~/ 3)) continue;
            final corners = [
              r1 * 9 + c1,
              r1 * 9 + c2,
              r2 * 9 + c1,
              r2 * 9 + c2,
            ];
            final pairs =
                corners.where((pos) => _count(_candidates[pos]) == 2).toList();
            if (pairs.length != 3) continue;
            final ab = _candidates[pairs[0]];
            if (pairs.any((pos) => _candidates[pos] != ab)) continue;
            final fourth = corners.firstWhere((pos) => !pairs.contains(pos));
            if (_candidates[fourth] & ab == ab &&
                _count(_candidates[fourth]) > 2 &&
                _eliminate(fourth, ab)) {
              return true;
            }
          }
        }
      }
    }
    return false;
  }

  static Iterable<List<T>> _combinations<T>(List<T> items, int size) sync* {
    if (size == 0) {
      yield <T>[];
      return;
    }
    for (var i = 0; i <= items.length - size; i++) {
      for (final rest in _combinations(items.sublist(i + 1), size - 1)) {
        yield [items[i], ...rest];
      }
    }
  }
}
