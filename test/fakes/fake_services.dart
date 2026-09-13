import 'package:dartz/dartz.dart';
import 'package:m6_sudoku/core/audio/audio_service.dart';
import 'package:m6_sudoku/core/errors/failures.dart';
import 'package:m6_sudoku/core/services/storage_service.dart';
import 'package:m6_sudoku/features/settings/domain/entities/settings.dart';
import 'package:m6_sudoku/features/settings/domain/repositories/settings_repository.dart';

/// Fake implementation of [StorageService] for testing.
/// Uses an in-memory map instead of SharedPreferences.
class FakeStorageService implements StorageService {
  final Map<String, dynamic> _storage = {};

  @override
  Future<bool> setString(String key, String value) async {
    _storage[key] = value;
    return true;
  }

  @override
  Future<bool> setBool(String key, bool value) async {
    _storage[key] = value;
    return true;
  }

  @override
  Future<bool> setInt(String key, int value) async {
    _storage[key] = value;
    return true;
  }

  @override
  Future<bool> setDouble(String key, double value) async {
    _storage[key] = value;
    return true;
  }

  @override
  Future<bool> setStringList(String key, List<String> value) async {
    _storage[key] = value;
    return true;
  }

  @override
  String? getString(String key) => _storage[key] as String?;

  @override
  bool? getBool(String key) => _storage[key] as bool?;

  @override
  int? getInt(String key) => _storage[key] as int?;

  @override
  double? getDouble(String key) => _storage[key] as double?;

  @override
  List<String>? getStringList(String key) =>
      (_storage[key] as List?)?.cast<String>();

  @override
  Future<bool> remove(String key) async {
    _storage.remove(key);
    return true;
  }

  @override
  Future<bool> clear() async {
    _storage.clear();
    return true;
  }

  @override
  bool containsKey(String key) => _storage.containsKey(key);

  @override
  Set<String> getKeys() => _storage.keys.toSet();
}

/// Fake implementation of [SettingsRepository] for testing.
class FakeSettingsRepository implements SettingsRepository {
  Settings? _settings;

  @override
  Future<Either<Failure, Settings>> getSettings() async {
    return Right(_settings ?? const Settings());
  }

  @override
  Future<Either<Failure, void>> saveSettings(Settings settings) async {
    _settings = settings;
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> resetSettings() async {
    _settings = const Settings();
    return const Right(null);
  }
}

/// Fake implementation of [AudioService] for testing.
/// Does not play any actual sounds.
class FakeAudioService implements AudioService {
  @override
  Future<void> initialize() async {}

  @override
  void playClick() {}

  @override
  void playWin() {}

  @override
  void playError() {}

  @override
  void playHint() {}

  @override
  void playPause() {}

  @override
  void playResume() {}

  @override
  void setMuted(bool muted) {}

  @override
  void setVolume(double volume) {}

  @override
  bool get isMuted => false;

  @override
  double get volume => 1.0;
}
