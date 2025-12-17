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

  // =====================================================
  // UI HELPERS
  // =====================================================
  String get dateString => "${date.day}-${date.month}-${date.year}";

  String get shift => "8AM - 5PM";

  String get breakTime => "1h";

  String get formattedLateDuration => _formatDuration(lateDuration);

  String get formattedTotalHours => _formatDuration(totalHours);

  // =====================================================
  // COPY WITH METHOD (USED FOR STATE UPDATES)
  // =====================================================
  AttendanceRecord copyWith({
    DateTime? date,
    DateTime? clockIn,
    DateTime? clockOut,
    Duration? totalHours,
    Duration? lateDuration,
    AttendanceStatus? status,
  }) {
    return AttendanceRecord(
      date: date ?? this.date,
      clockIn: clockIn ?? this.clockIn,
      clockOut: clockOut ?? this.clockOut,
      totalHours: totalHours ?? this.totalHours,
      lateDuration: lateDuration ?? this.lateDuration,
      status: status ?? this.status,
    );
  }

  // =====================================================
  // FIRESTORE SERIALIZATION (FROM Map and to Map)
  // =====================================================
  factory AttendanceRecord.fromMap(Map<String, dynamic> map) {
    DateTime? toDate(dynamic v) {
      if (v is Timestamp) return v.toDate();
      return null;
    }

    return AttendanceRecord(
      date: toDate(map['date']) ?? DateTime.now(),
      clockIn: toDate(map['clockIn']),
      clockOut: toDate(map['clockOut']),
      totalHours: Duration(minutes: map['totalHours'] ?? 0),
      lateDuration: Duration(minutes: map['lateDuration'] ?? 0),
      status: AttendanceStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => AttendanceStatus.onTime,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "date": Timestamp.fromDate(date),
      "clockIn": clockIn != null ? Timestamp.fromDate(clockIn!) : null,
      "clockOut": clockOut != null ? Timestamp.fromDate(clockOut!) : null,
      "totalHours": totalHours.inMinutes,
      "lateDuration": lateDuration.inMinutes,
      "status": status.name,
    };
  }

  // =====================================================
  // INTERNAL HELPERS
  // =====================================================
  String _formatDuration(Duration d) {
    if (d.inMinutes == 0) return "0 mins";

    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);

    if (hours > 0) {
      return minutes == 0 ? "${hours}h" : "${hours}h ${minutes}m";
    } else {
      return "${minutes}m";
    }
  }
}
