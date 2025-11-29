import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';  // Import intl package for date formatting

class AttendanceService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Function to format the Firestore Timestamp into a user-friendly string
  String formatClockIn(DateTime clockInDate) {
    return DateFormat('MMMM dd, yyyy h:mm a').format(clockInDate);  // Example: November 28, 2025 2:18 AM
  }

  Future<Map<String, dynamic>> logAttendance() async {
    final user = _auth.currentUser;

    if (user == null) {
      return {"success": false, "message": "User not logged in"};
    }

    final uid = user.uid;
    final today = DateFormat("yyyy-MM-dd").format(DateTime.now());

    final attendanceRef = _db
        .collection('attendance')
        .doc(uid)
        .collection('records')
        .doc(today);

    final snapshot = await attendanceRef.get();

    /// ==============================
    /// CHECK-IN (no record yet)
    /// ==============================
    if (!snapshot.exists) {
      // Get current timestamp and format it
      final now = DateTime.now();
      final formattedClockIn = formatClockIn(now);

      // Save raw Timestamp and formatted string
      await attendanceRef.set({
        "checkIn": FieldValue.serverTimestamp(),
        "formattedClockIn": formattedClockIn,  // Store formatted clockIn as a string
        "checkOut": null,
        "method": "face",
      });

      return {"success": true, "type": "checkIn"};
    }

    /// ==============================
    /// CHECK-OUT (record exists but no checkout)
    /// ==============================
    final data = snapshot.data() as Map<String, dynamic>;

    if (data["checkOut"] == null) {
      // Get current timestamp and format it
      final now = DateTime.now();
      final formattedCheckOut = formatClockIn(now);  // Format the checkOut time as well

      await attendanceRef.update({
        "checkOut": FieldValue.serverTimestamp(),
        "formattedCheckOut": formattedCheckOut,  // Store formatted checkOut as a string
      });

      return {"success": true, "type": "checkOut"};
    }

    /// ==============================
    /// COMPLETED (both done)
    /// ==============================
    return {
      "success": false,
      "message": "You already completed today's attendance"
    };
  }
}
