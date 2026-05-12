import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static String formatDate(DateTime date) => DateFormat('MMM d, yyyy').format(date);

  static String formatDateTime(DateTime date) => DateFormat('MMM d, yyyy • h:mm a').format(date);

  static String formatShortDate(DateTime date) => DateFormat('d MMM').format(date);

  static String formatRelative(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return formatDate(date);
  }

  static String formatDueDate(String? dueDate) {
    if (dueDate == null || dueDate.isEmpty) return 'No due date';
    try {
      final date = DateTime.parse(dueDate);
      return formatDate(date);
    } catch (_) {
      return dueDate;
    }
  }
}
