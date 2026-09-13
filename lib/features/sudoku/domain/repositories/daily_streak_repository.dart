import 'package:dartz/dartz.dart';
import 'package:m6_sudoku/core/errors/failures.dart';
import 'package:m6_sudoku/features/sudoku/domain/entities/daily_streak.dart';

abstract class DailyStreakRepository {
  /// Marks today as a completed-puzzle day (if not already marked) and
  /// returns the resulting streak. [isFirstCompletionToday] tells the
  /// caller whether this call is what just marked today — i.e. whether
  /// this is the first puzzle completed today — so it knows whether to
  /// show the daily streak celebration.
  Future<Either<Failure, ({DailyStreak streak, bool isFirstCompletionToday})>>
  recordCompletion();
}
