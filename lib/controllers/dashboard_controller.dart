import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/attendance_model.dart';
import '../services/firestore_service.dart';

class DashboardController extends StateNotifier<AttendanceState> {
  DashboardController() : super(AttendanceState.initial()) {
    loadToday();
  }

  final _service = FirestoreService();

  /// Load today's attendance record from Firestore
  Future<void> loadToday() async {
    final record = await _service.getTodayAttendance();
    if (record != null) {
      state = record; // update UI
    }
  }

  /// Handle clock in / clock out
  Future<void> toggleClock() async {
    final now = _formatTime(DateTime.now());

    final updated = state.copyWith(
      isClockedIn: !state.isClockedIn,
      lastAction: now,
    );

    state = updated; // update UI immediately

    await _service.updateAttendance(updated); // update Firestore
  }

  /// Format time like 08:45 AM
  String _formatTime(DateTime time) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? "PM" : "AM";
    return "$hour:$minute $period";
  }
}

/// Riverpod provider for Dashboard
final dashboardProvider =
    StateNotifierProvider<DashboardController, AttendanceState>(
  (ref) => DashboardController(),
);
