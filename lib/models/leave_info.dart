import 'package:cloud_firestore/cloud_firestore.dart';

class LeaveInfo {
  final String userId;
  final String userName;
  final String employeeId;
  final String leaveType;
  final DateTime startDate;
  final DateTime endDate;
  final String status;

  LeaveInfo({
    required this.userId,
    required this.userName,
    required this.employeeId,
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    required this.status,
  });

  factory LeaveInfo.fromMap(Map<String, dynamic> map, String userId, String userName, String employeeId) {
    return LeaveInfo(
      userId: userId,
      userName: userName,
      employeeId: employeeId,
      leaveType: map['leaveType'] ?? 'Unknown',
      startDate: (map['startDate'] as Timestamp).toDate(),
      endDate: (map['endDate'] as Timestamp).toDate(),
      status: map['status'] ?? 'pending',
    );
  }

  // Check if this leave includes the given date
  bool includesDate(DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);
    
    return (dateOnly.isAtSameMomentAs(start) || dateOnly.isAfter(start)) &&
           (dateOnly.isAtSameMomentAs(end) || dateOnly.isBefore(end));
  }

  // Get duration in days
  int get durationDays {
    return endDate.difference(startDate).inDays + 1;
  }

  String get formattedDateRange {
    if (startDate.year == endDate.year &&
        startDate.month == endDate.month &&
        startDate.day == endDate.day) {
      return '${startDate.day}/${startDate.month}/${startDate.year}';
    }
    return '${startDate.day}/${startDate.month}/${startDate.year} - ${endDate.day}/${endDate.month}/${endDate.year}';
  }
}
