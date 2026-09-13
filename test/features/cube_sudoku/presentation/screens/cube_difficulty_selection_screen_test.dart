import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:m6_sudoku/core/theme/app_theme_extension.dart';
import 'package:m6_sudoku/features/cube_sudoku/presentation/screens/cube_difficulty_selection_screen.dart';
import 'package:m6_sudoku/features/sudoku/engine/models/difficulty.dart';
import 'package:m6_sudoku/features/sudoku/presentation/providers/sudoku_providers.dart';

import '../../../../fakes/fake_services.dart';

Widget _wrap(Widget child) {
  return ProviderScope(
    overrides: [storageServiceProvider.overrideWithValue(FakeStorageService())],
    child: MaterialApp(
      theme: ThemeData.light().copyWith(extensions: [AppThemeExtension.light]),
      home: child,
    ),
  );
}

void main() {
  // The screen's ListView of six face tiles is lazy — the default test
  // surface (800x600) is tall enough for the AppBar/instructions card/
  // button but not for all six ~56px tiles at once, so only the first few
  // ever get built. Widening the surface avoids needing to scroll (and
  // avoids scrolling's own flakiness) to see every tile.
  Future<void> useTallSurface(WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets(
    'renders a difficulty dropdown for each of the six faces, all defaulting to the same difficulty',
    (tester) async {
      await useTallSurface(tester);
      await tester.pumpWidget(_wrap(const CubeDifficultySelectionScreen()));
      await tester.pump();

      expect(find.text('Top face'), findsOneWidget);
      expect(find.text('Bottom face'), findsOneWidget);
      expect(find.text('Front face'), findsOneWidget);
      expect(find.text('Back face'), findsOneWidget);
      expect(find.text('Left face'), findsOneWidget);
      expect(find.text('Right face'), findsOneWidget);

      // A fresh SettingsController starts at its synchronous Settings()
      // default (selectedDifficulty: 'easy') before its async load resolves
      // — every face's dropdown should seed from that same default.
      expect(find.text('Easy'), findsNWidgets(6));
    },
  );

  testWidgets(
    'changing one face\'s difficulty only updates that face\'s tile',
    (tester) async {
      await useTallSurface(tester);
      await tester.pumpWidget(_wrap(const CubeDifficultySelectionScreen()));
      await tester.pump();

      // CubeFace.values order is Top, Bottom, Front, Back, Left, Right — the
      // list renders in that order, so the first dropdown is the Top face's.
      final dropdowns = find.byType(DropdownButton<Difficulty>);
      expect(dropdowns, findsNWidgets(6));
      await tester.tap(dropdowns.first);
      await tester.pumpAndSettle();

      // The dropdown menu lists every difficulty; tap the "Expert" entry.
      await tester.tap(find.text('Expert').last);
      await tester.pumpAndSettle();

      expect(find.text('Expert'), findsOneWidget);
      // The other five faces stayed at Easy.
      expect(find.text('Easy'), findsNWidgets(5));
    },
  );

  testWidgets('Start 3D Sudoku button is present and enabled', (tester) async {
    await useTallSurface(tester);
    await tester.pumpWidget(_wrap(const CubeDifficultySelectionScreen()));
    await tester.pump();

    final button = find.widgetWithText(FilledButton, 'Start 3D Sudoku');
    expect(button, findsOneWidget);
    expect(tester.widget<FilledButton>(button).onPressed, isNotNull);
  });
}
