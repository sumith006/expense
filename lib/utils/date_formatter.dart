import 'package:intl/intl.dart';

class DateFormatter {
  static String formatRelative(DateTime date, {String formatPattern = 'MMM dd, yyyy'}) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final tomorrow = today.add(const Duration(days: 1));
    final checkDate = DateTime(date.year, date.month, date.day);

    if (checkDate == today) {
      return 'Today';
    } else if (checkDate == yesterday) {
      return 'Yesterday';
    } else if (checkDate == tomorrow) {
      return 'Tomorrow';
    } else {
      return DateFormat(formatPattern).format(date);
    }
  }

  static String formatMonthYear(int month, int year) {
    final date = DateTime(year, month);
    return DateFormat('MMMM yyyy').format(date);
  }

  static String getDayDifferenceString(DateTime dueDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final difference = due.difference(today).inDays;

    if (difference == 0) {
      return 'Due today';
    } else if (difference == 1) {
      return 'Due tomorrow';
    } else if (difference == -1) {
      return 'Overdue by 1 day';
    } else if (difference < -1) {
      return 'Overdue by ${difference.abs()} days';
    } else {
      return 'Due in $difference days';
    }
  }
}
