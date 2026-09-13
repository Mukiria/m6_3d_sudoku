import 'package:dartz/dartz.dart';
import 'package:m6_sudoku/core/errors/failures.dart';
import 'package:m6_sudoku/features/statistics/domain/entities/statistics.dart';
import 'package:m6_sudoku/features/statistics/domain/repositories/statistics_repository.dart';

class GetStatisticsUseCase {
  GetStatisticsUseCase(this._repository);

  final StatisticsRepository _repository;

  Future<Either<Failure, Statistics>> call() {
    return _repository.getStatistics();
  }
}

class UpdateStatisticsUseCase {
  UpdateStatisticsUseCase(this._repository);

  final StatisticsRepository _repository;

  Future<Either<Failure, void>> call(Statistics statistics) {
    return _repository.updateStatistics(statistics);
  }
}

class AddGameRecordUseCase {
  AddGameRecordUseCase(this._repository);

  final StatisticsRepository _repository;

  Future<Either<Failure, void>> call(GameRecord record) {
    return _repository.addGameRecord(record);
  }
}

class ResetStatisticsUseCase {
  ResetStatisticsUseCase(this._repository);

  final StatisticsRepository _repository;

  Future<Either<Failure, void>> call() {
    return _repository.resetStatistics();
  }
}
