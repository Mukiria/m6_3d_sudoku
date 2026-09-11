/// Bitmask-based Sudoku candidate computation.
///
/// Previously duplicated in two places that had drifted onto different
/// algorithms for the same rule — "which digits can legally go in this
/// cell" — despite needing to stay in exact agreement: the notes engine in
/// `GameController` (bitmask-based, fast) and the hint engine in
/// `GetHintUseCase` (a slower Set-rebuild scan repeated per cell, per
/// digit). Sharing one implementation means a future rule change (e.g. a
/// Sudoku variant with different regions) only needs to happen once, and
/// the hint engine now gets the faster algorithm for free.
library;

/// Bits 0-8 of the mask represent digits 1-9.
const int _allCandidates = 0x1FF;

/// For every cell in a 9x9 grid, the set of digits 1-9 that could legally
/// go there given the values already present.
///
/// [userGrid] holds entered values (0 = empty); [givensGrid] holds the
/// puzzle's fixed clues (0 = not a given) — a cell counts as filled if
/// either grid has a non-zero value there, and only cells empty in *both*
/// get candidates computed. Pass the same grid for both if there's no
/// separate givens grid.
List<List<Set<int>>> computeCandidateGrid(
  List<List<int>> userGrid,
  List<List<int>> givensGrid,
) {
  final rowMasks = List.filled(9, 0);
  final colMasks = List.filled(9, 0);
  final boxMasks = List.filled(9, 0);

  for (int r = 0; r < 9; r++) {
    for (int c = 0; c < 9; c++) {
      final val = userGrid[r][c] != 0 ? userGrid[r][c] : givensGrid[r][c];
      if (val != 0) {
        final bit = 1 << (val - 1);
        rowMasks[r] |= bit;
        colMasks[c] |= bit;
        boxMasks[(r ~/ 3) * 3 + (c ~/ 3)] |= bit;
      }
    }
  }

  return List.generate(9, (r) {
    return List.generate(9, (c) {
      if (userGrid[r][c] != 0 || givensGrid[r][c] != 0) return <int>{};
      final boxIndex = (r ~/ 3) * 3 + (c ~/ 3);
      final usedMask = rowMasks[r] | colMasks[c] | boxMasks[boxIndex];
      final mask = _allCandidates & ~usedMask;
      if (mask == 0) return <int>{};
      final set = <int>{};
      var m = mask;
      while (m != 0) {
        final bit = m & -m;
        set.add(_bitToDigit(bit));
        m &= m - 1;
      }
      return set;
    });
  });
}

int _bitToDigit(int bit) {
  switch (bit) {
    case 0x001:
      return 1;
    case 0x002:
      return 2;
    case 0x004:
      return 3;
    case 0x008:
      return 4;
    case 0x010:
      return 5;
    case 0x020:
      return 6;
    case 0x040:
      return 7;
    case 0x080:
      return 8;
    case 0x100:
      return 9;
    default:
      return 0;
  }
}
