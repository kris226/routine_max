import '../models/day_record.dart';

/// Shared streak logic so Calendar and Account screens always agree.
class StreakUtils {
  static DateTime _todayUtc() {
    final now = DateTime.now();
    return DateTime.utc(now.year, now.month, now.day);
  }

  /// Walks backward from today. A missing day breaks the streak;
  /// a rest day (completionPercentage < 0) is neutral and doesn't break it.
  static int currentStreak(
    Map<DateTime, DayRecord> history,
    bool Function(DayRecord) matchFn,
  ) {
    int streak = 0;
    DateTime checkDate = _todayUtc();

    final todayRecord = history[checkDate];
    if (todayRecord == null || !matchFn(todayRecord)) {
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    while (true) {
      final record = history[checkDate];
      if (record == null) break;

      if (record.completionPercentage < 0) {
        checkDate = checkDate.subtract(const Duration(days: 1));
        continue;
      }

      if (matchFn(record)) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  /// Scans every calendar day (not just existing keys) between the first
  /// and last recorded day, so a day with NO record correctly breaks the
  /// streak, while an explicit rest day does not.
  static int bestStreak(
    Map<DateTime, DayRecord> history,
    bool Function(DayRecord) matchFn,
  ) {
    if (history.isEmpty) return 0;

    final sortedDates = history.keys.toList()..sort();
    DateTime day = sortedDates.first;
    final lastDate = sortedDates.last;

    int maxStreak = 0;
    int tempStreak = 0;

    while (!day.isAfter(lastDate)) {
      final record = history[day];

      if (record == null) {
        tempStreak = 0;
      } else if (record.completionPercentage < 0) {
        // rest day: neutral
      } else if (matchFn(record)) {
        tempStreak++;
        if (tempStreak > maxStreak) maxStreak = tempStreak;
      } else {
        tempStreak = 0;
      }

      day = day.add(const Duration(days: 1));
    }
    return maxStreak;
  }
}