import 'package:dartz/dartz.dart';
import 'package:m6_sudoku/features/sudoku/domain/entities/daily_streak.dart';
import 'package:m6_sudoku/features/sudoku/domain/repositories/daily_streak_repository.dart';
import 'package:m6_sudoku/features/sudoku/data/datasources/daily_streak_local_datasource.dart';
import 'package:m6_sudoku/core/errors/failures.dart';

class DailyStreakRepositoryImpl implements DailyStreakRepository {
  DailyStreakRepositoryImpl(this._dataSource);

  final DailyStreakLocalDataSource _dataSource;

  @override
  Future<Either<Failure, ({DailyStreak streak, bool isFirstCompletionToday})>>
  recordCompletion() {
    return _dataSource.recordCompletion();
  }
}
