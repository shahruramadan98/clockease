import 'package:cloud_firestore/cloud_firestore.dart';

class LeaveInfo {
  final String id;
  final String userId;
  final String companyId;
  final String userName;
  final String employeeId;
  final String leaveType;
  final DateTime startDate;
  final DateTime endDate;
  final String status;

  LeaveInfo({
    required this.id,
    required this.userId,
    required this.companyId,
    required this.userName,
    required this.employeeId,
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    required this.status,
  });

  // ✅ Preferred factory: build directly from Firestore document
  factory LeaveInfo.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;

    return LeaveInfo(
      id: doc.id,
      userId: data['userId'],
      companyId: data['companyId'],
      userName: data['userName'],
      employeeId: data['employeeId'],
      leaveType: data['leaveType'],
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      status: data['status'],
    );
  }

  bool includesDate(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);

    return !d.isBefore(start) && !d.isAfter(end);
  }

  int get durationDays =>
      endDate.difference(startDate).inDays + 1;

  String get formattedDateRange {
    if (startDate.year == endDate.year &&
        startDate.month == endDate.month &&
        startDate.day == endDate.day) {
      return '${startDate.day}/${startDate.month}/${startDate.year}';
    }
    return '${startDate.day}/${startDate.month}/${startDate.year}'
        ' - ${endDate.day}/${endDate.month}/${endDate.year}';
  }

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
}
