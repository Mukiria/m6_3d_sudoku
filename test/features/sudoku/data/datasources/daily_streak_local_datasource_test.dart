import 'package:flutter_test/flutter_test.dart';
import 'package:m6_sudoku/features/sudoku/data/datasources/daily_streak_local_datasource.dart';

import '../../../../fakes/fake_services.dart';

void main() {
  group('DailyStreakLocalDataSource', () {
    test(
      'first completion of a day starts (or extends) the streak and reports itself as first',
      () async {
        final ds = DailyStreakLocalDataSource(FakeStorageService());
        final today = DateTime(2026, 3, 10);

        final result = await ds.recordCompletion(now: today);
        final data = result.fold((f) => throw Exception(f.message), (d) => d);

        expect(data.isFirstCompletionToday, true);
        expect(data.streak.currentStreak, 1);
        expect(data.streak.completedDates, ['2026-03-10']);
      },
    );

    test(
      'a second completion the same day does not re-trigger and streak is unchanged',
      () async {
        final ds = DailyStreakLocalDataSource(FakeStorageService());
        final today = DateTime(2026, 3, 10);

        await ds.recordCompletion(now: today);
        final second = await ds.recordCompletion(now: today);
        final data = second.fold((f) => throw Exception(f.message), (d) => d);

        expect(data.isFirstCompletionToday, false);
        expect(data.streak.currentStreak, 1);
      },
    );

    test('completing on consecutive days extends the streak', () async {
      final ds = DailyStreakLocalDataSource(FakeStorageService());
      final day1 = DateTime(2026, 3, 10);
      final day2 = DateTime(2026, 3, 11);
      final day3 = DateTime(2026, 3, 12);

      await ds.recordCompletion(now: day1);
      await ds.recordCompletion(now: day2);
      final third = await ds.recordCompletion(now: day3);
      final data = third.fold((f) => throw Exception(f.message), (d) => d);

      expect(data.isFirstCompletionToday, true);
      expect(data.streak.currentStreak, 3);
    });

    test('a missed day resets the streak back to 1', () async {
      final ds = DailyStreakLocalDataSource(FakeStorageService());
      final day1 = DateTime(2026, 3, 10);
      final day2 = DateTime(2026, 3, 11);
      // day 12 skipped entirely
      final day4 = DateTime(2026, 3, 13);

      await ds.recordCompletion(now: day1);
      await ds.recordCompletion(now: day2);
      final afterGap = await ds.recordCompletion(now: day4);
      final data = afterGap.fold((f) => throw Exception(f.message), (d) => d);

      expect(data.isFirstCompletionToday, true);
      expect(data.streak.currentStreak, 1);
    });

    test(
      'completedWeekdaysThisWeek only reports days up to and including today',
      () async {
        final ds = DailyStreakLocalDataSource(FakeStorageService());
        // 2026-03-08 is a Sunday; play Sun, Mon, Tue, skip Wed onward.
        final sunday = DateTime(2026, 3, 8);
        final monday = DateTime(2026, 3, 9);
        final tuesday = DateTime(2026, 3, 10);

        await ds.recordCompletion(now: sunday);
        await ds.recordCompletion(now: monday);
        final result = await ds.recordCompletion(now: tuesday);
        final data = result.fold((f) => throw Exception(f.message), (d) => d);

        final weekdays = data.streak.completedWeekdaysThisWeek(tuesday);
        expect(weekdays, {0, 1, 2});
      },
    );
  });
}
