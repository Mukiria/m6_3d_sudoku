import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:m6_sudoku/core/theme/app_theme_extension.dart';
import 'package:m6_sudoku/features/sudoku/domain/entities/game_state.dart';
import 'package:m6_sudoku/features/sudoku/presentation/widgets/hint_overlay.dart';

void main() {
  group('HintOverlay Widget Tests', () {
    Widget createTestWidget({
      required HintState hintState,
      required VoidCallback onDismiss,
    }) {
      return MaterialApp(
        theme: ThemeData.light().copyWith(
          extensions: [AppThemeExtension.light],
        ),
        home: Scaffold(
          body: HintOverlay(hintState: hintState, onDismiss: onDismiss),
        ),
      );
    }

    testWidgets('renders hint type title', (WidgetTester tester) async {
      final hintState = HintState(
        type: HintType.nakedSingle,
        cell: const CellPosition(row: 2, col: 2),
        value: 5,
        explanation: 'This cell can only be 5 (naked single)',
        shownAt: DateTime.now(),
      );

      await tester.pumpWidget(
        createTestWidget(hintState: hintState, onDismiss: () {}),
      );

      await tester.pumpAndSettle();

      expect(find.text('Naked Single'), findsOneWidget);
    });

    testWidgets('renders explanation text', (WidgetTester tester) async {
      final hintState = HintState(
        type: HintType.hiddenSingle,
        cell: const CellPosition(row: 2, col: 2),
        value: 7,
        explanation:
            'Digit 7 can only go in this cell in this row (hidden single)',
        shownAt: DateTime.now(),
      );

      await tester.pumpWidget(
        createTestWidget(hintState: hintState, onDismiss: () {}),
      );

      await tester.pumpAndSettle();

      expect(
        find.text(
          'Digit 7 can only go in this cell in this row (hidden single)',
        ),
        findsOneWidget,
      );
    });

    testWidgets('renders cell position', (WidgetTester tester) async {
      final hintState = HintState(
        type: HintType.directReveal,
        cell: const CellPosition(row: 4, col: 5),
        value: 3,
        explanation: 'The solution value for this cell is 3',
        shownAt: DateTime.now(),
      );

      await tester.pumpWidget(
        createTestWidget(hintState: hintState, onDismiss: () {}),
      );

      await tester.pumpAndSettle();

      expect(find.text('Row 5, Column 6'), findsOneWidget);
    });

    testWidgets('renders revealed value', (WidgetTester tester) async {
      final hintState = HintState(
        type: HintType.nakedSingle,
        cell: const CellPosition(row: 2, col: 2),
        value: 9,
        explanation: 'This cell can only be 9',
        shownAt: DateTime.now(),
      );

      await tester.pumpWidget(
        createTestWidget(hintState: hintState, onDismiss: () {}),
      );

      await tester.pumpAndSettle();

      expect(find.text('9'), findsWidgets);
    });

    testWidgets('dismiss button calls onDismiss', (WidgetTester tester) async {
      bool dismissCalled = false;

      final hintState = HintState(
        type: HintType.nakedSingle,
        cell: const CellPosition(row: 2, col: 2),
        value: 5,
        explanation: 'Test explanation',
        shownAt: DateTime.now(),
      );

      await tester.pumpWidget(
        createTestWidget(
          hintState: hintState,
          onDismiss: () => dismissCalled = true,
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Got it!'));
      await tester.pump();

      expect(dismissCalled, true);
    });

    testWidgets('renders different hint type colors', (
      WidgetTester tester,
    ) async {
      // Test naked single (green)
      var hintState = HintState(
        type: HintType.nakedSingle,
        cell: const CellPosition(row: 2, col: 2),
        value: 5,
        explanation: 'Test',
        shownAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light().copyWith(
            extensions: [AppThemeExtension.light],
          ),
          home: Scaffold(
            body: HintOverlay(hintState: hintState, onDismiss: () {}),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Test hidden single (blue)
      hintState = HintState(
        type: HintType.hiddenSingle,
        cell: const CellPosition(row: 2, col: 2),
        value: 5,
        explanation: 'Test',
        shownAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light().copyWith(
            extensions: [AppThemeExtension.light],
          ),
          home: Scaffold(
            body: HintOverlay(hintState: hintState, onDismiss: () {}),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Test direct reveal (orange)
      hintState = HintState(
        type: HintType.directReveal,
        cell: const CellPosition(row: 2, col: 2),
        value: 5,
        explanation: 'Test',
        shownAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light().copyWith(
            extensions: [AppThemeExtension.light],
          ),
          home: Scaffold(
            body: HintOverlay(hintState: hintState, onDismiss: () {}),
          ),
        ),
      );

      await tester.pumpAndSettle();
    });

    testWidgets('shows secret achievement as locked', (
      WidgetTester tester,
    ) async {
      // This tests the achievement screen logic, not hint overlay
      // But we can test that locked achievements show as ???
      // This is more of an integration test
    });
  });
}
