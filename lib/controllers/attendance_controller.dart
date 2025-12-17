import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/attendance_record.dart';
import '../models/attendance_status.dart';
import '../services/firestore_service.dart';

// =====================================================
// REALTIME ATTENDANCE LIST (MATCHES FirestoreService)
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

  /// Handles both Clock In and Clock Out
  Future<Map<String, dynamic>> logAttendance() async {
    final service = ref.read(firestoreServiceProvider);
    final now = DateTime.now();

    try {
      final todayRecord = await service.getTodayRecord();

      // =========================
      // CLOCK IN
      // =========================
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
          "message": "Clocked in successfully",
        };
      }

      // =========================
      // CLOCK OUT
      // =========================
      if (todayRecord.clockOut == null &&
          todayRecord.clockIn != null) {
        final workedDuration = now.difference(todayRecord.clockIn!);

        final updatedRecord = todayRecord.copyWith(
          clockOut: now,
          totalHours: workedDuration,
        );

        await service.saveRecord(updatedRecord);

        return {
          "success": true,
          "type": "checkOut",
          "message": "Clocked out successfully",
        };
      }

      // =========================
      // ALREADY COMPLETED
      // =========================
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
