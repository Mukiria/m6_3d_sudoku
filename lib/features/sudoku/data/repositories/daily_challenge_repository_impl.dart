import 'package:dartz/dartz.dart';
import 'package:m6_sudoku/core/errors/failures.dart';
import 'package:m6_sudoku/features/sudoku/data/datasources/daily_challenge_local_datasource.dart';
import 'package:m6_sudoku/features/sudoku/domain/entities/daily_challenge.dart';
import 'package:m6_sudoku/features/sudoku/domain/repositories/daily_challenge_repository.dart';

class DailyChallengeRepositoryImpl implements DailyChallengeRepository {
  DailyChallengeRepositoryImpl(this._dataSource);

  final DailyChallengeLocalDataSource _dataSource;

  @override
  Future<Either<Failure, DailyChallenge>> getOrGenerateDailyChallenge() {
    return _dataSource.getOrGenerateDailyChallenge();
  }

  @override
  Future<Either<Failure, void>> completeDailyChallenge({
    required String date,
    required int timeElapsed,
    required int mistakes,
    required int hintsUsed,
  }) {
    return _dataSource.completeDailyChallenge(
      date: date,
      timeElapsed: timeElapsed,
      mistakes: mistakes,
      hintsUsed: hintsUsed,
    );
  }

  @override
  Future<Either<Failure, DailyChallengeStats>> getStats() {
    return _dataSource.getStats();
  }

  @override
  Future<Either<Failure, bool>> isDailyChallengeCompleted(String date) async {
    try {
      final result = await _dataSource.isDailyChallengeCompleted(date);
      return Right(result);
    } catch (e) {
      return Left(
        CacheFailure('Failed to check daily challenge completion: $e'),
      );
    }
  }
}
