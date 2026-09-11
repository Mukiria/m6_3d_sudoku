import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:m6_sudoku/features/sudoku/domain/entities/achievement.dart';
import 'package:m6_sudoku/core/errors/failures.dart';
import 'package:m6_sudoku/core/services/json_store.dart';
import 'package:m6_sudoku/core/services/storage_service.dart';

class AchievementLocalDataSource {
  AchievementLocalDataSource(this._storage) : _json = JsonStore(_storage);

  final StorageService _storage;
  final JsonStore _json;

  static const String _achievementsKey = 'achievements';
  static const String _achievementProgressKey = 'achievement_progress_';

  List<Achievement> getDefaultAchievements() {
    return [
      // Wins
      Achievement(
        id: 'first_win',
        name: 'First Victory',
        description: 'Win your first game',
        icon: '🏆',
        category: AchievementCategory.wins,
        targetValue: 1,
        currentProgress: 0,
        isUnlocked: false,
        isSecret: false,
      ),
      Achievement(
        id: 'ten_wins',
        name: 'Decade of Wins',
        description: 'Win 10 games',
        icon: '🥇',
        category: AchievementCategory.wins,
        targetValue: 10,
        currentProgress: 0,
        isUnlocked: false,
        isSecret: false,
      ),
      Achievement(
        id: 'hundred_wins',
        name: 'Century Club',
        description: 'Win 100 games',
        icon: '💯',
        category: AchievementCategory.wins,
        targetValue: 100,
        currentProgress: 0,
        isUnlocked: false,
        isSecret: false,
      ),

      // Perfect Games
      Achievement(
        id: 'perfect_game',
        name: 'Perfectionist',
        description: 'Complete a game with 0 mistakes and 0 hints',
        icon: '✨',
        category: AchievementCategory.perfect,
        targetValue: 1,
        currentProgress: 0,
        isUnlocked: false,
        isSecret: false,
      ),
      Achievement(
        id: 'five_perfect',
        name: 'Flawless Five',
        description: 'Complete 5 perfect games',
        icon: '💎',
        category: AchievementCategory.perfect,
        targetValue: 5,
        currentProgress: 0,
        isUnlocked: false,
        isSecret: false,
      ),

      // No Hints
      Achievement(
        id: 'no_hints',
        name: 'Solo Solver',
        description: 'Complete a game without using hints',
        icon: '🧠',
        category: AchievementCategory.noHints,
        targetValue: 1,
        currentProgress: 0,
        isUnlocked: false,
        isSecret: false,
      ),
      Achievement(
        id: 'ten_no_hints',
        name: 'Hintless Hero',
        description: 'Complete 10 games without hints',
        icon: '🧠💪',
        category: AchievementCategory.noHints,
        targetValue: 10,
        currentProgress: 0,
        isUnlocked: false,
        isSecret: false,
      ),

      // Difficulty
      Achievement(
        id: 'expert_winner',
        name: 'Expert Champion',
        description: 'Win an Expert difficulty game',
        icon: '🏅',
        category: AchievementCategory.difficulty,
        targetValue: 1,
        currentProgress: 0,
        isUnlocked: false,
        isSecret: false,
      ),
      Achievement(
        id: 'evil_conqueror',
        name: 'Evil Conqueror',
        description: 'Win an Evil difficulty game',
        icon: '👑',
        category: AchievementCategory.difficulty,
        targetValue: 1,
        currentProgress: 0,
        isUnlocked: false,
        isSecret: true,
      ),
      Achievement(
        id: 'all_difficulties',
        name: 'Master of All',
        description: 'Win at least once on every difficulty',
        icon: '🌈',
        category: AchievementCategory.difficulty,
        targetValue: 5,
        currentProgress: 0,
        isUnlocked: false,
        isSecret: false,
      ),

      // Speed
      Achievement(
        id: 'speed_runner',
        name: 'Speed Runner',
        description: 'Complete any game in under 3 minutes',
        icon: '⚡',
        category: AchievementCategory.speed,
        targetValue: 180,
        currentProgress: 0,
        isUnlocked: false,
        isSecret: false,
      ),
      Achievement(
        id: 'lightning',
        name: 'Lightning Fast',
        description: 'Complete an Easy game in under 1 minute',
        icon: '⚡💨',
        category: AchievementCategory.speed,
        targetValue: 60,
        currentProgress: 0,
        isUnlocked: false,
        isSecret: false,
      ),

      // Streak
      Achievement(
        id: 'streak_three',
        name: 'Hot Streak',
        description: 'Win 3 games in a row',
        icon: '🔥',
        category: AchievementCategory.streak,
        targetValue: 3,
        currentProgress: 0,
        isUnlocked: false,
        isSecret: false,
      ),
      Achievement(
        id: 'streak_ten',
        name: 'Unstoppable',
        description: 'Win 10 games in a row',
        icon: '🔥🔥🔥',
        category: AchievementCategory.streak,
        targetValue: 10,
        currentProgress: 0,
        isUnlocked: false,
        isSecret: false,
      ),

      // Special
      Achievement(
        id: 'daily_champion',
        name: 'Daily Champion',
        description: 'Complete 30 daily challenges',
        icon: '📅',
        category: AchievementCategory.special,
        targetValue: 30,
        currentProgress: 0,
        isUnlocked: false,
        isSecret: false,
      ),
      Achievement(
        id: 'night_owl',
        name: 'Night Owl',
        description: 'Complete a game between midnight and 4 AM',
        icon: '🦉',
        category: AchievementCategory.special,
        targetValue: 1,
        currentProgress: 0,
        isUnlocked: false,
        isSecret: true,
      ),
      Achievement(
        id: 'early_bird',
        name: 'Early Bird',
        description: 'Complete a game between 4 AM and 7 AM',
        icon: '🐦',
        category: AchievementCategory.special,
        targetValue: 1,
        currentProgress: 0,
        isUnlocked: false,
        isSecret: true,
      ),

      // Cube
      Achievement(
        id: 'first_cube',
        name: 'Cube Master',
        description: 'Solve all six faces of a 3D Sudoku cube',
        icon: '🧊',
        category: AchievementCategory.cube,
        targetValue: 1,
        currentProgress: 0,
        isUnlocked: false,
        isSecret: false,
      ),
      Achievement(
        id: 'flawless_cube',
        name: 'Flawless Cube',
        description: 'Solve a cube with zero mistakes and zero hints',
        icon: '💎',
        category: AchievementCategory.cube,
        targetValue: 1,
        currentProgress: 0,
        isUnlocked: false,
        isSecret: false,
      ),
      Achievement(
        id: 'speed_cuber',
        name: 'Speed Cuber',
        description: 'Solve a cube in under 20 minutes',
        icon: '⚡',
        category: AchievementCategory.cube,
        targetValue: 1,
        currentProgress: 0,
        isUnlocked: false,
        isSecret: false,
      ),
      Achievement(
        id: 'evil_cube',
        name: 'Evil Six',
        description: 'Solve a cube with every face set to Evil difficulty',
        icon: '😈',
        category: AchievementCategory.cube,
        targetValue: 1,
        currentProgress: 0,
        isUnlocked: false,
        isSecret: true,
      ),
    ];
  }

