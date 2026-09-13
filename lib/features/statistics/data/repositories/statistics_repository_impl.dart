import 'package:dartz/dartz.dart';
import 'package:m6_sudoku/core/errors/failures.dart';
import 'package:m6_sudoku/features/statistics/data/datasources/statistics_local_datasource.dart';
import 'package:m6_sudoku/features/statistics/domain/entities/statistics.dart';
import 'package:m6_sudoku/features/statistics/domain/repositories/statistics_repository.dart';

class StatisticsRepositoryImpl implements StatisticsRepository {
  StatisticsRepositoryImpl(this._dataSource);

  final StatisticsLocalDataSource _dataSource;

  @override
  Future<Either<Failure, Statistics>> getStatistics() {
    return _dataSource.getStatistics();
  }

  @override
  Future<Either<Failure, void>> updateStatistics(Statistics statistics) {
    return _dataSource.updateStatistics(statistics);
  }

  @override
  Future<Either<Failure, void>> addGameRecord(GameRecord record) {
    return _dataSource.addGameRecord(record);
  }

  @override
  Future<Either<Failure, void>> resetStatistics() {
    return _dataSource.resetStatistics();
  }

  @override
  Future<Either<Failure, List<GameRecord>>> getRecentGames({int limit = 10}) {
    return _dataSource.getRecentGames(limit: limit);
  }
}
