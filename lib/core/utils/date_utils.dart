/// VIT-AP Sports — Date/time formatting utilities.
library;

import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;

class AppDateUtils {
  AppDateUtils._();

  /// "Sep 6, 2026"
  static String formatDate(DateTime date) {
    return DateFormat('MMM d, y').format(date);
  }

  /// "Sep 6"
  static String formatDateShort(DateTime date) {
    return DateFormat('MMM d').format(date);
  }

  /// "7:30 PM"
  static String formatTime(DateTime date) {
    return DateFormat('h:mm a').format(date);
  }

  /// "Sep 6, 2026 • 7:30 PM"
  static String formatDateTime(DateTime date) {
    return '${formatDate(date)} • ${formatTime(date)}';
  }

  /// "Sep 6 • 7:30 PM"
  static String formatDateTimeShort(DateTime date) {
    return '${formatDateShort(date)} • ${formatTime(date)}';
  }

  /// "2 hours ago", "just now", etc.
  static String formatRelative(DateTime date) {
    return timeago.format(date);
  }

  /// "Today", "Tomorrow", "Sep 6"
  static String formatSmartDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);
    final diff = dateOnly.difference(today).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff == -1) return 'Yesterday';
    return formatDateShort(date);
  }

  /// "Today, 7:30 PM" or "Sep 6, 7:30 PM"
  static String formatSmartDateTime(DateTime date) {
    return '${formatSmartDate(date)} • ${formatTime(date)}';
  }
}