  Future<Either<Failure, List<Achievement>>> getAchievements() async {
    try {
      final jsonString = _storage.getString(_achievementsKey);
      if (jsonString == null) {
        final defaults = getDefaultAchievements();
        await _saveAchievements(defaults);
        return Right(defaults);
      }
      final list = jsonDecode(jsonString) as List;
      final achievements =
          list
              .map((e) => Achievement.fromJson(e as Map<String, dynamic>))
              .toList();
      return Right(achievements);
    } catch (e) {
      return Left(CacheFailure('Failed to get achievements: $e'));
    }
  }

  Future<Either<Failure, void>> unlockAchievement(String id) async {
    final result = await getAchievements();
    return result.fold((failure) => Left(failure), (achievements) async {
      final index = achievements.indexWhere((a) => a.id == id);
      if (index == -1) {
        return Left(NotFoundFailure('Achievement not found: $id'));
      }
      final achievement = achievements[index];
      if (achievement.isUnlocked) {
        return const Right(null);
      }
      final unlocked = achievement.copyWith(
        isUnlocked: true,
        currentProgress: achievement.targetValue,
        unlockedAt: DateTime.now(),
      );
      achievements[index] = unlocked;
      await _saveAchievements(achievements);
      return const Right(null);
    });
  }

  Future<Either<Failure, void>> updateProgress(String id, int progress) async {
    final result = await getAchievements();
    return result.fold((failure) => Left(failure), (achievements) async {
      final index = achievements.indexWhere((a) => a.id == id);
      if (index == -1) {
        return Left(NotFoundFailure('Achievement not found: $id'));
      }
      final achievement = achievements[index];
      if (achievement.isUnlocked) {
        return const Right(null);
      }
      final newProgress = progress.clamp(0, achievement.targetValue);
      final updated = achievement.copyWith(
        currentProgress: newProgress,
        isUnlocked: newProgress >= achievement.targetValue,
        unlockedAt:
            newProgress >= achievement.targetValue ? DateTime.now() : null,
      );
      achievements[index] = updated;
      await _saveAchievements(achievements);
      return const Right(null);
    });
  }

