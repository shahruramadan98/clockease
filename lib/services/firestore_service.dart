import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/attendance_record.dart';

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // =====================================================
  // HELPERS
  // =====================================================
  String _docId(DateTime d) =>
      "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

  String? get _uid => _auth.currentUser?.uid;

  // =====================================================
  // SAVE / UPDATE ATTENDANCE
  // =====================================================
  Future<void> saveRecord(AttendanceRecord record) async {
    if (_uid == null) return;

    await _db
        .collection("users")
        .doc(_uid)
        .collection("attendance")
        .doc(_docId(record.date))
        .set(record.toMap(), SetOptions(merge: true));
  }

  // =====================================================
  // GET TODAY RECORD
  // =====================================================
  Future<AttendanceRecord?> getTodayRecord() async {
    if (_uid == null) return null;

    final doc = await _db
        .collection("users")
        .doc(_uid)
        .collection("attendance")
        .doc(_docId(DateTime.now()))
        .get();

    if (!doc.exists || doc.data() == null) return null;

    return AttendanceRecord.fromMap(doc.data()!);
  }

  // =====================================================
  // REALTIME ATTENDANCE HISTORY
  // =====================================================
  Stream<List<AttendanceRecord>> watchAttendance() {
    if (_uid == null) {
      return const Stream.empty();
    }

    return _db
        .collection("users")
        .doc(_uid)
        .collection("attendance")
        .orderBy("date", descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) {
                try {
                  return AttendanceRecord.fromMap(doc.data());
                } catch (_) {
                  return null;
                }
              })
              .whereType<AttendanceRecord>()
              .toList(),
        );
  }
}
