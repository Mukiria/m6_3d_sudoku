import 'package:flutter_test/flutter_test.dart';
import 'package:m6_sudoku/features/sudoku/domain/entities/game_state.dart';
import 'package:m6_sudoku/features/sudoku/domain/entities/puzzle.dart';
import 'package:m6_sudoku/features/sudoku/engine/models/difficulty.dart';

final testHint = HintState(
  type: HintType.directReveal,
  cell: const CellPosition(row: 0, col: 0),
  value: 1,
  explanation: 'test hint',
  shownAt: DateTime(2024, 1, 1),
);

void main() {
  group('GameState', () {
    late Puzzle testPuzzle;
    late List<List<int>> testUserGrid;
    late List<List<Set<int>>> testNotes;

    setUp(() {
      testPuzzle = Puzzle(
        id: 'test-puzzle-1',
        grid: List.generate(9, (i) => List.generate(9, (j) => (i + j) % 9 + 1)),
        solution: List.generate(
          9,
          (i) => List.generate(9, (j) => (i + j) % 9 + 1),
        ),
        difficulty: 'medium',
        cluesCount: 30,
        createdAt: DateTime(2024, 1, 1),
      );

      testUserGrid = List.generate(9, (i) => List.filled(9, 0));
      testNotes = List.generate(9, (i) => List.generate(9, (j) => <int>{}));
    });

    test('creates GameState with correct initial values', () {
      final gameState = GameState(
        puzzleId: testPuzzle.id,
        puzzle: testPuzzle,
        userGrid: testUserGrid,
        notes: testNotes,
        timeElapsed: 0,
        mistakes: 0,
        hintsUsed: 0,
        penaltyTime: 0,
        moveHistory: [],
        redoStack: [],
        status: GameStatus.playing,
        lastPlayed: DateTime(2024, 1, 1),
        difficulty: Difficulty.medium,
        selectedCell: null,
        selectedNumber: null,
        isNoteMode: false,
        highlightedCells: {},
        conflictCells: {},
        hintState: testHint,
        lastSaved: DateTime(2024, 1, 1),
      );

      expect(gameState.puzzleId, equals(testPuzzle.id));
      expect(gameState.puzzle, equals(testPuzzle));
      expect(gameState.userGrid, equals(testUserGrid));
      expect(gameState.notes, equals(testNotes));
      expect(gameState.timeElapsed, equals(0));
      expect(gameState.mistakes, equals(0));
      expect(gameState.hintsUsed, equals(0));
      expect(gameState.penaltyTime, equals(0));
      expect(gameState.moveHistory, isEmpty);
      expect(gameState.redoStack, isEmpty);
      expect(gameState.status, equals(GameStatus.playing));
      expect(gameState.difficulty, equals(Difficulty.medium));
      expect(gameState.selectedCell, isNull);
      expect(gameState.selectedNumber, isNull);
      expect(gameState.isNoteMode, isFalse);
      expect(gameState.highlightedCells, isEmpty);
      expect(gameState.conflictCells, isEmpty);
      expect(gameState.saveVersion, equals(1));
    });

    test('copyWith updates only specified fields', () {
      final gameState = GameState(
        puzzleId: 'test-1',
        puzzle: Puzzle(
          id: 'puzzle-1',
          grid: List.generate(9, (i) => List.filled(9, 0)),
          solution: List.generate(9, (i) => List.filled(9, 0)),
          difficulty: 'easy',
          cluesCount: 36,
          createdAt: DateTime.now(),
        ),
        userGrid: List.generate(9, (i) => List.filled(9, 0)),
        notes: List.generate(9, (i) => List.generate(9, (j) => <int>{})),
        timeElapsed: 100,
        mistakes: 1,
        hintsUsed: 2,
        penaltyTime: 30,
        moveHistory: [],
        redoStack: [],
        status: GameStatus.playing,
        lastPlayed: DateTime.now(),
        difficulty: Difficulty.easy,
        selectedCell: const CellPosition(row: 0, col: 0),
        selectedNumber: 5,
        isNoteMode: true,
        highlightedCells: {const CellPosition(row: 0, col: 1)},
        conflictCells: {const CellPosition(row: 1, col: 1)},
        hintState: testHint,
        lastSaved: DateTime.now(),
      );

      final updatedState = gameState.copyWith(
        timeElapsed: 200,
        mistakes: 2,
        status: GameStatus.completed,
      );

      expect(updatedState.timeElapsed, equals(200));
      expect(updatedState.mistakes, equals(2));
      expect(updatedState.status, equals(GameStatus.completed));
      expect(updatedState.mistakes, equals(2));
      expect(updatedState.hintsUsed, equals(gameState.hintsUsed));
      expect(updatedState.penaltyTime, equals(gameState.penaltyTime));
      expect(updatedState.selectedCell, equals(gameState.selectedCell));
      expect(updatedState.isNoteMode, equals(gameState.isNoteMode));
    });

    test('toJson and fromJson roundtrip', () {
      final gameState = GameState(
        puzzleId: 'test-puzzle',
        puzzle: Puzzle(
          id: 'puzzle-1',
          grid: List.generate(9, (i) => List.filled(9, 0)),
          solution: List.generate(9, (i) => List.filled(9, 0)),
          difficulty: 'medium',
          cluesCount: 30,
          createdAt: DateTime(2024, 1, 1),
        ),
        userGrid: List.generate(9, (i) => List.filled(9, 0)),
        notes: List.generate(9, (i) => List.generate(9, (j) => <int>{})),
        timeElapsed: 120,
        mistakes: 1,
        hintsUsed: 1,
        penaltyTime: 15,
        moveHistory: [],
        redoStack: [],
        status: GameStatus.paused,
        lastPlayed: DateTime(2024, 6, 15),
        difficulty: Difficulty.hard,
        selectedCell: const CellPosition(row: 4, col: 4),
        selectedNumber: 7,
        isNoteMode: false,
        highlightedCells: {const CellPosition(row: 0, col: 0)},
        conflictCells: {const CellPosition(row: 1, col: 1)},
        hintState: testHint,
        lastSaved: DateTime(2024, 6, 15),
      );

      final json = gameState.toJson();
      final restored = GameState.fromJson(json);

      expect(restored.puzzleId, equals(gameState.puzzleId));
      expect(restored.timeElapsed, equals(gameState.timeElapsed));
      expect(restored.mistakes, equals(gameState.mistakes));
      expect(restored.hintsUsed, equals(gameState.hintsUsed));
      expect(restored.penaltyTime, equals(gameState.penaltyTime));
      expect(restored.status, equals(gameState.status));
      expect(restored.difficulty, equals(gameState.difficulty));
      expect(restored.selectedCell, equals(gameState.selectedCell));
      expect(restored.selectedNumber, equals(gameState.selectedNumber));
      expect(restored.isNoteMode, equals(gameState.isNoteMode));
      expect(restored.highlightedCells, equals(gameState.highlightedCells));
      expect(restored.conflictCells, equals(gameState.conflictCells));
      expect(restored.lastSaved, equals(gameState.lastSaved));
    });

    test('equality works correctly', () {
      final fixedTime = DateTime(2024, 1, 1, 12, 0, 0);
      final state1 = GameState(
        puzzleId: 'test',
        puzzle: Puzzle(
          id: 'p1',
          grid: List.generate(9, (i) => List.filled(9, 0)),
          solution: List.generate(9, (i) => List.filled(9, 0)),
          difficulty: 'easy',
          cluesCount: 36,
          createdAt: fixedTime,
        ),
        userGrid: List.generate(9, (i) => List.filled(9, 0)),
        notes: List.generate(9, (i) => List.generate(9, (j) => <int>{})),
        timeElapsed: 0,
        mistakes: 0,
        hintsUsed: 0,
        penaltyTime: 0,
        moveHistory: [],
        redoStack: [],
        status: GameStatus.playing,
        lastPlayed: fixedTime,
        difficulty: Difficulty.easy,
        selectedCell: null,
        selectedNumber: null,
        isNoteMode: false,
        highlightedCells: {},
        conflictCells: {},
        hintState: testHint,
        lastSaved: fixedTime,
      );

      final state2 = GameState(
        puzzleId: 'test',
        puzzle: Puzzle(
          id: 'p1',
          grid: List.generate(9, (i) => List.filled(9, 0)),
          solution: List.generate(9, (i) => List.filled(9, 0)),
          difficulty: 'easy',
          cluesCount: 36,
          createdAt: fixedTime,
        ),
        userGrid: List.generate(9, (i) => List.filled(9, 0)),
        notes: List.generate(9, (i) => List.generate(9, (j) => <int>{})),
        timeElapsed: 0,
        mistakes: 0,
        hintsUsed: 0,
        penaltyTime: 0,
        moveHistory: [],
        redoStack: [],
        status: GameStatus.playing,
        lastPlayed: fixedTime,
        difficulty: Difficulty.easy,
        selectedCell: null,
        selectedNumber: null,
        isNoteMode: false,
        highlightedCells: {},
        conflictCells: {},
        hintState: testHint,
        lastSaved: fixedTime,
      );

      expect(state1, equals(state2));
      expect(state1.hashCode, equals(state2.hashCode));
    });
  });

  group('Move', () {
    test('creates Move with all fields', () {
      final move = Move(
        row: 4,
        col: 4,
        previousValue: 0,
        newValue: 5,
        type: MoveType.value,
        timestamp: DateTime(2024, 1, 1),
      );

      expect(move.row, equals(4));
      expect(move.col, equals(4));
      expect(move.previousValue, equals(0));
      expect(move.newValue, equals(5));
      expect(move.type, equals(MoveType.value));
    });

    test('copyWith works correctly', () {
      final move = Move(
        row: 0,
        col: 0,
        previousValue: 0,
        newValue: 5,
        type: MoveType.value,
        timestamp: DateTime.now(),
      );

      final updated = move.copyWith(newValue: 7);
      expect(updated.newValue, equals(7));
      expect(updated.row, equals(0));
      expect(updated.type, equals(MoveType.value));
    });
  });

  group('CellPosition', () {
    test('creates CellPosition correctly', () {
      const pos = CellPosition(row: 3, col: 5);
      expect(pos.row, equals(3));
      expect(pos.col, equals(5));
    });

    test('equality works correctly', () {
      const pos1 = CellPosition(row: 2, col: 3);
      const pos2 = CellPosition(row: 2, col: 3);
      const pos3 = CellPosition(row: 3, col: 2);

      expect(pos1, equals(pos2));
      expect(pos1.hashCode, equals(pos2.hashCode));
      expect(pos1, isNot(equals(pos3)));
    });

    test('toJson and fromJson roundtrip', () {
      const pos = CellPosition(row: 4, col: 7);
      final json = pos.toJson();
      final restored = CellPosition.fromJson(json);
      expect(restored, equals(pos));
    });
  });

  group('MoveType', () {
    test('all values exist', () {
      expect(
        MoveType.values,
        containsAll([
          MoveType.value,
          MoveType.note,
          MoveType.hint,
          MoveType.undo,
          MoveType.clear,
          MoveType.redo,
        ]),
      );
    });
  });

  group('GameStatus', () {
    test('all values exist', () {
      expect(
        GameStatus.values,
        containsAll([
          GameStatus.playing,
          GameStatus.paused,
          GameStatus.completed,
          GameStatus.failed,
        ]),
      );
    });
  });
}