  /// Returns the achievement's new state if this call is the one that
  /// unlocked it, or `null` if progress moved without unlocking (or the
  /// achievement was already unlocked, a no-op) — the caller uses this to
  /// know when to fire an unlock animation.
  Future<Either<Failure, Achievement?>> incrementProgress(
    String id,
    int amount,
  ) async {
    final result = await getAchievements();
    return result.fold((failure) => Left(failure), (achievements) async {
      final index = achievements.indexWhere((a) => a.id == id);
      if (index == -1) {
        return Left(NotFoundFailure('Achievement not found: $id'));
      }
      final achievement = achievements[index];
      if (achievement.isUnlocked) {
        return const Right(null);
      }
      final newProgress = (achievement.currentProgress + amount).clamp(
        0,
        achievement.targetValue,
      );
      final justUnlocked = newProgress >= achievement.targetValue;
      final updated = achievement.copyWith(
        currentProgress: newProgress,
        isUnlocked: justUnlocked,
        unlockedAt: justUnlocked ? DateTime.now() : null,
      );
      achievements[index] = updated;
      await _saveAchievements(achievements);
      return Right(justUnlocked ? updated : null);
    });
  }

  /// Applies every entry in [deltas] (achievement id → progress delta)
  /// against a single read-modify-write cycle, instead of one cycle per
  /// achievement. Multiple achievements progressing from the same event
  /// (e.g. a game completion) previously each ran their own
  /// getAchievements()-then-save() round trip; firing those concurrently
  /// raced on the same storage key and could silently lose updates. Routing
  /// them all through one batch call removes the race entirely.
  Future<Either<Failure, List<Achievement>>> incrementProgressBatch(
    Map<String, int> deltas,
  ) async {
    if (deltas.isEmpty) return const Right([]);
    final result = await getAchievements();
    return result.fold((failure) => Left(failure), (achievements) async {
      final justUnlocked = <Achievement>[];
      for (var i = 0; i < achievements.length; i++) {
        final achievement = achievements[i];
        final amount = deltas[achievement.id];
        if (amount == null || achievement.isUnlocked) continue;

        final newProgress = (achievement.currentProgress + amount).clamp(
          0,
          achievement.targetValue,
        );
        final unlockedNow = newProgress >= achievement.targetValue;
        final updated = achievement.copyWith(
          currentProgress: newProgress,
          isUnlocked: unlockedNow,
          unlockedAt: unlockedNow ? DateTime.now() : null,
        );
        achievements[i] = updated;
        if (unlockedNow) justUnlocked.add(updated);
      }
      await _saveAchievements(achievements);
      return Right(justUnlocked);
    });
  }

  Future<Either<Failure, void>> _saveAchievements(
    List<Achievement> achievements,
  ) {
    return _json.writeJson(
      _achievementsKey,
      achievements.map((a) => a.toJson()).toList(),
      'save achievements',
    );
  }

  Future<Either<Failure, List<Achievement>>> getUnlockedAchievements() async {
    final result = await getAchievements();
    return result.fold(
      (failure) => Left(failure),
      (achievements) => Right(achievements.where((a) => a.isUnlocked).toList()),
    );
  }

  Future<Either<Failure, List<Achievement>>> getLockedAchievements() async {
    final result = await getAchievements();
    return result.fold(
      (failure) => Left(failure),
      (achievements) =>
          Right(achievements.where((a) => !a.isUnlocked).toList()),
    );
  }
}
