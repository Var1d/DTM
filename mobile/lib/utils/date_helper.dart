import 'package:intl/intl.dart';

class DateHelper {
  static String format(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('dd MMM yyyy, HH:mm').format(date);
  }

  static String formatShort(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('dd MMM yyyy').format(date);
  }

  static String timeAgo(DateTime? date) {
    if (date == null) return '-';
    final diff = date.difference(DateTime.now());
    if (diff.isNegative) return 'Terlambat ${(-diff.inDays)} hari';
    if (diff.inDays > 0)  return '${diff.inDays} hari lagi';
    if (diff.inHours > 0) return '${diff.inHours} jam lagi';
    return '${diff.inMinutes} menit lagi';
  }
}
