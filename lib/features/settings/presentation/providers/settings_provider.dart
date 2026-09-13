import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:m6_sudoku/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:m6_sudoku/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:m6_sudoku/features/settings/domain/entities/settings.dart';
import 'package:m6_sudoku/features/settings/domain/repositories/settings_repository.dart';
import 'package:m6_sudoku/features/settings/domain/usecases/settings_usecases.dart';
import 'package:m6_sudoku/features/sudoku/presentation/providers/sudoku_providers.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final storageService = ref.read(storageServiceProvider);
  return SettingsRepositoryImpl(SettingsLocalDataSource(storageService));
});

final getSettingsUseCaseProvider = Provider<GetSettingsUseCase>((ref) {
  final repo = ref.read(settingsRepositoryProvider);
  return GetSettingsUseCase(repo);
});

final saveSettingsUseCaseProvider = Provider<SaveSettingsUseCase>((ref) {
  final repo = ref.read(settingsRepositoryProvider);
  return SaveSettingsUseCase(repo);
});

final resetSettingsUseCaseProvider = Provider<ResetSettingsUseCase>((ref) {
  final repo = ref.read(settingsRepositoryProvider);
  return ResetSettingsUseCase(repo);
});

final settingsProvider = StateNotifierProvider<SettingsController, Settings>((
  ref,
) {
  return SettingsController(ref);
});

final themeModeProvider = StateProvider<ThemeMode>((ref) {
  final settings = ref.watch(settingsProvider);
  return settings.themeMode;
});

class SettingsController extends StateNotifier<Settings> {
  SettingsController(this._ref) : super(const Settings()) {
    _loadSettings();
  }

  final Ref _ref;

  Future<void> _loadSettings() async {
    final getSettings = _ref.read(getSettingsUseCaseProvider);
    final result = await getSettings();
    result.fold(
      (failure) => debugPrint('Failed to load settings: $failure'),
      (settings) => state = settings,
    );
  }

  Future<void> updateThemeMode(ThemeMode themeMode) async {
    final newSettings = state.copyWith(themeMode: themeMode);
    await _saveSettings(newSettings);
  }

  Future<void> updateDifficulty(String difficulty) async {
    final newSettings = state.copyWith(selectedDifficulty: difficulty);
    await _saveSettings(newSettings);
  }

  Future<void> toggleSound(bool enabled) async {
    final newSettings = state.copyWith(soundEnabled: enabled);
    await _saveSettings(newSettings);
  }

  Future<void> toggleHaptics(bool enabled) async {
    final newSettings = state.copyWith(hapticsEnabled: enabled);
    await _saveSettings(newSettings);
  }

  Future<void> toggleAutoNotes(bool enabled) async {
    final newSettings = state.copyWith(autoNotes: enabled);
    await _saveSettings(newSettings);
  }

  Future<void> toggleHighlightErrors(bool enabled) async {
    final newSettings = state.copyWith(highlightErrors: enabled);
    await _saveSettings(newSettings);
  }

  Future<void> toggleShowTimer(bool enabled) async {
    final newSettings = state.copyWith(showTimer: enabled);
    await _saveSettings(newSettings);
  }

  Future<void> toggleShowHints(bool enabled) async {
    final newSettings = state.copyWith(showHints: enabled);
    await _saveSettings(newSettings);
  }

  Future<void> toggleAnimations(bool enabled) async {
    final newSettings = state.copyWith(animationsEnabled: enabled);
    await _saveSettings(newSettings);
  }

  Future<void> toggleAutoClearNotes(bool enabled) async {
    final newSettings = state.copyWith(autoClearNotes: enabled);
    await _saveSettings(newSettings);
  }

  Future<void> toggleHighlightRegions(bool enabled) async {
    final newSettings = state.copyWith(highlightRegions: enabled);
    await _saveSettings(newSettings);
  }

  Future<void> toggleNumberFirstInput(bool enabled) async {
    final newSettings = state.copyWith(numberFirstInput: enabled);
    await _saveSettings(newSettings);
  }

  Future<void> setMaxHints(int value) async {
    final newSettings = state.copyWith(maxHints: value.clamp(0, 10));
    await _saveSettings(newSettings);
  }

  Future<void> _saveSettings(Settings settings) async {
    final saveSettings = _ref.read(saveSettingsUseCaseProvider);
    final result = await saveSettings(settings);
    result.fold(
      (failure) => debugPrint('Failed to save settings: $failure'),
      (_) => state = settings,
    );
  }

  Future<void> resetToDefaults() async {
    final resetSettings = _ref.read(resetSettingsUseCaseProvider);
    final result = await resetSettings();
    result.fold(
      (failure) => debugPrint('Failed to reset settings: $failure'),
      (_) => state = const Settings(),
    );
  }
}
