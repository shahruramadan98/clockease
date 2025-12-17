import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/dashboard_attendance_state.dart';
import '../models/attendance_record.dart';
import '../services/firestore_service.dart';
import '../models/attendance_status.dart';

final dashboardProvider = StateNotifierProvider<DashboardController, DashboardAttendanceState>(
  (ref) => DashboardController(ref.read(firestoreServiceProvider)),
);

class DashboardController extends StateNotifier<DashboardAttendanceState> {
  DashboardController(this._service) : super(DashboardAttendanceState.initial()) {
    loadToday();
  }

  final FirestoreService _service;

  // =====================================================
  // LOAD TODAY STATE FROM FIRESTORE
  // =====================================================
  Future<void> loadToday() async {
    final record = await _service.getTodayRecord();

    if (record == null) {
      state = DashboardAttendanceState.initial();
      return;
    }

    state = state.copyWith(
      isClockedIn: record.clockOut == null,
      lastAction: record.clockOut == null
          ? _formatTime(record.clockIn!)
          : _formatTime(record.clockOut!),
    );
  }

  // =====================================================
  // CLOCK IN / CLOCK OUT (FIRESTORE DRIVEN)
  // =====================================================
 Future<void> toggleClock() async {
  final now = DateTime.now();
  final today = await _service.getTodayRecord();

  // CLOCK IN
  if (today == null) {
    final record = AttendanceRecord(
      date: DateTime(now.year, now.month, now.day),
      clockIn: now,
      clockOut: null,
      totalHours: Duration.zero,
      lateDuration: Duration.zero,
      status: AttendanceStatus.onTime,
    );

    await _service.saveRecord(record);
    
    // Delay added for Firestore update
    await Future.delayed(Duration(seconds: 1));

    // Reload the state after clocking in
    await loadToday();
    return;
  }

  // CLOCK OUT
  if (today.clockOut == null) {
    final workedMinutes = now.difference(today.clockIn!).inMinutes - 60; // deduct break time

    final updated = today.copyWith(
      clockOut: now,
      totalHours: Duration(minutes: workedMinutes < 0 ? 0 : workedMinutes),
    );

    await _service.saveRecord(updated);

    // Delay added for Firestore update
    await Future.delayed(Duration(seconds: 1));

    // Reload the state after clocking out
    await loadToday();
  }
}




  // =====================================================
  // FORMAT TIME
  // =====================================================
  String _formatTime(DateTime t) {
    final hour = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.hour >= 12 ? 'PM' : 'AM';
    return "$hour:$minute $period";
  }
}
