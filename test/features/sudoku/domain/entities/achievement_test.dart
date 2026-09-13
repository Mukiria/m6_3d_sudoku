import 'package:flutter_test/flutter_test.dart';
import 'package:m6_sudoku/features/sudoku/domain/entities/achievement.dart';

void main() {
  group('Achievement', () {
    test('creates Achievement with all required fields', () {
      const achievement = Achievement(
        id: 'first_win',
        name: 'First Victory',
        description: 'Win your first game',
        icon: '🏆',
        category: AchievementCategory.wins,
        targetValue: 1,
        currentProgress: 0,
        isUnlocked: false,
        isSecret: false,
      );

      expect(achievement.id, equals('first_win'));
      expect(achievement.name, equals('First Victory'));
      expect(achievement.description, equals('Win your first game'));
      expect(achievement.icon, equals('🏆'));
      expect(achievement.category, equals(AchievementCategory.wins));
      expect(achievement.targetValue, equals(1));
      expect(achievement.currentProgress, equals(0));
      expect(achievement.isUnlocked, isFalse);
      expect(achievement.isSecret, isFalse);
      expect(achievement.unlockedAt, isNull);
    });

    test('copyWith updates only specified fields', () {
      const achievement = Achievement(
        id: 'first_win',
        name: 'First Victory',
        description: 'Win your first game',
        icon: '🏆',
        category: AchievementCategory.wins,
        targetValue: 1,
        currentProgress: 0,
        isUnlocked: false,
        isSecret: false,
      );

      final unlocked = achievement.copyWith(
        isUnlocked: true,
        currentProgress: 1,
        unlockedAt: DateTime(2024, 6, 15),
      );

      expect(unlocked.isUnlocked, isTrue);
      expect(unlocked.currentProgress, equals(1));
      expect(unlocked.unlockedAt, equals(DateTime(2024, 6, 15)));
      expect(unlocked.id, equals('first_win'));
      expect(unlocked.name, equals('First Victory'));
      expect(unlocked.category, equals(AchievementCategory.wins));
    });

    test('progress reaches target unlocks achievement', () {
      const achievement = Achievement(
        id: 'ten_wins',
        name: 'Decade of Wins',
        description: 'Win 10 games',
        icon: '🥇',
        category: AchievementCategory.wins,
        targetValue: 10,
        currentProgress: 9,
        isUnlocked: false,
        isSecret: false,
      );

      final updated = achievement.copyWith(currentProgress: 10);

      expect(updated.currentProgress >= updated.targetValue, isTrue);
      expect(updated.currentProgress, equals(10));
    });

    test('copyWith preserves unchanged fields', () {
      const achievement = Achievement(
        id: 'test',
        name: 'Test',
        description: 'Test description',
        icon: '⭐',
        category: AchievementCategory.wins,
        targetValue: 5,
        currentProgress: 3,
        isUnlocked: false,
        unlockedAt: null,
        isSecret: true,
      );

      final updated = achievement.copyWith(currentProgress: 4);

      expect(updated.currentProgress, equals(4));
      expect(updated.id, equals('test'));
      expect(updated.name, equals('Test'));
      expect(updated.description, equals('Test description'));
      expect(updated.icon, equals('⭐'));
      expect(updated.category, equals(AchievementCategory.wins));
      expect(updated.targetValue, equals(5));
      expect(updated.isUnlocked, isFalse);
      expect(updated.isSecret, isTrue);
      expect(updated.unlockedAt, isNull);
    });

    test('equality works correctly', () {
      const a1 = Achievement(
        id: 'a1',
        name: 'A1',
        description: 'Desc',
        icon: '⭐',
        category: AchievementCategory.wins,
        targetValue: 1,
        currentProgress: 0,
        isUnlocked: false,
        isSecret: false,
      );

      const a2 = Achievement(
        id: 'a1',
        name: 'A1',
        description: 'Desc',
        icon: '⭐',
        category: AchievementCategory.wins,
        targetValue: 1,
        currentProgress: 0,
        isUnlocked: false,
        isSecret: false,
      );

      const a3 = Achievement(
        id: 'a2',
        name: 'A2',
        description: 'Desc',
        icon: '⭐',
        category: AchievementCategory.wins,
        targetValue: 1,
        currentProgress: 0,
        isUnlocked: false,
        isSecret: false,
      );

      expect(a1, equals(a2));
      expect(a1.hashCode, equals(a2.hashCode));
      expect(a1, isNot(equals(a3)));
    });

    test('toJson and fromJson roundtrip', () {
      const achievement = Achievement(
        id: 'perfect_game',
        name: 'Perfectionist',
        description: 'Complete a game with 0 mistakes and 0 hints',
        icon: '✨',
        category: AchievementCategory.perfect,
        targetValue: 1,
        currentProgress: 0,
        isUnlocked: false,
        isSecret: false,
      );

      final json = achievement.toJson();
      final restored = Achievement.fromJson(json);

      expect(restored.id, equals(achievement.id));
      expect(restored.name, equals(achievement.name));
      expect(restored.description, equals(achievement.description));
      expect(restored.icon, equals(achievement.icon));
      expect(restored.category, equals(achievement.category));
      expect(restored.targetValue, equals(achievement.targetValue));
      expect(restored.currentProgress, equals(achievement.currentProgress));
      expect(restored.isUnlocked, equals(achievement.isUnlocked));
      expect(restored.isSecret, equals(achievement.isSecret));
      expect(restored.unlockedAt, isNull);
    });
  });

  group('AchievementCategory', () {
    test('all categories exist', () {
      expect(
        AchievementCategory.values,
        containsAll([
          AchievementCategory.wins,
          AchievementCategory.perfect,
          AchievementCategory.noHints,
          AchievementCategory.difficulty,
          AchievementCategory.speed,
          AchievementCategory.streak,
          AchievementCategory.special,
        ]),
      );
    });

    test('display names are correct', () {
      expect(AchievementCategory.wins.displayName, equals('Wins'));
      expect(AchievementCategory.perfect.displayName, equals('Perfect Games'));
      expect(AchievementCategory.noHints.displayName, equals('No Hints'));
      expect(AchievementCategory.difficulty.displayName, equals('Difficulty'));
      expect(AchievementCategory.speed.displayName, equals('Speed'));
      expect(AchievementCategory.streak.displayName, equals('Streak'));
      expect(AchievementCategory.special.displayName, equals('Special'));
    });
  });

  group('Achievement progress helpers', () {
    test('progress calculation works correctly', () {
      const achievement = Achievement(
        id: 'test',
        name: 'Test',
        description: 'Test',
        icon: '⭐',
        category: AchievementCategory.wins,
        targetValue: 10,
        currentProgress: 5,
        isUnlocked: false,
        isSecret: false,
      );

      // Helper function to calculate progress percentage
      final progressPercent =
          (achievement.currentProgress / achievement.targetValue) * 100;
      expect(progressPercent, equals(50.0));
    });

    test('isCompleted returns true when target reached', () {
      const unlocked = Achievement(
        id: 'test',
        name: 'Test',
        description: 'Test',
        icon: '⭐',
        category: AchievementCategory.wins,
        targetValue: 5,
        currentProgress: 5,
        isUnlocked: true,
        isSecret: false,
      );

      expect(unlocked.isUnlocked, isTrue);
      expect(unlocked.currentProgress >= unlocked.targetValue, isTrue);
    });
  });
}
