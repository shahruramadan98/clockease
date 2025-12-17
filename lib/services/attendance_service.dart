import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


class AttendanceService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  

  Future<Map<String, dynamic>> logAttendance() async {
    final user = _auth.currentUser;

    if (user == null) {
      return {"success": false, "message": "User not logged in"};
    }

    final uid = user.uid;
    final now = DateTime.now();
final today =
    "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";


    final attendanceRef = _db
    .collection('users')
    .doc(uid)
    .collection('attendance')
    .doc(today);

    final snapshot = await attendanceRef.get();

    /// ==============================
    /// CHECK-IN (no record yet)
    /// ==============================
    if (!snapshot.exists) {
  await attendanceRef.set({
    "date": Timestamp.fromDate(DateTime.now()), // ✅ REQUIRED
    "clockIn": FieldValue.serverTimestamp(),     // ✅ MATCH MODEL
    "clockOut": null,
    "method": "face",
  });

  return {"success": true, "type": "checkIn"};
}


    /// ==============================
    /// CHECK-OUT (record exists but no checkout)
    /// ==============================
    final data = snapshot.data() as Map<String, dynamic>;

    if (data["clockOut"] == null) {
  await attendanceRef.update({
    "clockOut": FieldValue.serverTimestamp(), // ✅ ONLY TIMESTAMP
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
