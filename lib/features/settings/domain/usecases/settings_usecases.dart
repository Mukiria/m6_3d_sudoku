import 'package:dartz/dartz.dart';
import 'package:m6_sudoku/core/errors/failures.dart';
import 'package:m6_sudoku/features/settings/domain/entities/settings.dart';
import 'package:m6_sudoku/features/settings/domain/repositories/settings_repository.dart';

class GetSettingsUseCase {
  GetSettingsUseCase(this._repository);

  final SettingsRepository _repository;

  Future<Either<Failure, Settings>> call() {
    return _repository.getSettings();
  }
}

class SaveSettingsUseCase {
  SaveSettingsUseCase(this._repository);

  final SettingsRepository _repository;

  Future<Either<Failure, void>> call(Settings settings) {
    return _repository.saveSettings(settings);
  }
}

class ResetSettingsUseCase {
  ResetSettingsUseCase(this._repository);

  final SettingsRepository _repository;

  Future<Either<Failure, void>> call() {
    return _repository.resetSettings();
  }
}
