import 'package:cloud_firestore/cloud_firestore.dart';

enum AttendanceLogType { checkIn, checkOut }

class AttendanceLog {
  final String? id;
  final AttendanceLogType type;
  final DateTime timestamp;
  final String? faceImagePath;

  AttendanceLog({
    this.id,
    required this.type,
    required this.timestamp,
    this.faceImagePath,
  });

  factory AttendanceLog.fromMap(Map<String, dynamic> map, String id) {
    AttendanceLogType typeFromStr(String? s) {
      if (s == 'checkIn') return AttendanceLogType.checkIn;
      return AttendanceLogType.checkOut;
    }

    DateTime toDate(dynamic v) {
      if (v is Timestamp) return v.toDate();
      return DateTime.now();
    }

    return AttendanceLog(
      id: id,
      type: typeFromStr(map['type']),
      timestamp: toDate(map['timestamp']),
      faceImagePath: map['faceImagePath'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type == AttendanceLogType.checkIn ? 'checkIn' : 'checkOut',
      'timestamp': Timestamp.fromDate(timestamp),
      'faceImagePath': faceImagePath,
    };
  }

  String get formattedTime {
    final t = timestamp;
    final hour = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.hour >= 12 ? 'PM' : 'AM';
    return "$hour:$minute $period";
  }

  String get dateString => "${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')}";
}
