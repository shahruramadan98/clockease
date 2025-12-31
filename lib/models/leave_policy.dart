import 'package:cloud_firestore/cloud_firestore.dart';

class LeavePolicy {
  final int annualLeave;
  final int sickLeave;
  final bool unpaidAllowed;
  final bool halfDayAllowed;

  LeavePolicy({
    required this.annualLeave,
    required this.sickLeave,
    required this.unpaidAllowed,
    required this.halfDayAllowed,
  });

  factory LeavePolicy.fromMap(Map<String, dynamic> map) {
    return LeavePolicy(
      annualLeave: map['annualLeave'] ?? 0,
      sickLeave: map['sickLeave'] ?? 0,
      unpaidAllowed: map['unpaidAllowed'] ?? false,
      halfDayAllowed: map['halfDayAllowed'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'annualLeave': annualLeave,
      'sickLeave': sickLeave,
      'unpaidAllowed': unpaidAllowed,
      'halfDayAllowed': halfDayAllowed,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
