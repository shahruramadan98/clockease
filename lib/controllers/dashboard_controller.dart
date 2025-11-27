import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/dashboard_attendance_state.dart';
import '../models/attendance_record.dart';
import '../models/attendance_status.dart';
import '../services/firestore_service.dart';

class DashboardController extends StateNotifier<DashboardAttendanceState> {
  DashboardController() : super(DashboardAttendanceState.initial()) {
    loadToday();
  }

  final _service = FirestoreService();

  Future<void> loadToday() async {
    final record = await _service.getTodayAttendance();
    if (record != null) {
      state = record;
    }
  }

  Future<void> toggleClock() async {
    final now = DateTime.now();

    // CLOCK IN ------------------------------------------------------
    if (!state.isClockedIn) {
      final updated = state.copyWith(
        isClockedIn: true,
        lastAction: _formatTime(now),
      );

      state = updated;
      await _service.updateDashboardAttendance(updated);

      // Shift rules
      final shiftStart = DateTime(now.year, now.month, now.day, 8, 0);
      final lunchTime = DateTime(now.year, now.month, now.day, 12, 0);
      final shiftEnd = DateTime(now.year, now.month, now.day, 17, 0);

      AttendanceStatus status = AttendanceStatus.onTime;
      Duration lateDuration = Duration.zero;

      if (now.isAfter(shiftStart) && now.isBefore(lunchTime)) {
        status = AttendanceStatus.late;
        lateDuration = now.difference(shiftStart);
      } else if (now.isAfter(lunchTime) && now.isBefore(shiftEnd)) {
        status = AttendanceStatus.halfDay;
      } else if (now.isAfter(shiftEnd)) {
        status = AttendanceStatus.absent;
      }

      final rec = AttendanceRecord(
        date: DateTime(now.year, now.month, now.day),
        clockIn: now,
        clockOut: null,
        totalHours: Duration.zero,
        lateDuration: lateDuration,
        status: status,
      );

      await _service.saveAttendanceRecord(rec);
      return;
    }

    // CLOCK OUT ------------------------------------------------------
    if (state.isClockedIn) {
      final updated = state.copyWith(
        isClockedIn: false,
        lastAction: _formatTime(now),
      );

      state = updated;
      await _service.updateDashboardAttendance(updated);

      final today =
          await _service.getAttendanceRecordForDate(DateTime.now());
      if (today == null) return;

      final totalMinutes = now.difference(today.clockIn!).inMinutes;

      const breakMinutes = 60;
      final workMinutes = totalMinutes - breakMinutes;

      final rec = AttendanceRecord(
        date: today.date,
        clockIn: today.clockIn,
        clockOut: now,
        totalHours: Duration(minutes: workMinutes),
        lateDuration: today.lateDuration,
        status: today.status, // KEEP ORIGINAL STATUS
      );

      await _service.saveAttendanceRecord(rec);
    }
  }

  String _formatTime(DateTime time) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? "PM" : "AM";
    return "$hour:$minute $period";
  }
}

final dashboardProvider =
    StateNotifierProvider<DashboardController, DashboardAttendanceState>(
  (ref) => DashboardController(),
);
