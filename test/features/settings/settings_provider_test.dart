import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:m6_sudoku/core/services/storage_service.dart';
import 'package:m6_sudoku/features/settings/presentation/providers/settings_provider.dart';
import 'package:m6_sudoku/features/sudoku/presentation/providers/sudoku_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('SettingsController', () {
    late ProviderContainer container;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      container = ProviderContainer(
        overrides: [
          storageServiceProvider.overrideWithValue(StorageServiceImpl(prefs)),
        ],
      );
      addTearDown(container.dispose);
    });

    test('settingsRepositoryProvider resolves without throwing', () {
      // Regression: this used to be a placeholder that always threw
      // UnimplementedError, silently breaking every settings mutation.
      expect(() => container.read(settingsRepositoryProvider), returnsNormally);
    });

    test('updateThemeMode persists and updates state', () async {
      // Let the initial async _loadSettings() finish.
      await Future<void>.delayed(Duration.zero);

      final notifier = container.read(settingsProvider.notifier);
      expect(container.read(settingsProvider).themeMode, ThemeMode.light);

      await notifier.updateThemeMode(ThemeMode.dark);

      expect(container.read(settingsProvider).themeMode, ThemeMode.dark);
    });

    test('theme choice survives a reload from storage', () async {
      await Future<void>.delayed(Duration.zero);
      await container
          .read(settingsProvider.notifier)
          .updateThemeMode(ThemeMode.light);

      final prefs = await SharedPreferences.getInstance();
      final reloadedContainer = ProviderContainer(
        overrides: [
          storageServiceProvider.overrideWithValue(StorageServiceImpl(prefs)),
        ],
      );
      addTearDown(reloadedContainer.dispose);

      // Reading the provider is what constructs SettingsController and
      // kicks off its async _loadSettings() call — trigger that first,
      // then let it complete before asserting on the loaded value.
      reloadedContainer.read(settingsProvider);
      await Future<void>.delayed(Duration.zero);
      expect(
        reloadedContainer.read(settingsProvider).themeMode,
        ThemeMode.light,
      );
    });

    test(
      'toggleAnimations updates animationsEnabled, not soundEffectsEnabled',
      () async {
        await Future<void>.delayed(Duration.zero);
        final notifier = container.read(settingsProvider.notifier);
        final before = container.read(settingsProvider);

        await notifier.toggleAnimations(false);

        final after = container.read(settingsProvider);
        expect(after.animationsEnabled, false);
        expect(after.soundEffectsEnabled, before.soundEffectsEnabled);
      },
    );
  });
}
