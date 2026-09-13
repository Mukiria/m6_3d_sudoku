import 'package:dartz/dartz.dart';
import 'package:m6_sudoku/core/errors/failures.dart';
import 'package:m6_sudoku/features/sudoku/domain/entities/daily_streak.dart';
import 'package:m6_sudoku/features/sudoku/domain/repositories/daily_streak_repository.dart';

class RecordDailyStreakCompletionUseCase {
  RecordDailyStreakCompletionUseCase(this._repository);

  final DailyStreakRepository _repository;

  Future<Either<Failure, ({DailyStreak streak, bool isFirstCompletionToday})>>
  call() {
    return _repository.recordCompletion();
  }
}
