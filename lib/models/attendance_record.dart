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

  String get dateString =>
      "${date.day}-${date.month}-${date.year}";

  String get shift => "8AM - 5PM";

  String get breakTime => "1h";

  factory AttendanceRecord.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.parse(val);
      return DateTime.now(); // Fallback
    }

    return AttendanceRecord(
      date: parseDate(map['date']),
      clockIn: map['clockIn'] != null ? parseDate(map['clockIn']) : null,
      clockOut: map['clockOut'] != null ? parseDate(map['clockOut']) : null,
      totalHours: Duration(
        minutes: map['totalMinutes'] is int ? map['totalMinutes'] : 0,
      ),
      lateDuration: Duration(
        minutes: map['lateMinutes'] is int ? map['lateMinutes'] : 0,
      ),
      status: _safeStatus(map['status']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'clockIn': clockIn?.toIso8601String(),
      'clockOut': clockOut?.toIso8601String(),
      'totalMinutes': totalHours.inMinutes,
      'lateMinutes': lateDuration.inMinutes,
      'status': status.index,
    };
  }

  static AttendanceStatus _safeStatus(dynamic raw) {
    if (raw is int && raw >= 0 && raw < AttendanceStatus.values.length) {
      return AttendanceStatus.values[raw];
    }
    return AttendanceStatus.onTime; // default fallback
  }

  String get formattedLateDuration => _formatDuration(lateDuration);
  String get formattedTotalHours => _formatDuration(totalHours);

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
