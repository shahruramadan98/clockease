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
  
  // Admin amendment fields
  final DateTime? adminAmendedClockIn;
  final DateTime? adminAmendedClockOut;
  final int? adminAmendedTotalMinutes;
  final String? adminNotes;
  final String? adminOverrideStatus; // "onTime", "late", "absent", or null for auto-calculated

  AttendanceLog({
    this.id,
    required this.type,
    required this.timestamp,
    this.faceImagePath,
    this.latitude,
    this.longitude,
    this.accuracy,
    this.address,
    this.adminAmendedClockIn,
    this.adminAmendedClockOut,
    this.adminAmendedTotalMinutes,
    this.adminNotes,
    this.adminOverrideStatus,
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

    DateTime? toNullableDate(dynamic v) {
      if (v == null) return null;
      if (v is Timestamp) return v.toDate();
      return null;
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
      adminAmendedClockIn: toNullableDate(map['adminAmendedClockIn']),
      adminAmendedClockOut: toNullableDate(map['adminAmendedClockOut']),
      adminAmendedTotalMinutes: map['adminAmendedTotalMinutes'] as int?,
      adminNotes: map['adminNotes'] as String?,
      adminOverrideStatus: map['adminOverrideStatus'] as String?,
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
    
    // Add admin amendment fields if present
    if (adminAmendedClockIn != null) {
      map['adminAmendedClockIn'] = Timestamp.fromDate(adminAmendedClockIn!);
    }
    if (adminAmendedClockOut != null) {
      map['adminAmendedClockOut'] = Timestamp.fromDate(adminAmendedClockOut!);
    }
    if (adminAmendedTotalMinutes != null) {
      map['adminAmendedTotalMinutes'] = adminAmendedTotalMinutes;
    }
    if (adminNotes != null && adminNotes!.isNotEmpty) {
      map['adminNotes'] = adminNotes;
    }
    if (adminOverrideStatus != null && adminOverrideStatus!.isNotEmpty) {
      map['adminOverrideStatus'] = adminOverrideStatus;
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
