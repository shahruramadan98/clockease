import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/attendance_record.dart';
import '../services/firestore_service.dart';

// =====================================================
// PROVIDER: REALTIME ATTENDANCE LIST
// =====================================================
final attendanceProvider =
    StreamProvider<List<AttendanceRecord>>((ref) {
  final service = ref.read(firestoreServiceProvider);
  return service.watchAttendance();
});

// =====================================================
// CONTROLLER PROVIDER
// =====================================================
final attendanceControllerProvider =
    Provider<AttendanceController>((ref) {
  return AttendanceController(ref);
});

// =====================================================
// CONTROLLER
// =====================================================
class AttendanceController {
  final Ref ref;

  AttendanceController(this.ref);

  /// Toggle attendance:
  /// - If no record today → clock in
  /// - If clocked in → clock out
  /// - If already completed → do nothing
  Future<Map<String, dynamic>> toggleAttendance() async {
    final service = ref.read(firestoreServiceProvider);
    final now = DateTime.now();

    try {
      final todayRecord = await service.getTodayRecord();

      // ======================
      // CLOCK IN
      // ======================
      if (todayRecord == null) {
        final record = AttendanceRecord(
          date: now,
          clockIn: now,
          clockOut: null,
          totalHours: Duration.zero,
          lateDuration: Duration.zero,
          status: AttendanceStatus.onTime,
        );

        await service.saveRecord(record);

        return {
          "success": true,
          "type": "checkIn",
        };
      }

      // ======================
      // CLOCK OUT
      // ======================
      if (todayRecord.clockOut == null &&
          todayRecord.clockIn != null) {
        final workedDuration = now.difference(todayRecord.clockIn!);

        final updated = todayRecord.copyWith(
          clockOut: now,
          totalHours: workedDuration,
        );

        await service.saveRecord(updated);

        return {
          "success": true,
          "type": "checkOut",
        };
      }

      // ======================
      // ALREADY COMPLETED
      // ======================
      return {
        "success": false,
        "message": "Attendance already completed for today",
      };
    } catch (e) {
      return {
        "success": false,
        "message": e.toString(),
      };
    }
  }
}
