import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

String formatClockIn(dynamic clockIn) {
  DateTime date;
  if (clockIn is Timestamp) {
    date = clockIn.toDate();
  } else if (clockIn is DateTime) {
    date = clockIn;
  } else {
    return 'Invalid Date';
  }
  return DateFormat('MMMM dd, yyyy h:mm a').format(date);
}
