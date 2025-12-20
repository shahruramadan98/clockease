import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/attendance_record.dart';
import '../models/attendance_log.dart';
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



  Stream<List<AttendanceRecord>> getAttendanceStream() {
    if (_user == null) return Stream.value([]);

    return _db
        .collection('users')
        .doc(_user.uid)
        .collection('attendance')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => AttendanceRecord.fromMap(doc.data()))
            .toList());
  }

  Future<List<AttendanceRecord>> fetchAttendanceList() async {
    if (_user == null) return [];

    final snap = await _db
        .collection('users')
        .doc(_user.uid)
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
        .doc(_user.uid)
        .collection('attendance')
        .doc(_todayId)
        .get();

    if (!doc.exists || doc.data() == null) return null;

    return DashboardAttendanceState.fromMap(doc.data()!);
  }

  Future<void> updateDashboardAttendance(DashboardAttendanceState state) async {
    if (_user == null) return;

    await _db
        .collection('users')
        .doc(_user.uid)
        .collection('attendance')
        .doc(_todayId)
        .set(state.toMap(), SetOptions(merge: true));
  }

  Future<void> saveAttendanceRecord(AttendanceRecord rec) async {
    if (_user == null) return;

    await _db
        .collection('users')
        .doc(_user.uid)
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
        .doc(_user.uid)
        .collection('attendance')
        .doc(id)
        .get();

    if (!doc.exists) return null;

    return AttendanceRecord.fromMap(doc.data()!);
  }

  // --- NEW: ATTENDANCE LOGS COLLECTION ---
  
  /// Stream attendance logs from the new attendance_logs collection
  /// Index-safe: queries by userId only, sorts in Dart
  Stream<List<AttendanceLog>> getAttendanceLogsStream() {
    if (_user == null) return Stream.value([]);

    return _db
        .collection('attendance_logs')
        .where('userId', isEqualTo: _user.uid)
        .snapshots()
        .map((snap) {
          final logs = snap.docs
              .map((doc) => AttendanceLog.fromMap(doc.data(), doc.id))
              .toList();
          
          // Sort in Dart (descending by timestamp)
          logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          
          return logs;
        });
  }

  /// Fetch attendance logs once from the new attendance_logs collection
  /// Index-safe: queries by userId only, sorts in Dart
  Future<List<AttendanceLog>> fetchAttendanceLogs() async {
    if (_user == null) return [];

    final snap = await _db
        .collection('attendance_logs')
        .where('userId', isEqualTo: _user.uid)
        .get();

    final logs = snap.docs
        .map((doc) => AttendanceLog.fromMap(doc.data(), doc.id))
        .toList();
    
    // Sort in Dart (descending by timestamp)
    logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    return logs;
  }
}
