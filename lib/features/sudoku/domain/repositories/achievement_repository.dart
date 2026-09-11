import 'package:dartz/dartz.dart';
import 'package:m6_sudoku/features/sudoku/domain/entities/achievement.dart';
import 'package:m6_sudoku/core/errors/failures.dart';

abstract class AchievementRepository {
  Future<Either<Failure, List<Achievement>>> getAchievements();
  Future<Either<Failure, void>> unlockAchievement(String id);
  Future<Either<Failure, void>> updateProgress(String id, int progress);

  /// Returns the unlocked [Achievement] if this call just unlocked it,
  /// otherwise `null`.
  Future<Either<Failure, Achievement?>> incrementProgress(
    String id,
    int amount,
  );

  /// Applies every entry in [deltas] (achievement id → progress delta) in
  /// one atomic read-modify-write, returning every achievement this call
  /// unlocked (possibly empty). Prefer this over multiple [incrementProgress]
  /// calls for achievements that can progress together from one event.
  Future<Either<Failure, List<Achievement>>> incrementProgressBatch(
    Map<String, int> deltas,
  );
  Future<Either<Failure, List<Achievement>>> getUnlockedAchievements();
  Future<Either<Failure, List<Achievement>>> getLockedAchievements();
}
