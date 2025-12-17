import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/attendance_record.dart';
import '../models/attendance_status.dart';
import '../models/dashboard_attendance_state.dart';
import '../services/firestore_service.dart';

// Stream Provider for Real-time Data
final attendanceListProvider = StreamProvider<List<AttendanceRecord>>((ref) {
  return ref.read(firestoreServiceProvider).getAttendanceStream();
});

// Action Provider
final attendanceControllerProvider = Provider((ref) => AttendanceController(ref));

enum AttendanceAction {
  checkIn,
  checkOut,
  earlyCheckOut,
  alreadyCompleted,
}

class AttendanceController {
  final Ref ref;

  AttendanceController(this.ref);

  Future<AttendanceAction> getNextAction() async {
    final now = DateTime.now();
    final firestoreService = ref.read(firestoreServiceProvider);

    final existingRecord =
        await firestoreService.getAttendanceRecordForDate(now);

    print("DEBUG: Checking existing record for $now");
    if (existingRecord == null) {
      print("DEBUG: No record found. Returning checkIn");
      return AttendanceAction.checkIn;
    } else if (existingRecord.clockOut == null) {
      // Check if it's early checkout
      // Shift rules: Ends at 5:00 PM (17:00)
      final shiftEnd = DateTime(now.year, now.month, now.day, 17, 0);
      if (now.isBefore(shiftEnd)) {
        print("DEBUG: Early checkout detected");
        return AttendanceAction.earlyCheckOut;
      }
      print("DEBUG: Normal checkout detected");
      return AttendanceAction.checkOut;
    } else {
      print("DEBUG: Already completed");
      return AttendanceAction.alreadyCompleted;
    }
  }

  Future<Map<String, dynamic>> logAttendance() async {
    try {
      final now = DateTime.now();
      final firestoreService = ref.read(firestoreServiceProvider);

      // 1. Check existing record
      final existingRecord =
          await firestoreService.getAttendanceRecordForDate(now);

      if (existingRecord == null) {
        // --- CLOCK IN LOGIC ---
        // Shift rules (Default: 8:00 AM - 5:00 PM)
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

        final newRecord = AttendanceRecord(
          date: now,
          clockIn: now,
          totalHours: Duration.zero, // Calculated at checkout
          lateDuration: lateDuration,
          status: status,
        );

        await firestoreService.saveAttendanceRecord(newRecord);

        // Update Dashboard State
        await firestoreService.updateDashboardAttendance(
          DashboardAttendanceState(
            isClockedIn: true,
            lastAction: "Clock In at ${now.hour}:${now.minute.toString().padLeft(2, '0')}",
          ),
        );

        return {"success": true, "message": "Clocked In successfully! Status: ${status.name}"};
      } else if (existingRecord.clockOut == null) {
        // --- CLOCK OUT LOGIC ---
        final rawDuration = now.difference(existingRecord.clockIn!);
        // Deduct 1 hour break if worked more than 1 hour (Business Logic)
        final adjustedMinutes = rawDuration.inMinutes > 60
            ? rawDuration.inMinutes - 60
            : rawDuration.inMinutes;

        final updatedRecord = AttendanceRecord(
          date: existingRecord.date,
          clockIn: existingRecord.clockIn,
          clockOut: now,
          totalHours: Duration(minutes: adjustedMinutes),
          lateDuration: existingRecord.lateDuration,
          status: existingRecord.status,
        );
        await firestoreService.saveAttendanceRecord(updatedRecord);

        // Update Dashboard State
        await firestoreService.updateDashboardAttendance(
          DashboardAttendanceState(
            isClockedIn: false,
            lastAction: "Clock Out at ${now.hour}:${now.minute.toString().padLeft(2, '0')}",
          ),
        );

        return {"success": true, "message": "Clocked Out successfully!"};
      } else {
        // ALREADY COMPLETED
        return {
          "success": false,
          "message": "Already completed attendance for today."
        };
      }
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }
}
