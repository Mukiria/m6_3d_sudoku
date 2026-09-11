import 'package:freezed_annotation/freezed_annotation.dart';

part 'achievement.freezed.dart';
part 'achievement.g.dart';

@freezed
class Achievement with _$Achievement {
  const factory Achievement({
    required String id,
    required String name,
    required String description,
    required String icon,
    required AchievementCategory category,
    required int targetValue,
    required int currentProgress,
    required bool isUnlocked,
    DateTime? unlockedAt,
    required bool isSecret,
  }) = _Achievement;

  factory Achievement.fromJson(Map<String, dynamic> json) =>
      _$AchievementFromJson(json);
}

enum AchievementCategory {
  wins,
  perfect,
  noHints,
  difficulty,
  speed,
  streak,
  special,
  cube,
}

extension AchievementCategoryExtension on AchievementCategory {
  String get displayName {
    switch (this) {
      case AchievementCategory.wins:
        return 'Wins';
      case AchievementCategory.perfect:
        return 'Perfect Games';
      case AchievementCategory.noHints:
        return 'No Hints';
      case AchievementCategory.difficulty:
        return 'Difficulty';
      case AchievementCategory.speed:
        return 'Speed';
      case AchievementCategory.streak:
        return 'Streak';
      case AchievementCategory.special:
        return 'Special';
      case AchievementCategory.cube:
        return 'Cube';
    }
  }
}
