import 'package:dartz/dartz.dart';
import 'package:m6_sudoku/core/errors/failures.dart';
import 'package:m6_sudoku/features/sudoku/domain/entities/daily_challenge.dart';

abstract class DailyChallengeRepository {
  Future<Either<Failure, DailyChallenge>> getOrGenerateDailyChallenge();
  Future<Either<Failure, void>> completeDailyChallenge({
    required String date,
    required int timeElapsed,
    required int mistakes,
    required int hintsUsed,
  });
  Future<Either<Failure, DailyChallengeStats>> getStats();
  Future<Either<Failure, bool>> isDailyChallengeCompleted(String date);
}
