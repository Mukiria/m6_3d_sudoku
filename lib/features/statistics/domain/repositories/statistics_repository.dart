import 'package:dartz/dartz.dart';
import 'package:m6_sudoku/core/errors/failures.dart';
import 'package:m6_sudoku/features/statistics/domain/entities/statistics.dart';

abstract class StatisticsRepository {
  Future<Either<Failure, Statistics>> getStatistics();
  Future<Either<Failure, void>> updateStatistics(Statistics statistics);
  Future<Either<Failure, void>> addGameRecord(GameRecord record);
  Future<Either<Failure, void>> resetStatistics();
}
