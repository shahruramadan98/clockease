import 'package:intl/intl.dart';

String formatClockIn(DateTime clockIn) {
  return DateFormat('MMMM dd, yyyy h:mm a').format(clockIn);
}
