import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/dashboard_attendance_state.dart';
import '../services/attendance_service.dart';
import '../services/location_service.dart';

class DashboardController extends StateNotifier<DashboardAttendanceState> {
  DashboardController() : super(DashboardAttendanceState.initial()) {
    loadToday();
  }

  final _attendanceService = AttendanceService();

  Future<void> loadToday() async {
    // UNIFIED SOURCE: Fetch from attendance/...
    final data = await _attendanceService.getTodayRecord();
    if (data != null) {
      state = DashboardAttendanceState.fromMap(data);
    } else {
      // If record exists (or was deleted), reset to initial state
      state = DashboardAttendanceState.initial();
    }
  }

  /// Called after Face Verification returns a file
  Future<void> confirmAttendance(File selfieImage, LocationData confirmedLocation) async {
    // 1. PRE-CHECK: (Removed completed check)

    try {
      // 2. UPLOAD & LOG with confirmed location
      await _attendanceService.uploadSelfieAndLogAttendance(
        selfieImage,
        confirmedLocation: confirmedLocation,
      );

      // 3. RE-FETCH SOURCE OF TRUTH
      // Instead of manual state updates, we fetch the updated record from backend
      // This ensures 100% consistency with what the server thinks.
      await loadToday();

    } catch (e) {
      // Rethrow to let UI show error
      throw Exception(e.toString());
    }
  }




}

final dashboardProvider =
    StateNotifierProvider<DashboardController, DashboardAttendanceState>(
      (ref) => DashboardController(),
    );
