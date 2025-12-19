import 'package:cloud_firestore/cloud_firestore.dart';
import 'attendance_status.dart';

class AttendanceRecord {
  final DateTime date;
  final DateTime? clockIn;
  final DateTime? clockOut;
  final Duration totalHours;
  final Duration lateDuration;
  final AttendanceStatus status;

  AttendanceRecord({
    required this.date,
    this.clockIn,
    this.clockOut,
    required this.totalHours,
    required this.lateDuration,
    required this.status,
  });

  String get dateString => "${date.day}-${date.month}-${date.year}";

  factory AttendanceRecord.fromMap(Map<String, dynamic> map) {
    // 1. CONSTANTS (Static Schedule)
    const int workStartHour = 8;
    // const int workEndHour = 17; // 5 PM
    const Duration breakDuration = Duration(hours: 1);

    // --- SAFE PARSING FOR DATE ---
    DateTime _parseDate(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.parse(value);
      return DateTime.now();
    }

    DateTime? _parseNullableDate(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.parse(value);
      return null;
    }

    // 2. PARSE TIMESTAMPS
    final date = _parseDate(map['date']);
    final clockIn = _parseNullableDate(map['checkIn']);
    final clockOut = _parseNullableDate(map['checkOut']);

    // 3. DYNAMIC CALCULATIONS (Logic Separation)

    // A. Status & Late Duration
    AttendanceStatus status = AttendanceStatus.absent; // default
    Duration lateDuration = Duration.zero;

    if (clockIn != null) {
      // Create "8:00 AM" for the *same day* as the clockIn
      final scheduledStart = DateTime(
        clockIn.year,
        clockIn.month,
        clockIn.day,
        workStartHour,
        0,
      );

      // On Time → check-in time <= 8:00 AM
      // Late → check-in time > 8:00 AM
      if (clockIn.isAfter(scheduledStart)) {
        status = AttendanceStatus.late;
        lateDuration = clockIn.difference(scheduledStart);
      } else {
        status = AttendanceStatus.onTime;
        lateDuration = Duration.zero;
      }
    } else {
      status = AttendanceStatus.absent;
    }

    // B. Total Working Hours
    Duration totalHours = Duration.zero;
    if (clockIn != null && clockOut != null) {
      final rawDuration = clockOut.difference(clockIn);
      // Formula: (checkOut - checkIn) - breakTime
      totalHours = rawDuration - breakDuration;
      
      // Prevent negative hours
      if (totalHours.isNegative) {
        totalHours = Duration.zero;
      }
    }

    // Override status for half-day or absent logic if needed, 
    // but user requested STRICT simpler logic for now.

    return AttendanceRecord(
      date: date,
      clockIn: clockIn,
      clockOut: clockOut,
      totalHours: totalHours,
      lateDuration: lateDuration,
      status: status,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': Timestamp.fromDate(date),
      'checkIn': clockIn != null ? Timestamp.fromDate(clockIn!) : null,
      'checkOut': clockOut != null ? Timestamp.fromDate(clockOut!) : null,
      'totalMinutes': totalHours.inMinutes,
      'lateMinutes': lateDuration.inMinutes,
      'status': status.index,
    };
  }
}
