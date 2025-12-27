import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/attendance_record.dart';
import '../models/attendance_log.dart';
import '../models/attendance_status.dart';
import '../models/attendance_status_calculator.dart';
import '../services/firestore_service.dart';

final attendanceProvider = StreamProvider.autoDispose<List<AttendanceRecord>>((ref) {
  final firestore = ref.watch(firestoreServiceProvider);
  
  // Read from attendance_logs and group by date
  return firestore.getAttendanceLogsStream().map((logs) {
    return _groupLogsByDate(logs);
  });
});

/// Helper function to group attendance logs by date and create AttendanceRecord objects
List<AttendanceRecord> _groupLogsByDate(List<AttendanceLog> logs) {
  // Group logs by date string (YYYY-MM-DD)
  final Map<String, List<AttendanceLog>> groupedLogs = {};
  
  for (final log in logs) {
    final dateKey = log.dateString;
    if (!groupedLogs.containsKey(dateKey)) {
      groupedLogs[dateKey] = [];
    }
    groupedLogs[dateKey]!.add(log);
  }
  
  // Convert each group into an AttendanceRecord
  final List<AttendanceRecord> records = [];
  
  for (final entry in groupedLogs.entries) {
    final dateKey = entry.key;
    final dayLogs = entry.value;
    
    // Sort logs by timestamp (earliest first)
    dayLogs.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    
    // Find first check-in and last check-out
    final checkInLog = dayLogs.firstWhere(
      (log) => log.type == AttendanceLogType.checkIn,
      orElse: () => dayLogs.first,
    );
    
    final checkOutLogs = dayLogs.where((log) => log.type == AttendanceLogType.checkOut).toList();
    final checkOutLog = checkOutLogs.isNotEmpty ? checkOutLogs.last : null;
    
    // Use admin-amended times if available, otherwise use original timestamps
    final DateTime? clockIn = checkInLog.type == AttendanceLogType.checkIn
        ? (checkInLog.adminAmendedClockIn ?? checkInLog.timestamp)
        : null;
    final DateTime? clockOut = checkOutLog != null
        ? (checkOutLog.adminAmendedClockOut ?? checkOutLog.timestamp)
        : null;
    
    // Parse date from dateKey (YYYY-MM-DD)
    final dateParts = dateKey.split('-');
    final date = DateTime(
      int.parse(dateParts[0]),
      int.parse(dateParts[1]),
      int.parse(dateParts[2]),
    );
    
    // Use admin-amended total minutes if available, otherwise calculate
    Duration totalHours;
    if (checkInLog.adminAmendedTotalMinutes != null) {
      totalHours = Duration(minutes: checkInLog.adminAmendedTotalMinutes!);
    } else {
      totalHours = AttendanceStatusCalculator.calculateTotalHours(
        clockIn,
        clockOut,
      );
    }
    
    // Check for admin status override first, otherwise auto-calculate
    AttendanceStatus status;
    Duration lateDuration = Duration.zero;
    
    if (checkInLog.adminOverrideStatus != null) {
      // Use admin-overridden status
      switch (checkInLog.adminOverrideStatus!) {
        case 'onTime':
          status = AttendanceStatus.onTime;
          break;
        case 'late':
          status = AttendanceStatus.late;
          break;
        case 'halfDay':
          status = AttendanceStatus.halfDay;
          break;
        case 'absent':
          status = AttendanceStatus.absent;
          break;
        default:
          // Fallback to auto-calculate
          final statusResult = AttendanceStatusCalculator.calculateStatus(clockIn);
          status = statusResult['status'] as AttendanceStatus;
          lateDuration = statusResult['lateDuration'] as Duration;
      }
    } else {
      // Auto-calculate status and late duration
      final statusResult = AttendanceStatusCalculator.calculateStatus(clockIn);
      status = statusResult['status'] as AttendanceStatus;
      lateDuration = statusResult['lateDuration'] as Duration;
    }
    
    records.add(AttendanceRecord(
      date: date,
      clockIn: clockIn,
      clockOut: clockOut,
      totalHours: totalHours,
      lateDuration: lateDuration,
      status: status,
    ));
  }
  
  // Sort records by date descending (most recent first)
  records.sort((a, b) => b.date.compareTo(a.date));
  
  return records;
}

