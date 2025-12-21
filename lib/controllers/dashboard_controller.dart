import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/dashboard_attendance_state.dart';
import '../models/attendance_log.dart';
import '../services/attendance_service.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';

/// Stream provider that watches today's last attendance log
/// Automatically updates UI when Firestore data changes
final dashboardProvider = StreamProvider<DashboardAttendanceState>((ref) {
  final firestoreService = FirestoreService();
  
  return firestoreService.watchTodayLastLog().map((lastLog) {
    if (lastLog != null) {
      // Determine state based on last log type
      final isClockedIn = lastLog.type == AttendanceLogType.checkIn;
      return DashboardAttendanceState(
        step: isClockedIn ? AttendanceStep.clockedIn : AttendanceStep.notStarted,
        lastAction: lastLog.formattedTime,
      );
    } else {
      // No logs today, reset to initial state
      return DashboardAttendanceState.initial();
    }
  });
});

/// Controller for dashboard actions (clock in/out)
/// No longer manages state directly - state comes from the stream provider
class DashboardController {
  final _attendanceService = AttendanceService();

  /// Called after Face Verification returns a file
  Future<void> confirmAttendance(File selfieImage, LocationData confirmedLocation) async {
    try {
      // Upload & log attendance with confirmed location
      // The dashboardProvider stream will automatically update when
      // the new attendance log is written to Firestore
      await _attendanceService.uploadSelfieAndLogAttendance(
        selfieImage,
        confirmedLocation: confirmedLocation,
      );
      
      // No need to manually update state - the stream provider will
      // automatically emit the new state when Firestore data changes
      
    } catch (e) {
      // Rethrow to let UI show error
      throw Exception(e.toString());
    }
  }
}

/// Provider for dashboard controller actions
final dashboardControllerProvider = Provider((ref) => DashboardController());

