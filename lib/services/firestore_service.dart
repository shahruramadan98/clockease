import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/attendance_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final User? _user = FirebaseAuth.instance.currentUser;

  String get _todayId {
    final now = DateTime.now();
    final y = now.year.toString();
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<AttendanceState?> getTodayAttendance() async {
    if (_user == null) return null;

    print("📥 Fetching today's attendance for: ${_user!.uid}");

    final doc = await _db
        .collection('users')
        .doc(_user!.uid)
        .collection('attendance')
        .doc(_todayId)
        .get();

    if (!doc.exists || doc.data() == null) {
      print("ℹ️ No attendance record found for today.");
      return null;
    }

    print("📄 Fetched data: ${doc.data()}");

    return AttendanceState.fromMap(doc.data()!);
  }

  Future<void> updateAttendance(AttendanceState state) async {
    if (_user == null) return;

    print("📤 Writing attendance: ${state.toMap()}");

    await _db
        .collection('users')
        .doc(_user!.uid)
        .collection('attendance')
        .doc(_todayId)
        .set(state.toMap(), SetOptions(merge: true));

    print("✅ Firestore write success");
  }
}
