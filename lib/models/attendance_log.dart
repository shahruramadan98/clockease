import 'package:cloud_firestore/cloud_firestore.dart';

enum AttendanceLogType { checkIn, checkOut }

class AttendanceLog {
  final String? id;
  final AttendanceLogType type;
  final DateTime timestamp;
  final String? faceImagePath;
  
  // Location fields
  final double? latitude;
  final double? longitude;
  final double? accuracy;
  final String? address;

  AttendanceLog({
    this.id,
    required this.type,
    required this.timestamp,
    this.faceImagePath,
    this.latitude,
    this.longitude,
    this.accuracy,
    this.address,
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

    // Extract location data if present
    final locationMap = map['location'] as Map<String, dynamic>?;

    return AttendanceLog(
      id: id,
      type: typeFromStr(map['type']),
      timestamp: toDate(map['timestamp']),
      faceImagePath: map['faceImagePath'],
      latitude: locationMap?['latitude']?.toDouble(),
      longitude: locationMap?['longitude']?.toDouble(),
      accuracy: locationMap?['accuracy']?.toDouble(),
      address: locationMap?['address'],
    );
  }

  Map<String, dynamic> toMap() {
    final map = {
      'type': type == AttendanceLogType.checkIn ? 'checkIn' : 'checkOut',
      'timestamp': Timestamp.fromDate(timestamp),
      'faceImagePath': faceImagePath,
    };

    // Add location data if available
    if (latitude != null && longitude != null) {
      map['location'] = {
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        if (address != null) 'address': address,
      };
    }

    return map;
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
