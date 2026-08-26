import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static String formatEventDate(DateTime dateTime) {
    return DateFormat('EEE, d MMM yyyy - hh:mm a').format(dateTime);
  }

  static String formatShortDate(DateTime dateTime) {
    return DateFormat('d MMM yyyy').format(dateTime);
  }

  static String formatTime(DateTime dateTime) {
    return DateFormat('hh:mm a').format(dateTime);
  }
}
