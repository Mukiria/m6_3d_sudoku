import 'package:dartz/dartz.dart';
import 'package:m6_sudoku/core/errors/failures.dart';
import 'package:m6_sudoku/features/sudoku/domain/entities/daily_challenge.dart';
import 'package:m6_sudoku/features/sudoku/domain/repositories/daily_challenge_repository.dart';

class GetOrGenerateDailyChallengeUseCase {
  GetOrGenerateDailyChallengeUseCase(this._repository);

  final DailyChallengeRepository _repository;

  Future<Either<Failure, DailyChallenge>> call() {
    return _repository.getOrGenerateDailyChallenge();
  }
}

class CompleteDailyChallengeUseCase {
  CompleteDailyChallengeUseCase(this._repository);

  final DailyChallengeRepository _repository;

  Future<Either<Failure, void>> call({
    required String date,
    required int timeElapsed,
    required int mistakes,
    required int hintsUsed,
  }) {
    return _repository.completeDailyChallenge(
      date: date,
      timeElapsed: timeElapsed,
      mistakes: mistakes,
      hintsUsed: hintsUsed,
    );
  }
}

class GetDailyChallengeStatsUseCase {
  GetDailyChallengeStatsUseCase(this._repository);

  final DailyChallengeRepository _repository;

  Future<Either<Failure, DailyChallengeStats>> call() {
    return _repository.getStats();
  }
}

class IsDailyChallengeCompletedUseCase {
  IsDailyChallengeCompletedUseCase(this._repository);

  final DailyChallengeRepository _repository;

  Future<Either<Failure, bool>> call(String date) {
    return _repository.isDailyChallengeCompleted(date);
  }
}
