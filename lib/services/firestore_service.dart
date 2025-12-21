import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/attendance_log.dart';

final firestoreServiceProvider = Provider((ref) => FirestoreService());

class FirestoreService {
  final _db = FirebaseFirestore.instance;
  final _user = FirebaseAuth.instance.currentUser;




  // --- ATTENDANCE LOGS COLLECTION ---
  
  /// Stream attendance logs from the attendance_logs collection
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

  /// Fetch attendance logs once from the attendance_logs collection
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

  /// Get today's last attendance log for dashboard state
  Future<AttendanceLog?> getTodayLastLog() async {
    if (_user == null) return null;

    final now = DateTime.now();
    final today = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    final snap = await _db
        .collection('attendance_logs')
        .where('userId', isEqualTo: _user.uid)
        .where('date', isEqualTo: today)
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return null;

    return AttendanceLog.fromMap(snap.docs.first.data(), snap.docs.first.id);
  }

  /// Stream today's last attendance log for real-time dashboard updates
  /// This enables reactive UI that automatically updates when attendance is logged
  Stream<AttendanceLog?> watchTodayLastLog() {
    if (_user == null) return Stream.value(null);

    final now = DateTime.now();
    final today = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    return _db
        .collection('attendance_logs')
        .where('userId', isEqualTo: _user.uid)
        .where('date', isEqualTo: today)
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .map((snap) {
          if (snap.docs.isEmpty) return null;
          return AttendanceLog.fromMap(snap.docs.first.data(), snap.docs.first.id);
        });
  }
}

