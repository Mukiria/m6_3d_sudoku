import 'package:equatable/equatable.dart';

/// Tracks how many consecutive calendar days the player has completed at
/// least one puzzle on — distinct from [DailyChallengeStats], which tracks
/// the separate "same puzzle for everyone" Daily Challenge feature.
class DailyStreak extends Equatable {
  const DailyStreak({
    required this.currentStreak,
    required this.completedDates,
  });

  /// Consecutive days (ending today) with at least one puzzle completed.
  final int currentStreak;

  /// Every date (`yyyy-MM-dd`, ascending) a puzzle was completed on,
  /// capped to a bounded recent window by the data source.
  final List<String> completedDates;

  /// Which days of the current week (Sunday=0 .. Saturday=6, up to and
  /// including [referenceDate]) had a completed puzzle.
  Set<int> completedWeekdaysThisWeek(DateTime referenceDate) {
    final today = DateTime(
      referenceDate.year,
      referenceDate.month,
      referenceDate.day,
    );
    final todayIndex = today.weekday % 7; // Mon=1..Sun=7 -> Sun=0..Sat=6
    final startOfWeek = today.subtract(Duration(days: todayIndex));
    final dateSet = completedDates.toSet();

    final result = <int>{};
    for (var i = 0; i <= todayIndex; i++) {
      final day = startOfWeek.add(Duration(days: i));
      if (dateSet.contains(formatDate(day))) result.add(i);
    }
    return result;
  }

  static String formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  @override
  List<Object?> get props => [currentStreak, completedDates];
}
