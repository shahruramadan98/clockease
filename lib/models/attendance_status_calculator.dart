import 'attendance_status.dart';

/// Shared utility for calculating attendance status based on clock-in time
class AttendanceStatusCalculator {
  /// Standard work start time (8:00 AM)
  static const int workStartHour = 8;
  static const int workStartMinute = 0;

  /// Calculates attendance status and late duration based on clock-in time
  /// 
  /// Rules:
  /// - **Absent**: No clock-in time provided OR clock-in after work end time
  /// - **On Time**: Clock-in at or before scheduled work start time
  /// - **Late**: Clock-in after work start time but before or at work end time (returns late duration)
  /// 
  /// Optional schedule parameters allow per-employee schedules. If not provided,
  /// defaults to 8:00 AM - 5:00 PM for backward compatibility.
  /// 
  /// Returns a map with:
  /// - 'status': AttendanceStatus enum value
  /// - 'lateDuration': Duration object (zero if on time or absent)
  static Map<String, dynamic> calculateStatus(
    DateTime? clockIn, {
    int? workStartHour,
    int? workStartMinute,
    int? workEndHour,
    int? workEndMinute,
  }) {
    if (clockIn == null) {
      return {
        'status': AttendanceStatus.absent,
        'lateDuration': Duration.zero,
      };
    }

    // Use provided schedule or default to 8:00 AM - 5:00 PM
    final startHour = workStartHour ?? AttendanceStatusCalculator.workStartHour;
    final startMinute = workStartMinute ?? AttendanceStatusCalculator.workStartMinute;
    final endHour = workEndHour ?? 17; // Default 5:00 PM
    final endMinute = workEndMinute ?? 0;

    // Create scheduled start time and end time for the same day
    final scheduledStart = DateTime(
      clockIn.year,
      clockIn.month,
      clockIn.day,
      startHour,
      startMinute,
    );

    // Calculate end time (subtract 1 second to make it inclusive, e.g., 4:59:59 PM for 5:00 PM end)
    final scheduledEnd = DateTime(
      clockIn.year,
      clockIn.month,
      clockIn.day,
      endHour,
      endMinute,
    ).subtract(const Duration(seconds: 1));

    // Check if clocking in after scheduled end time - mark as absent
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
