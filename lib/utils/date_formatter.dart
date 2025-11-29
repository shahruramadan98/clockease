import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Function to format Firestore Timestamp to user-friendly format
String formatClockIn(Timestamp clockInTimestamp) {
  // Convert Firestore Timestamp to DateTime object
  DateTime clockInDate = clockInTimestamp.toDate();

  // Format the DateTime into a user-friendly format
  String formattedClockIn = DateFormat('MMMM dd, yyyy h:mm a').format(clockInDate);

  return formattedClockIn;  // Example: "November 28, 2025 1:45 AM"
}
