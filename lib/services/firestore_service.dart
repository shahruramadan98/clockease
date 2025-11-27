import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/attendance_record.dart';
import '../models/dashboard_attendance_state.dart';

final firestoreServiceProvider = Provider((ref) => FirestoreService());

class FirestoreService {
  final _db = FirebaseFirestore.instance;
  final _user = FirebaseAuth.instance.currentUser;

  // ID for today's attendance
  String get _todayId {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  // --- HISTORY LIST ---
  Future<List<AttendanceRecord>> fetchAttendanceList() async {
    if (_user == null) return [];

    final snap = await _db
        .collection('users')
        .doc(_user!.uid)
        .collection('attendance')
        .orderBy('date', descending: true)
        .get();

    return snap.docs
        .map((doc) => AttendanceRecord.fromMap(doc.data()))
        .toList();
  }

  // --- DASHBOARD CLOCK STATE ---
  Future<DashboardAttendanceState?> getTodayAttendance() async {
    if (_user == null) return null;

    final doc = await _db
        .collection('users')
        .doc(_user!.uid)
        .collection('attendance')
        .doc(_todayId)
        .get();

    if (!doc.exists || doc.data() == null) return null;

    return DashboardAttendanceState.fromMap(doc.data()!);
  }

  Future<void> updateDashboardAttendance(
      DashboardAttendanceState state) async {
    if (_user == null) return;

    await _db
        .collection('users')
        .doc(_user!.uid)
        .collection('attendance')
        .doc(_todayId)
        .set(state.toMap(), SetOptions(merge: true));
  }

  Future<void> saveAttendanceRecord(AttendanceRecord rec) async {
  if (_user == null) return;

  await _db
      .collection('users')
      .doc(_user!.uid)
      .collection('attendance')
      .doc("${rec.date.year}-${rec.date.month}-${rec.date.day}")
      .set(rec.toMap(), SetOptions(merge: true));
}

Future<AttendanceRecord?> getAttendanceRecordForDate(DateTime date) async {
  if (_user == null) return null;

  final id =
      "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

  final doc = await _db
      .collection('users')
      .doc(_user!.uid)
      .collection('attendance')
      .doc(id)
      .get();

  if (!doc.exists) return null;

  return AttendanceRecord.fromMap(doc.data()!);
}


}
