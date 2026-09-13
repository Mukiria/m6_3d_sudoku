import 'package:m6_sudoku/features/sudoku/engine/models/cell.dart';

class Board {
  Board({List<List<Cell>>? cells}) : _cells = cells ?? _createEmptyGrid() {
    _initMasks();
  }

  static List<List<Cell>> _createEmptyGrid() {
    return List.generate(
      9,
      (r) => List.generate(9, (c) => Cell(row: r, col: c)),
    );
  }

  final List<List<Cell>> _cells;

  // Bitmasks for fast constraint checking
  // Each row/col/box has a 9-bit mask where bit i (0-8) represents digit i+1
  final List<int> _rowMasks = List.filled(9, 0);
  final List<int> _colMasks = List.filled(9, 0);
  final List<int> _boxMasks = List.filled(9, 0);

  List<List<Cell>> get cells => _cells;

  Cell getCell(int row, int col) => _cells[row][col];

  void setCell(int row, int col, Cell cell) {
    _cells[row][col] = cell;
  }

  int getValue(int row, int col) => _cells[row][col].value;

  void setValue(int row, int col, int value) {
    final cell = _cells[row][col];
    final oldValue = cell.value;

    if (oldValue != 0) {
      final bit = 1 << (oldValue - 1);
      _rowMasks[row] &= ~bit;
      _colMasks[col] &= ~bit;
      _boxMasks[(row ~/ 3) * 3 + (col ~/ 3)] &= ~bit;
    }

    if (value != 0) {
      final bit = 1 << (value - 1);
      _rowMasks[row] |= bit;
      _colMasks[col] |= bit;
      _boxMasks[(row ~/ 3) * 3 + (col ~/ 3)] |= bit;
    }

    _cells[row][col] = cell.copyWith(value: value);
  }

  List<int> getRow(int row) => _cells[row].map((c) => c.value).toList();

  List<int> getCol(int col) => _cells.map((row) => row[col].value).toList();

  List<int> getBox(int boxRow, int boxCol) {
    final values = <int>[];
    for (var r = boxRow * 3; r < boxRow * 3 + 3; r++) {
      for (var c = boxCol * 3; c < boxCol * 3 + 3; c++) {
        values.add(_cells[r][c].value);
      }
    }
    return values;
  }

  List<int> getBoxAt(int row, int col) {
    return getBox(row ~/ 3, col ~/ 3);
  }

  bool isValidPlacement(int row, int col, int value) {
    if (value < 1 || value > 9) return false;
    if (_cells[row][col].isGiven) return false;

    final bit = 1 << (value - 1);
    final boxIndex = (row ~/ 3) * 3 + (col ~/ 3);

    return (_rowMasks[row] & bit) == 0 &&
        (_colMasks[col] & bit) == 0 &&
        (_boxMasks[boxIndex] & bit) == 0;
  }

  int getCandidatesMask(int row, int col) {
    if (_cells[row][col].value != 0) return 0;
    final boxIndex = (row ~/ 3) * 3 + (col ~/ 3);
    final usedMask = _rowMasks[row] | _colMasks[col] | _boxMasks[boxIndex];
    return allCandidates & ~usedMask;
  }

  List<int> getCandidates(int row, int col) {
    final mask = getCandidatesMask(row, col);
    final list = <int>[];
    for (int v = 1; v <= 9; v++) {
      if (mask & (1 << (v - 1)) != 0) {
        list.add(v);
      }
    }
    return list;
  }

  void updateCandidates() {
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        if (_cells[r][c].value == 0) {
          _cells[r][c] = _cells[r][c].copyWith(
            candidates: getCandidatesMask(r, c),
          );
        }
      }
    }
  }

  bool get isComplete {
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        if (_cells[r][c].value == 0) return false;
      }
    }
    return true;
  }

  bool get isValid {
    for (var r = 0; r < 9; r++) {
      final rowVals = getRow(r).where((v) => v != 0).toList();
      if (rowVals.length != rowVals.toSet().length) return false;
    }
    for (var c = 0; c < 9; c++) {
      final colVals = getCol(c).where((v) => v != 0).toList();
      if (colVals.length != colVals.toSet().length) return false;
    }
    for (var br = 0; br < 3; br++) {
      for (var bc = 0; bc < 3; bc++) {
        final boxVals = getBox(br, bc).where((v) => v != 0).toList();
        if (boxVals.length != boxVals.toSet().length) return false;
      }
    }
    return true;
  }

  int get filledCount =>
      _cells.expand((row) => row).where((c) => c.value != 0).length;

  int get getFilledCount => filledCount;

  int get givenCount =>
      _cells.expand((row) => row).where((c) => c.isGiven).length;

  Board copy() {
    final newBoard = Board();
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        newBoard._cells[r][c] = _cells[r][c].copyWith();
      }
      newBoard._rowMasks[r] = _rowMasks[r];
      newBoard._colMasks[r] = _colMasks[r];
      newBoard._boxMasks[r] = _boxMasks[r];
    }
    return newBoard;
  }

  List<List<int>> toGrid() =>
      _cells.map((row) => row.map((c) => c.value).toList()).toList();

  static Board fromGrid(List<List<int>> grid) {
    final board = Board();
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        final value = grid[r][c];
        board._cells[r][c] = Cell(
          row: r,
          col: c,
          value: value,
          isGiven: value != 0,
        );
        if (value != 0) {
          final bit = 1 << (value - 1);
          board._rowMasks[r] |= bit;
          board._colMasks[c] |= bit;
          board._boxMasks[(r ~/ 3) * 3 + (c ~/ 3)] |= bit;
        }
      }
    }
    return board;
  }

  void _initMasks() {
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        final value = _cells[r][c].value;
        if (value != 0) {
          final bit = 1 << (value - 1);
          _rowMasks[r] |= bit;
          _colMasks[c] |= bit;
          _boxMasks[(r ~/ 3) * 3 + (c ~/ 3)] |= bit;
        }
      }
    }
  }

  @override
  String toString() {
    final buffer = StringBuffer();
    for (var r = 0; r < 9; r++) {
      if (r % 3 == 0 && r != 0) buffer.writeln('------+-------+------');
      for (var c = 0; c < 9; c++) {
        if (c % 3 == 0 && c != 0) buffer.write('| ');
        buffer.write('${_cells[r][c].value == 0 ? '.' : _cells[r][c].value} ');
      }
      buffer.writeln();
    }
    return buffer.toString();
  }
}
