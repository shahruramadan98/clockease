import 'attendance_status.dart';

/// Shared utility for calculating attendance status based on clock-in time
class AttendanceStatusCalculator {
  /// Standard work start time (8:00 AM)
  static const int workStartHour = 8;
  static const int workStartMinute = 0;

  /// Calculates attendance status and late duration based on clock-in time
  /// 
  /// Rules:
  /// - **Absent**: No clock-in time provided OR clock-in after 5:00 PM
  /// - **On Time**: Clock-in at or before 8:00 AM
  /// - **Late**: Clock-in after 8:00 AM but before or at 5:00 PM (returns late duration)
  /// 
  /// Returns a map with:
  /// - 'status': AttendanceStatus enum value
  /// - 'lateDuration': Duration object (zero if on time or absent)
  static Map<String, dynamic> calculateStatus(DateTime? clockIn) {
    if (clockIn == null) {
      return {
        'status': AttendanceStatus.absent,
        'lateDuration': Duration.zero,
      };
    }

    // Create scheduled start time (8:00 AM) and end time (5:00 PM) for the same day
    final scheduledStart = DateTime(
      clockIn.year,
      clockIn.month,
      clockIn.day,
      workStartHour,
      workStartMinute,
    );

    final scheduledEnd = DateTime(
      clockIn.year,
      clockIn.month,
      clockIn.day,
      16, // 4:00 PM
      59, // 59 minutes
      59, // 59 seconds
    );

    // Check if clocking in after 4:59:59 PM (i.e., 5:00 PM or later) - mark as absent
    if (clockIn.isAfter(scheduledEnd)) {
      return {
        'status': AttendanceStatus.absent,
        'lateDuration': Duration.zero,
      };
    }

    // Check if late (after 8:00 AM but before or at 5:00 PM)
    if (clockIn.isAfter(scheduledStart)) {
      return {
        'status': AttendanceStatus.late,
        'lateDuration': clockIn.difference(scheduledStart),
      };
    } else {
      return {
        'status': AttendanceStatus.onTime,
        'lateDuration': Duration.zero,
      };
    }
  }

  /// Calculates total working hours excluding break time
  /// 
  /// Formula: (clockOut - clockIn) - breakDuration
  /// Returns Duration.zero if result is negative or if either time is null
  static Duration calculateTotalHours(
    DateTime? clockIn,
    DateTime? clockOut, {
    Duration breakDuration = const Duration(hours: 1),
  }) {
    if (clockIn == null || clockOut == null) {
      return Duration.zero;
    }

    final rawDuration = clockOut.difference(clockIn);
    final totalHours = rawDuration - breakDuration;

    // Prevent negative hours
    if (totalHours.isNegative) {
      return Duration.zero;
    }

    return totalHours;
  }
}
