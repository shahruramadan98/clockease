import 'package:flutter/material.dart';
import 'attendance_log.dart';
import 'attendance_status.dart';
import 'attendance_status_calculator.dart';
import 'employee_schedule.dart';

/// Consolidated model combining employee data with today's attendance for admin view
class StaffAttendanceInfo {
  final String userId;
  final String employeeId;
  final String fullName;
  final String designation;
  final EmployeeSchedule schedule;
  
  // Attendance data for today
  final AttendanceLog? clockInLog;
  final AttendanceLog? clockOutLog;
  final bool isOnLeave;
  
  StaffAttendanceInfo({
    required this.userId,
    required this.employeeId,
    required this.fullName,
    required this.designation,
    required this.schedule,
    this.clockInLog,
    this.clockOutLog,
    this.isOnLeave = false,
  });

  /// Get the effective clock in time (amended  if available, otherwise original)
  DateTime? get effectiveClockIn {
    if (clockInLog == null) return null;
    return clockInLog!.adminAmendedClockIn ?? clockInLog!.timestamp;
  }

  /// Get the effective clock out time (amended if available, otherwise original)
  DateTime? get effectiveClockOut {
    if (clockOutLog == null) return null;
    return clockOutLog!.adminAmendedClockOut ?? clockOutLog!.timestamp;
  }

  /// Check if this attendance has been amended by admin
  bool get hasAmendments {
    return (clockInLog?.adminAmendedClockIn != null) ||
        (clockOutLog?.adminAmendedClockOut != null) ||
        (clockInLog?.adminAmendedTotalMinutes != null) ||
        (clockInLog?.adminOverrideStatus != null);
  }

  /// Get admin notes (prioritize clock in log's notes)
  String? get adminNotes {
    return clockInLog?.adminNotes ?? clockOutLog?.adminNotes;
  }

  /// Calculate attendance status based on employee's schedule
  /// If admin has overridden the status, use that instead
  AttendanceStatus get status {
    if (isOnLeave) return AttendanceStatus.onTime; // On leave counts as present
    
    // Check if admin has overridden the status
    if (clockInLog?.adminOverrideStatus != null) {
      switch (clockInLog!.adminOverrideStatus!) {
        case 'onTime':
          return AttendanceStatus.onTime;
        case 'late':
          return AttendanceStatus.late;
        case 'absent':
          return AttendanceStatus.absent;
        case 'halfDay':
          return AttendanceStatus.halfDay;
      }
    }
    
    if (effectiveClockIn == null) {
      return AttendanceStatus.absent;
    }

    final result = AttendanceStatusCalculator.calculateStatus(
      effectiveClockIn,
      workStartHour: schedule.workStartTime.hour,
      workStartMinute: schedule.workStartTime.minute,
      workEndHour: schedule.workEndTime.hour,
      workEndMinute: schedule.workEndTime.minute,
    );

    return result['status'] as AttendanceStatus;
  }

  /// Get late duration based on employee's schedule
  Duration get lateDuration {
    if (effectiveClockIn == null) return Duration.zero;

    final result = AttendanceStatusCalculator.calculateStatus(
      effectiveClockIn,
      workStartHour: schedule.workStartTime.hour,
      workStartMinute: schedule.workStartTime.minute,
      workEndHour: schedule.workEndTime.hour,
      workEndMinute: schedule.workEndTime.minute,
    );

    return result['lateDuration'] as Duration;
  }

  /// Calculate total working hours
  Duration get totalWorkingHours {
    // If admin has amended the total minutes, use that
    if (clockInLog?.adminAmendedTotalMinutes != null) {
      return Duration(minutes: clockInLog!.adminAmendedTotalMinutes!);
    }

    if (effectiveClockIn == null || effectiveClockOut == null) {
      return Duration.zero;
    }

    return AttendanceStatusCalculator.calculateTotalHours(
      effectiveClockIn,
      effectiveClockOut,
    );
  }

  /// Format total working hours as "Xh Ym"
  String get formattedWorkingHours {
    final hours = totalWorkingHours.inHours;
    final minutes = totalWorkingHours.inMinutes.remainder(60);
    
    if (hours == 0 && minutes == 0) return '-';
    if (hours == 0) return '${minutes}m';
    if (minutes == 0) return '${hours}h';
    return '${hours}h ${minutes}m';
  }

  /// Get status text
  String get statusText {
    if (isOnLeave) return 'On Leave';
    
    switch (status) {
      case AttendanceStatus.onTime:
        return 'On Time';
      case AttendanceStatus.late:
        final mins = lateDuration.inMinutes;
        return 'Late ($mins min)';
      case AttendanceStatus.halfDay:
        return 'Half Day';
      case AttendanceStatus.absent:
        return 'Absent';
    }
  }

  /// Get status color
  Color get statusColor {
    if (isOnLeave) return Colors.blue;
    
    switch (status) {
      case AttendanceStatus.onTime:
        return Colors.green;
      case AttendanceStatus.late:
        return Colors.orange;
      case AttendanceStatus.halfDay:
        return Colors.amber;
      case AttendanceStatus.absent:
        return Colors.red;
    }
  }
}
