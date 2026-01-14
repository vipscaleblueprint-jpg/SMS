import 'package:sms/utils/scheduling_utils.dart';

void main() {
  print('Testing Monthly Scheduling Logic...');

  // Test case 1: 30th of February (should pick last day of Feb)
  DateTime startFeb = DateTime(2026, 2, 1);
  DateTime nextFeb = SchedulingUtils.getNextMonthlyDate(30, startFeb);
  print('Feb 1st -> Next 30th: $nextFeb (Expected: 2026-02-28)');

  // Test case 2: 31st of April (should pick last day of April)
  DateTime startApril = DateTime(2026, 4, 1);
  DateTime nextApril = SchedulingUtils.getNextMonthlyDate(31, startApril);
  print('April 1st -> Next 31st: $nextApril (Expected: 2026-04-30)');

  // Test case 3: 15th of month, today is 1st
  DateTime startJan = DateTime(2026, 1, 1);
  DateTime nextJan = SchedulingUtils.getNextMonthlyDate(15, startJan);
  print('Jan 1st -> Next 15th: $nextJan (Expected: 2026-01-15)');

  // Test case 4: 15th of month, today is 20th
  DateTime midJan = DateTime(2026, 1, 20);
  DateTime nextFeb15 = SchedulingUtils.getNextMonthlyDate(15, midJan);
  print('Jan 20th -> Next 15th: $nextFeb15 (Expected: 2026-02-15)');

  print('\nTesting Weekly Scheduling Logic...');
  // Test case 5: Monday, today is Wednesday (3)
  DateTime wed = DateTime(2026, 1, 14); // Jan 14, 2026 is Wednesday
  DateTime nextMon = SchedulingUtils.getNextWeeklyDate(1, wed);
  print('Wed Jan 14 -> Next Monday: $nextMon (Expected: 2026-01-19)');
}
