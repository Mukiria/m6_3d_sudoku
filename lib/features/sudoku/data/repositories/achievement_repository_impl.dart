import 'package:dartz/dartz.dart';
import 'package:m6_sudoku/features/sudoku/domain/entities/achievement.dart';
import 'package:m6_sudoku/features/sudoku/domain/repositories/achievement_repository.dart';
import 'package:m6_sudoku/features/sudoku/data/datasources/achievement_local_datasource.dart';
import 'package:m6_sudoku/core/errors/failures.dart';

class AchievementRepositoryImpl implements AchievementRepository {
  AchievementRepositoryImpl(this._dataSource);

  final AchievementLocalDataSource _dataSource;

  @override
  Future<Either<Failure, List<Achievement>>> getAchievements() {
    return _dataSource.getAchievements();
  }

  @override
  Future<Either<Failure, void>> unlockAchievement(String id) {
    return _dataSource.unlockAchievement(id);
  }

  @override
  Future<Either<Failure, void>> updateProgress(String id, int progress) {
    return _dataSource.updateProgress(id, progress);
  }

  @override
  Future<Either<Failure, Achievement?>> incrementProgress(
    String id,
    int amount,
  ) {
    return _dataSource.incrementProgress(id, amount);
  }

  @override
  Future<Either<Failure, List<Achievement>>> incrementProgressBatch(
    Map<String, int> deltas,
  ) {
    return _dataSource.incrementProgressBatch(deltas);
  }

  @override
  Future<Either<Failure, List<Achievement>>> getUnlockedAchievements() {
    return _dataSource.getUnlockedAchievements();
  }

  @override
  Future<Either<Failure, List<Achievement>>> getLockedAchievements() {
    return _dataSource.getLockedAchievements();
  }
}
