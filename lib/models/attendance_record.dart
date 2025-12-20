import 'package:cloud_firestore/cloud_firestore.dart';
import 'attendance_status.dart';
import 'attendance_status_calculator.dart';

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

    // B. Total Working Hours
    final totalHours = AttendanceStatusCalculator.calculateTotalHours(
      clockIn,
      clockOut,
    );

    // C. Status & Late Duration
    final statusResult = AttendanceStatusCalculator.calculateStatus(clockIn);
    final status = statusResult['status'] as AttendanceStatus;
    final lateDuration = statusResult['lateDuration'] as Duration;


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
