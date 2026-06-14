import 'package:intl/intl.dart';

/// Date and number formatting utilities
abstract final class DateFormatter {
  static final _displayDate = DateFormat('dd MMM yyyy');
  static final _displayDateTime = DateFormat('dd MMM yyyy, HH:mm');
  static final _apiDate = DateFormat('yyyy-MM-dd');
  static final _apiDateTime = DateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'");
  static final _timeOnly = DateFormat('HH:mm');
  static final _monthYear = DateFormat('MMM yyyy');

  /// e.g. "14 Jun 2026"
  static String toDisplay(DateTime date) => _displayDate.format(date);

  /// e.g. "14 Jun 2026, 16:10"
  static String toDisplayDateTime(DateTime date) =>
      _displayDateTime.format(date);

  /// e.g. "2026-06-14"
  static String toApi(DateTime date) => _apiDate.format(date);

  /// e.g. "2026-06-14T16:10:00Z"
  static String toApiDateTime(DateTime date) => _apiDateTime.format(date);

  /// e.g. "16:10"
  static String toTime(DateTime date) => _timeOnly.format(date);

  /// e.g. "Jun 2026"
  static String toMonthYear(DateTime date) => _monthYear.format(date);

  /// Relative time (e.g. "2 hours ago", "just now")
  static String toRelative(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return toDisplay(date);
  }
}
