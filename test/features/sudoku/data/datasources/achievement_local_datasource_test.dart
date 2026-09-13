import 'package:flutter_test/flutter_test.dart';
import 'package:m6_sudoku/features/sudoku/data/datasources/achievement_local_datasource.dart';
import 'package:m6_sudoku/features/sudoku/domain/entities/achievement.dart';

import '../../../../fakes/fake_services.dart';

void main() {
  group('AchievementLocalDataSource.incrementProgress', () {
    test('returns null while progress stays below target', () async {
      final ds = AchievementLocalDataSource(FakeStorageService());

      // 'ten_wins' has targetValue 10; a single increment shouldn't unlock it.
      final result = await ds.incrementProgress('ten_wins', 1);

      expect(result.isRight(), true);
      expect(result.fold((f) => throw Exception(f.message), (a) => a), isNull);

      final achievements = (await ds.getAchievements()).fold(
        (f) => throw Exception(f.message),
        (list) => list,
      );
      final tenWins = achievements.firstWhere((a) => a.id == 'ten_wins');
      expect(tenWins.currentProgress, 1);
      expect(tenWins.isUnlocked, false);
    });

    test(
      'returns the unlocked achievement exactly on the call that crosses the target',
      () async {
        final ds = AchievementLocalDataSource(FakeStorageService());

        // 'first_win' has targetValue 1, so the first call unlocks it.
        final result = await ds.incrementProgress('first_win', 1);

        final unlocked = result.fold(
          (f) => throw Exception(f.message),
          (a) => a,
        );
        expect(unlocked, isNotNull);
        expect(unlocked!.id, 'first_win');
        expect(unlocked.isUnlocked, true);
        expect(unlocked.unlockedAt, isNotNull);
      },
    );

    test(
      'returns null for every call after the achievement is unlocked',
      () async {
        final ds = AchievementLocalDataSource(FakeStorageService());

        final first = await ds.incrementProgress('first_win', 1);
        expect(
          first.fold((f) => throw Exception(f.message), (a) => a),
          isNotNull,
        );

        final second = await ds.incrementProgress('first_win', 1);
        expect(
          second.fold((f) => throw Exception(f.message), (a) => a),
          isNull,
        );
      },
    );

    test(
      'clamps progress at targetValue and unlocks exactly once for multi-step achievements',
      () async {
        final ds = AchievementLocalDataSource(FakeStorageService());

        // 'ten_wins' has targetValue 10.
        for (var i = 0; i < 9; i++) {
          final result = await ds.incrementProgress('ten_wins', 1);
          expect(
            result.fold((f) => throw Exception(f.message), (a) => a),
            isNull,
          );
        }

        final unlockResult = await ds.incrementProgress('ten_wins', 1);
        final unlocked = unlockResult.fold(
          (f) => throw Exception(f.message),
          (a) => a,
        );
        expect(unlocked, isNotNull);
        expect(unlocked!.currentProgress, 10);

        final overflowResult = await ds.incrementProgress('ten_wins', 5);
        expect(
          overflowResult.fold((f) => throw Exception(f.message), (a) => a),
          isNull,
        );
      },
    );
  });

  group(
    'AchievementLocalDataSource.incrementProgressBatch — distinctProgress',
    () {
      Future<Achievement> allDifficulties(AchievementLocalDataSource ds) async {
        final achievements = (await ds.getAchievements()).fold(
          (f) => throw Exception(f.message),
          (list) => list,
        );
        return achievements.firstWhere((a) => a.id == 'all_difficulties');
      }

      test(
        'a repeat difficulty does not advance progress a second time',
        () async {
          final ds = AchievementLocalDataSource(FakeStorageService());

          await ds.incrementProgressBatch(
            const {},
            distinctProgress: const {'all_difficulties': 'easy'},
          );
          await ds.incrementProgressBatch(
            const {},
            distinctProgress: const {'all_difficulties': 'easy'},
          );

          final achievement = await allDifficulties(ds);
          expect(achievement.currentProgress, 1);
          expect(achievement.progressKeys, ['easy']);
          expect(achievement.isUnlocked, false);
        },
      );

      test(
        'five distinct difficulties unlock the achievement exactly once',
        () async {
          final ds = AchievementLocalDataSource(FakeStorageService());
          const difficulties = ['easy', 'medium', 'hard', 'expert', 'evil'];

          List<Achievement> unlockedThisCall = [];
          for (final difficulty in difficulties) {
            final result = await ds.incrementProgressBatch(
              const {},
              distinctProgress: {'all_difficulties': difficulty},
            );
            unlockedThisCall = result.fold(
              (f) => throw Exception(f.message),
              (list) => list,
            );
          }

          // Only the 5th (final) call should have crossed the target.
          expect(
            unlockedThisCall.map((a) => a.id),
            contains('all_difficulties'),
          );

          final achievement = await allDifficulties(ds);
          expect(achievement.currentProgress, 5);
          expect(achievement.progressKeys, unorderedEquals(difficulties));
          expect(achievement.isUnlocked, true);
        },
      );

      test('winning the same difficulty five times never unlocks it', () async {
        final ds = AchievementLocalDataSource(FakeStorageService());

        for (var i = 0; i < 5; i++) {
          await ds.incrementProgressBatch(
            const {},
            distinctProgress: const {'all_difficulties': 'easy'},
          );
        }

        final achievement = await allDifficulties(ds);
        expect(achievement.currentProgress, 1);
        expect(achievement.isUnlocked, false);
      });

      test(
        'a distinctProgress credit is a no-op once already unlocked',
        () async {
          final ds = AchievementLocalDataSource(FakeStorageService());
          const difficulties = ['easy', 'medium', 'hard', 'expert', 'evil'];
          for (final difficulty in difficulties) {
            await ds.incrementProgressBatch(
              const {},
              distinctProgress: {'all_difficulties': difficulty},
            );
          }

          // A sixth, novel "key" after unlock must not reopen or over-progress it.
          final result = await ds.incrementProgressBatch(
            const {},
            distinctProgress: const {
              'all_difficulties': 'somehow-a-sixth-value',
            },
          );
          final unlocked = result.fold(
            (f) => throw Exception(f.message),
            (list) => list,
          );
          expect(unlocked, isEmpty);

          final achievement = await allDifficulties(ds);
          expect(achievement.currentProgress, 5);
          expect(achievement.progressKeys.length, 5);
        },
      );

      test(
        'plain deltas and distinctProgress apply together in one batch',
        () async {
          final ds = AchievementLocalDataSource(FakeStorageService());

          final result = await ds.incrementProgressBatch(
            const {'first_win': 1},
            distinctProgress: const {'all_difficulties': 'expert'},
          );
          final unlocked = result.fold(
            (f) => throw Exception(f.message),
            (list) => list,
          );
          expect(unlocked.map((a) => a.id), contains('first_win'));

          final achievements = (await ds.getAchievements()).fold(
            (f) => throw Exception(f.message),
            (list) => list,
          );
          final firstWin = achievements.firstWhere((a) => a.id == 'first_win');
          expect(firstWin.isUnlocked, true);
          final master = achievements.firstWhere(
            (a) => a.id == 'all_difficulties',
          );
          expect(master.currentProgress, 1);
          expect(master.progressKeys, ['expert']);
        },
      );
    },
  );
}
