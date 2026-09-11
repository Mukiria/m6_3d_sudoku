import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:m6_sudoku/core/services/json_store.dart';
import 'package:m6_sudoku/core/services/storage_service.dart';
import 'package:m6_sudoku/core/errors/failures.dart';
import '../../domain/entities/settings.dart';

class SettingsLocalDataSource {
  SettingsLocalDataSource(StorageService storage) : _json = JsonStore(storage);

  final JsonStore _json;

  static const String _settingsKey = 'game_settings';

  Future<Either<Failure, Settings>> getSettings() async {
    return _json.readJson(
      _settingsKey,
      (decoded) => Settings.fromJson(decoded as Map<String, dynamic>),
      _defaultSettings,
      'get settings',
    );
  }

  Future<Either<Failure, void>> saveSettings(Settings settings) {
    return _json.writeJson(_settingsKey, settings.toJson(), 'save settings');
  }

  Future<Either<Failure, void>> resetSettings() {
    return _json.removeKeys([_settingsKey], 'reset settings');
  }

  Settings _defaultSettings() {
    return Settings(
      themeMode: ThemeMode.light,
      soundEnabled: true,
      hapticsEnabled: true,
      autoNotes: true,
      highlightErrors: true,
      showTimer: true,
      showHints: true,
      autoClearNotes: true,
      highlightRegions: true,
      numberFirstInput: false,
    );
  }
}
