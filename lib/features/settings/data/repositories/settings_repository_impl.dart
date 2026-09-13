import 'package:dartz/dartz.dart';
import 'package:m6_sudoku/core/errors/failures.dart';
import 'package:m6_sudoku/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:m6_sudoku/features/settings/domain/entities/settings.dart';
import 'package:m6_sudoku/features/settings/domain/repositories/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl(this._dataSource);

  final SettingsLocalDataSource _dataSource;

  @override
  Future<Either<Failure, Settings>> getSettings() {
    return _dataSource.getSettings();
  }

  @override
  Future<Either<Failure, void>> saveSettings(Settings settings) {
    return _dataSource.saveSettings(settings);
  }

  @override
  Future<Either<Failure, void>> resetSettings() {
    return _dataSource.resetSettings();
  }
}
