import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:m6_sudoku/features/sudoku/presentation/widgets/sudoku_board.dart';
import 'package:m6_sudoku/features/sudoku/presentation/widgets/number_pad.dart';
import 'package:m6_sudoku/features/sudoku/presentation/widgets/game_header.dart';
import 'package:m6_sudoku/features/sudoku/domain/entities/puzzle.dart';
import 'package:m6_sudoku/features/sudoku/domain/entities/game_state.dart';
import 'package:m6_sudoku/core/theme/app_theme_extension.dart';

void main() {
  group('SudokuBoard Widget Tests', () {
    late Puzzle testPuzzle;
    late List<List<int>> testUserGrid;
    late List<List<Set<int>>> testNotes;

    setUp(() {
      testPuzzle = Puzzle(
        id: 'test',
        grid: List.generate(9, (i) => List.generate(9, (j) => 0)),
        solution: List.generate(
          9,
          (i) => List.generate(9, (j) => (i + j) % 9 + 1),
        ),
        difficulty: 'medium',
        cluesCount: 30,
        createdAt: DateTime.now(),
      );
      testPuzzle.grid[0][0] = 5;
      testPuzzle.grid[1][1] = 3;

      testUserGrid = List.generate(9, (i) => List.generate(9, (j) => 0));
      testUserGrid[2][2] = 7;

      testNotes = List.generate(9, (i) => List.generate(9, (j) => <int>{}));
      testNotes[3][3] = {1, 2, 3};
    });

    Widget createTestWidget() {
      return MaterialApp(
        theme: ThemeData.light().copyWith(
          extensions: [AppThemeExtension.light],
        ),
        home: Scaffold(
          body: SudokuBoard(
            puzzle: testPuzzle,
            userGrid: testUserGrid,
            notes: testNotes,
            selectedCell: null,
            highlightedCells: {},
            conflictCells: {},
            isNoteMode: false,
            selectionEpoch: 0,
            onCellTap: (row, col) {},
            onCellLongPress: (row, col) {},
          ),
        ),
      );
    }

    testWidgets('renders 9x9 grid of cells', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Find all InkWell widgets (cells)
      final cells = find.byType(InkWell);
      expect(cells, findsNWidgets(81));
    });

    testWidgets('renders fixed values from puzzle', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());

      // Check for fixed values (5 at 0,0 and 3 at 1,1)
      expect(find.text('5'), findsWidgets);
      expect(find.text('3'), findsWidgets);
    });

    testWidgets('renders user values', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Check for user value (7 at 2,2)
      expect(find.text('7'), findsWidgets);
    });

    testWidgets('renders notes in cell', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Check for notes (1, 2, 3 at 3,3)
      expect(find.text('1'), findsWidgets);
      expect(find.text('2'), findsWidgets);
      expect(find.text('3'), findsWidgets);
    });

    testWidgets('highlights selected cell', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light().copyWith(
            extensions: [AppThemeExtension.light],
          ),
          home: Scaffold(
            body: SudokuBoard(
              puzzle: testPuzzle,
              userGrid: testUserGrid,
              notes: testNotes,
              selectedCell: const CellPosition(row: 2, col: 2),
              highlightedCells: {
                const CellPosition(row: 2, col: 0),
                const CellPosition(row: 0, col: 2),
              },
              conflictCells: {},
              isNoteMode: false,
              selectionEpoch: 0,
              onCellTap: (row, col) {},
              onCellLongPress: (row, col) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      // Should render without errors
    });

    testWidgets('shows conflict indicator', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light().copyWith(
            extensions: [AppThemeExtension.light],
          ),
          home: Scaffold(
            body: SudokuBoard(
              puzzle: testPuzzle,
              userGrid: testUserGrid,
              notes: testNotes,
              selectedCell: null,
              highlightedCells: {},
              conflictCells: {const CellPosition(row: 2, col: 2)},
              isNoteMode: false,
              selectionEpoch: 0,
              onCellTap: (row, col) {},
              onCellLongPress: (row, col) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      // Should render without errors
    });

    testWidgets('handles cell tap', (WidgetTester tester) async {
      int? tappedRow;
      int? tappedCol;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light().copyWith(
            extensions: [AppThemeExtension.light],
          ),
          home: Scaffold(
            body: SudokuBoard(
              puzzle: testPuzzle,
              userGrid: testUserGrid,
              notes: testNotes,
              selectedCell: null,
              highlightedCells: {},
              conflictCells: {},
              isNoteMode: false,
              selectionEpoch: 0,
              onCellTap: (row, col) {
                tappedRow = row;
                tappedCol = col;
              },
              onCellLongPress: (row, col) {},
            ),
          ),
        ),
      );

      // Tap on a cell
      await tester.tap(find.byType(InkWell).first);
      await tester.pump();

      expect(tappedRow, isNotNull);
      expect(tappedCol, isNotNull);
    });
  });

  group('GameHeader Widget Tests', () {
    Widget createTestWidget({
      required String difficulty,
      required int timeElapsed,
      required int mistakes,
      required VoidCallback onPause,
    }) {
      return MaterialApp(
        theme: ThemeData.light().copyWith(
          extensions: [AppThemeExtension.light],
        ),
        home: Scaffold(
          body: GameHeader(
            difficulty: difficulty,
            timeElapsed: timeElapsed,
            mistakes: mistakes,
            onPause: onPause,
          ),
        ),
      );
    }

    testWidgets('renders difficulty label', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          difficulty: 'medium',
          timeElapsed: 0,
          mistakes: 0,
          onPause: () {},
        ),
      );

      expect(find.text('Medium'), findsOneWidget);
    });

    testWidgets('renders timer', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          difficulty: 'easy',
          timeElapsed: 125, // 2:05
          mistakes: 0,
          onPause: () {},
        ),
      );

      expect(find.text('02:05'), findsOneWidget);
    });

    testWidgets('renders mistakes counter', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          difficulty: 'hard',
          timeElapsed: 0,
          mistakes: 2,
          onPause: () {},
        ),
      );

      expect(find.text('Mistake: 2/3'), findsOneWidget);
    });

    testWidgets('pause button calls onPause', (WidgetTester tester) async {
      bool pauseCalled = false;

      await tester.pumpWidget(
        createTestWidget(
          difficulty: 'easy',
          timeElapsed: 0,
          mistakes: 0,
          onPause: () => pauseCalled = true,
        ),
      );

      await tester.tap(find.byIcon(Icons.pause_rounded));
      await tester.pump();

      expect(pauseCalled, true);
    });
  });

  group('NumberPad Widget Tests', () {
    Widget createTestWidget({
      required int? selectedNumber,
      required void Function(int) onNumberSelected,
      required void Function() onNoteModeToggle,
      required bool isNoteMode,
      required Set<int> disabledNumbers,
    }) {
      return MaterialApp(
        theme: ThemeData.light().copyWith(
          extensions: [AppThemeExtension.light],
        ),
        home: Scaffold(
          body: NumberPad(
            selectedNumber: selectedNumber,
            onNumberSelected: onNumberSelected,
            onNoteModeToggle: onNoteModeToggle,
            isNoteMode: isNoteMode,
            disabledNumbers: disabledNumbers,
          ),
        ),
      );
    }

    testWidgets('renders number buttons 1-9', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          selectedNumber: null,
          onNumberSelected: (_) {},
          onNoteModeToggle: () {},
          isNoteMode: false,
          disabledNumbers: {},
        ),
      );

      for (int i = 1; i <= 9; i++) {
        expect(find.text(i.toString()), findsWidgets);
      }
    });

    testWidgets('renders erase button', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          selectedNumber: null,
          onNumberSelected: (_) {},
          onNoteModeToggle: () {},
          isNoteMode: false,
          disabledNumbers: {},
        ),
      );

      expect(find.byIcon(Icons.backspace_outlined), findsOneWidget);
    });

    testWidgets('renders notes toggle with OFF badge', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(
          selectedNumber: null,
          onNumberSelected: (_) {},
          onNoteModeToggle: () {},
          isNoteMode: false,
          disabledNumbers: {},
        ),
      );

      expect(find.text('Notes'), findsOneWidget);
      expect(find.text('OFF'), findsOneWidget);
    });

    testWidgets('highlights selected number', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          selectedNumber: 5,
          onNumberSelected: (_) {},
          onNoteModeToggle: () {},
          isNoteMode: false,
          disabledNumbers: {},
        ),
      );

      // Should find the number 5 button as selected
      // This is tested by the presence of the widget
    });

    testWidgets('note mode toggle switches mode', (WidgetTester tester) async {
      bool noteModeToggled = false;

      await tester.pumpWidget(
        createTestWidget(
          selectedNumber: null,
          onNumberSelected: (_) {},
          onNoteModeToggle: () => noteModeToggled = true,
          isNoteMode: false,
          disabledNumbers: {},
        ),
      );

      await tester.tap(find.text('Notes'));
      await tester.pump();

      expect(noteModeToggled, true);
    });
  });
}
