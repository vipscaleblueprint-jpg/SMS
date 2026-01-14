import 'dart:math';

class SchedulingUtils {
  static const List<String> weekDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  /// Gets the suffix for a day of the month (e.g., 1st, 2nd, 3rd, 4th).
  static String getDaySuffix(int day) {
    if (day >= 11 && day <= 13) {
      return 'th';
    }
    switch (day % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }

  /// Calculates the next DateTime for a monthly frequency.
  /// If the target month has fewer days than [targetDay], it returns the last day of that month.
  static DateTime getNextMonthlyDate(
    int targetDay,
    DateTime from, {
    int hour = 9,
    int minute = 0,
  }) {
    int year = from.year;
    int month = from.month;

    // Try current month first if targetDay hasn't passed today
    DateTime targetThisMonth = _getDateOrLastDayOfMonth(
      year,
      month,
      targetDay,
      hour,
      minute,
    );

    if (targetThisMonth.isAfter(from)) {
      return targetThisMonth;
    }

    // Move to next month
    month++;
    if (month > 12) {
      month = 1;
      year++;
    }

    return _getDateOrLastDayOfMonth(year, month, targetDay, hour, minute);
  }

  /// Calculates the next DateTime for a weekly frequency.
  /// [targetWeekday] is 1 (Monday) to 7 (Sunday).
  static DateTime getNextWeeklyDate(
    int targetWeekday,
    DateTime from, {
    int hour = 9,
    int minute = 0,
  }) {
    int daysUntil = targetWeekday - from.weekday;
    if (daysUntil <= 0) {
      daysUntil += 7;
    }

    DateTime target = from.add(Duration(days: daysUntil));
    return DateTime(target.year, target.month, target.day, hour, minute);
  }

  static DateTime _getDateOrLastDayOfMonth(
    int year,
    int month,
    int day,
    int hour,
    int minute,
  ) {
    // DateTime(year, month + 1, 0) gives the last day of the current month
    int lastDay = DateTime(year, month + 1, 0).day;
    int actualDay = min(day, lastDay);
    return DateTime(year, month, actualDay, hour, minute);
  }
}
