import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/attendance_record.dart';
import '../models/attendance_log.dart';
import '../models/attendance_status.dart';
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
    
    // Calculate total hours and status
    final DateTime? clockIn = checkInLog.type == AttendanceLogType.checkIn ? checkInLog.timestamp : null;
    final DateTime? clockOut = checkOutLog?.timestamp;
    
    // Parse date from dateKey (YYYY-MM-DD)
    final dateParts = dateKey.split('-');
    final date = DateTime(
      int.parse(dateParts[0]),
      int.parse(dateParts[1]),
      int.parse(dateParts[2]),
    );
    
    // Calculate total hours
    Duration totalHours = Duration.zero;
    const Duration breakDuration = Duration(hours: 1);
    
    if (clockIn != null && clockOut != null) {
      final rawDuration = clockOut.difference(clockIn);
      totalHours = rawDuration - breakDuration;
      if (totalHours.isNegative) {
        totalHours = Duration.zero;
      }
    }
    
    // Calculate status and late duration
    AttendanceStatus status = AttendanceStatus.absent;
    Duration lateDuration = Duration.zero;
    
    if (clockIn != null) {
      // Check if late (after 8:00 AM)
      final scheduledStart = DateTime(
        clockIn.year,
        clockIn.month,
        clockIn.day,
        8, // 8:00 AM
        0,
      );
      
      if (clockIn.isAfter(scheduledStart)) {
        status = AttendanceStatus.late;
        lateDuration = clockIn.difference(scheduledStart);
      } else {
        status = AttendanceStatus.onTime;
      }
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

