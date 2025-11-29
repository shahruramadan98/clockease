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
    return AttendanceRecord(
      date: DateTime.parse(map['date']),

      clockIn: map['clockIn'] != null
          ? DateTime.parse(map['clockIn'])
          : null,

      clockOut: map['clockOut'] != null
          ? DateTime.parse(map['clockOut'])
          : null,

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
}
