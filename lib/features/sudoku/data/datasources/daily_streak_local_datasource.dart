import 'package:dartz/dartz.dart';
import 'package:m6_sudoku/core/errors/failures.dart';
import 'package:m6_sudoku/core/services/storage_service.dart';
import 'package:m6_sudoku/features/sudoku/domain/entities/daily_streak.dart';

class DailyStreakLocalDataSource {
  DailyStreakLocalDataSource(this._storage);

  final StorageService _storage;

  static const String _datesKey = 'daily_streak_dates';

  /// Bounds storage growth. A player's current streak can never exceed
  /// this many days without it having been visible well before then, so
  /// pruning older entries never affects the displayed streak.
  static const int _maxStoredDates = 400;

  /// [now] is injectable for testing; defaults to the real current time.
  Future<Either<Failure, ({DailyStreak streak, bool isFirstCompletionToday})>>
  recordCompletion({DateTime? now}) async {
    try {
      final today = now ?? DateTime.now();
      final todayString = DailyStreak.formatDate(today);

      final dates = _loadDates();
      final isFirstCompletionToday = !dates.contains(todayString);

      if (isFirstCompletionToday) {
        dates.add(todayString);
        dates.sort();
        if (dates.length > _maxStoredDates) {
          dates.removeRange(0, dates.length - _maxStoredDates);
        }
        await _storage.setStringList(_datesKey, dates);
      }

      return Right((
        streak: DailyStreak(
          currentStreak: _computeStreak(dates, today),
          completedDates: dates,
        ),
        isFirstCompletionToday: isFirstCompletionToday,
      ));
    } catch (e) {
      return Left(StorageFailure('Failed to record daily streak: $e'));
    }
  }

  List<String> _loadDates() =>
      List<String>.from(_storage.getStringList(_datesKey) ?? const []);

  /// Consecutive days, walking backward from [today], that appear in
  /// [dates]. A single missed day breaks the streak back to zero from
  /// that point.
  int _computeStreak(List<String> dates, DateTime today) {
    final dateSet = dates.toSet();
    var streak = 0;
    var day = today;
    while (dateSet.contains(DailyStreak.formatDate(day))) {
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }
}
