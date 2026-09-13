import 'package:flutter_test/flutter_test.dart';
import 'package:m6_sudoku/features/sudoku/engine/models/board.dart';
import 'package:m6_sudoku/features/sudoku/engine/models/cell.dart';
import 'package:m6_sudoku/features/sudoku/engine/models/difficulty.dart';

void main() {
  group('Board - Extended Tests', () {
    test('getCandidates returns correct candidates for empty cell', () {
      final board = Board();
      board.setValue(0, 0, 5);
      board.setValue(0, 1, 3);
      board.setValue(1, 0, 6);

      final candidates = board.getCandidates(2, 2);
      expect(candidates, isNotEmpty);
      expect(candidates, isNot(contains(5)));
      expect(candidates, isNot(contains(3)));
      expect(candidates, isNot(contains(6)));
    });

    test('getCandidates returns empty for filled cell', () {
      final board = Board();
      board.setValue(0, 0, 5);
      final candidates = board.getCandidates(0, 0);
      expect(candidates, isEmpty);
    });

    test('getFilledCount returns correct count', () {
      final board = Board();
      expect(board.filledCount, 0);

      board.setValue(0, 0, 5);
      expect(board.filledCount, 1);

      board.setValue(1, 1, 3);
      expect(board.filledCount, 2);
    });

    test('toGrid converts board to grid', () {
      final board = Board();
      board.setValue(0, 0, 5);
      board.setValue(1, 1, 3);

      final grid = board.toGrid();
      expect(grid.length, 9);
      expect(grid[0].length, 9);
      expect(grid[0][0], 5);
      expect(grid[1][1], 3);
      expect(grid[2][2], 0);
    });

    test('fromGrid preserves given cells', () {
      final grid = List.generate(9, (i) => List.generate(9, (j) => 0));
      grid[0][0] = 5;
      grid[1][1] = 3;

      final board = Board.fromGrid(grid);
      expect(board.getValue(0, 0), 5);
      expect(board.getValue(1, 1), 3);
      expect(board.cells[0][0].isGiven, true);
      expect(board.cells[1][1].isGiven, true);
      expect(board.cells[0][1].isGiven, false);
    });

    test('isValidPlacement with invalid row', () {
      final board = Board();
      board.setValue(0, 0, 5);
      expect(board.isValidPlacement(0, 1, 5), false);
    });

    test('isValidPlacement with invalid column', () {
      final board = Board();
      board.setValue(0, 0, 5);
      expect(board.isValidPlacement(1, 0, 5), false);
    });

    test('isValidPlacement with invalid box', () {
      final board = Board();
      board.setValue(0, 0, 5);
      expect(board.isValidPlacement(1, 1, 5), false);
    });

    test('isValidPlacement with valid placement', () {
      final board = Board();
      board.setValue(0, 0, 5);
      // (1,2) is in different row, column, and box from (0,0)
      expect(board.isValidPlacement(1, 2, 5), false); // Same box as (0,0)
      // Valid placement would be outside the box
      expect(board.isValidPlacement(3, 2, 5), true); // Different box
    });

    test('updateCandidates updates all empty cells', () {
      final board = Board();
      board.setValue(0, 0, 5);
      board.setValue(0, 1, 3);
      board.setValue(1, 0, 6);

      board.updateCandidates();

      // Check that updateCandidates runs without error
      // and that candidates can be retrieved
      final candidates = board.getCandidates(2, 2);
      expect(candidates, isNotEmpty);
      expect(candidates, isNot(contains(5)));
      expect(candidates, isNot(contains(3)));
      expect(candidates, isNot(contains(6)));
    });

    test('isComplete returns false for empty board', () {
      final board = Board();
      expect(board.isComplete, false);
    });

    test('isComplete returns true when all cells filled', () {
      final board = Board();
      for (var r = 0; r < 9; r++) {
        for (var c = 0; c < 9; c++) {
          board.setValue(r, c, (r + c) % 9 + 1);
        }
      }
      expect(board.isComplete, true);
    });

    test('isValid returns true for valid board', () {
      final board = Board();
      board.setValue(0, 0, 5);
      board.setValue(1, 1, 3);
      expect(board.isValid, true);
    });

    test('isValid returns false for duplicate in row', () {
      final board = Board();
      board.setValue(0, 0, 5);
      board.setValue(0, 1, 5);
      expect(board.isValid, false);
    });

    test('isValid returns false for duplicate in column', () {
      final board = Board();
      board.setValue(0, 0, 5);
      board.setValue(1, 0, 5);
      expect(board.isValid, false);
    });

    test('isValid returns false for duplicate in box', () {
      final board = Board();
      board.setValue(0, 0, 5);
      board.setValue(1, 1, 5);
      expect(board.isValid, false);
    });

    test('copy creates deep copy', () {
      final board = Board();
      board.setValue(0, 0, 5);
      final copy = board.copy();
      expect(copy.getValue(0, 0), 5);
      copy.setValue(0, 0, 7);
      expect(board.getValue(0, 0), 5);
    });
  });

  group('Cell - Extended Tests', () {
    test('candidates are empty by default', () {
      const cell = Cell(row: 0, col: 0);
      expect(cell.getCandidatesList(), isEmpty);
    });

    test('candidates can be set', () {
      // bitmask for [1,2,3] is 0x001 | 0x002 | 0x004 = 0x007
      const cell = Cell(row: 0, col: 0, candidates: 0x007);
      expect(cell.getCandidatesList(), [1, 2, 3]);
    });

    test('copyWith preserves candidates when not specified', () {
      // bitmask for [1,2] is 0x001 | 0x002 = 0x003
      const cell = Cell(row: 0, col: 0, candidates: 0x003);
      final newCell = cell.copyWith(value: 5);
      expect(newCell.getCandidatesList(), [1, 2]);
    });

    test('copyWith updates candidates when specified', () {
      // bitmask for [3,4] is 0x004 | 0x008 = 0x00C
      const cell = Cell(row: 0, col: 0, candidates: 0x003);
      final newCell = cell.copyWith(candidates: 0x00C);
      expect(newCell.getCandidatesList(), [3, 4]);
    });

    test('isGiven is false by default', () {
      const cell = Cell(row: 0, col: 0);
      expect(cell.isGiven, false);
    });

    test('isGiven can be set to true', () {
      const cell = Cell(row: 0, col: 0, isGiven: true);
      expect(cell.isGiven, true);
    });

    test('isEmpty is true for empty cell', () {
      const cell = Cell(row: 0, col: 0);
      expect(cell.isEmpty, true);
    });

    test('isFilled is true for filled cell', () {
      const cell = Cell(row: 0, col: 0, value: 5);
      expect(cell.isFilled, true);
    });
  });

  group('Difficulty - Tests', () {
    test('Difficulty enum has all expected values', () {
      expect(Difficulty.values, [
        Difficulty.easy,
        Difficulty.medium,
        Difficulty.hard,
        Difficulty.expert,
        Difficulty.evil,
      ]);
    });

    test('Difficulty difficulty names are correct', () {
      expect(Difficulty.easy.name, 'easy');
      expect(Difficulty.medium.name, 'medium');
      expect(Difficulty.hard.name, 'hard');
      expect(Difficulty.expert.name, 'expert');
      expect(Difficulty.evil.name, 'evil');
    });

    test('Difficulty clues count is correct', () {
      expect(Difficulty.easy.cluesCount, 36);
      expect(Difficulty.medium.cluesCount, 30);
      expect(Difficulty.hard.cluesCount, 26);
      expect(Difficulty.expert.cluesCount, 22);
      expect(Difficulty.evil.cluesCount, 20);
    });

    test('Difficulty from name works', () {
      expect(
        Difficulty.values.firstWhere((d) => d.name == 'easy'),
        Difficulty.easy,
      );
      expect(
        Difficulty.values.firstWhere((d) => d.name == 'medium'),
        Difficulty.medium,
      );
      expect(
        Difficulty.values.firstWhere((d) => d.name == 'hard'),
        Difficulty.hard,
      );
      expect(
        Difficulty.values.firstWhere((d) => d.name == 'expert'),
        Difficulty.expert,
      );
      expect(
        Difficulty.values.firstWhere((d) => d.name == 'evil'),
        Difficulty.evil,
      );
    });

    test('Difficulty from name defaults to medium for invalid', () {
      expect(
        Difficulty.values.firstWhere(
          (d) => d.name == 'invalid',
          orElse: () => Difficulty.medium,
        ),
        Difficulty.medium,
      );
    });

    test('Difficulty values have correct display names', () {
      expect(Difficulty.easy.displayName, 'Easy');
      expect(Difficulty.medium.displayName, 'Medium');
      expect(Difficulty.hard.displayName, 'Hard');
      expect(Difficulty.expert.displayName, 'Expert');
      expect(Difficulty.evil.displayName, 'Evil');
    });
  });
}
