import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/staff_attendance_info.dart';
import '../models/attendance_log.dart';
import '../models/employee_schedule.dart';

class AdminAttendanceService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Stream comprehensive attendance info for all company staff for a specific date
  /// This provides real-time updates when staff clock in/out or admin makes edits
  Stream<List<StaffAttendanceInfo>> streamStaffAttendanceForDate(
    String companyId,
    DateTime date,
  ) async* {
    final dateString = DateFormat("yyyy-MM-dd").format(date);

    try {
      // 1. Get all employees for this company
      final employeesSnapshot = await _db
          .collection('companies')
          .doc(companyId)
          .collection('employees')
          .orderBy('fullName')
          .get();

      // 2. Listen to attendance_logs collection for real-time updates
      // Use snapshots() to get real-time stream
      await for (final logsSnapshot in _db
          .collection('attendance_logs')
          .where('date', isEqualTo: dateString)
          .snapshots()) {
        
        final List<StaffAttendanceInfo> staffList = [];

        for (final empDoc in employeesSnapshot.docs) {
          final empData = empDoc.data();
          final userId = empDoc.id;

          // Parse employee schedule
          final schedule = EmployeeSchedule.fromFirestore(
            empData['workStartTime'],
            empData['workEndTime'],
          );

          // Filter logs for this specific employee
          final userLogs = logsSnapshot.docs
              .where((doc) => doc.data()['userId'] == userId)
              .toList();

          AttendanceLog? clockInLog;
          AttendanceLog? clockOutLog;

          // Process logs to find clock in and clock out
          for (final logDoc in userLogs) {
            final log = AttendanceLog.fromMap(logDoc.data(), logDoc.id);

            if (log.type == AttendanceLogType.checkIn) {
              clockInLog = log;
            } else if (log.type == AttendanceLogType.checkOut) {
              clockOutLog = log;
            }
          }

          // Check if employee is on leave on the specified date
          final isOnLeave = await _isEmployeeOnLeaveForDate(userId, companyId, date);

          // Create staff attendance info
          final staffInfo = StaffAttendanceInfo(
            userId: userId,
            employeeId: empData['employeeId'] ?? '',
            fullName: empData['fullName'] ?? 'Unknown',
            designation: empData['designation'] ?? '',
            schedule: schedule,
            clockInLog: clockInLog,
            clockOutLog: clockOutLog,
            isOnLeave: isOnLeave,
          );

          staffList.add(staffInfo);
        }

        yield staffList;
      }
    } catch (e) {
      print('Error streaming staff attendance: $e');
      rethrow;
    }
  }

  /// Check if a specific employee is on approved leave for a given date
  Future<bool> _isEmployeeOnLeaveForDate(
    String userId,
    String companyId,
    DateTime date,
  ) async {
    try {
      final dayStart = DateTime(date.year, date.month, date.day);
      final dayEnd = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final leaveSnapshot = await _db
          .collection('leave_applications')
          .where('userId', isEqualTo: userId)
          .where('companyId', isEqualTo: companyId)
          .where('status', isEqualTo: 'approved')
          .get();

      // Check if any approved leave includes today
      for (final leaveDoc in leaveSnapshot.docs) {
        final data = leaveDoc.data();
        final startDate = (data['startDate'] as Timestamp).toDate();
        final endDate = (data['endDate'] as Timestamp).toDate();

        // Check if the specified date is within leave period
        if (!dayStart.isBefore(startDate) && !dayStart.isAfter(endDate)) {
          return true;
        }
      }

      return false;
    } catch (e) {
      print('Error checking leave status: $e');
      return false;
    }
  }

  /// Update attendance log with admin amendments
  Future<void> updateAttendanceLogAsAdmin({
    required String logId,
    DateTime? amendedClockIn,
    DateTime? amendedClockOut,
    int? amendedTotalMinutes,
    String? notes,
    String? overrideStatus, // "onTime", "late", "absent", "halfDay", or null
  }) async {
    try {
      final updates = <String, dynamic>{};

      if (amendedClockIn != null) {
        updates['adminAmendedClockIn'] = Timestamp.fromDate(amendedClockIn);
      }
      
      if (amendedClockOut != null) {
        updates['adminAmendedClockOut'] = Timestamp.fromDate(amendedClockOut);
      }
      
      if (amendedTotalMinutes != null) {
        updates['adminAmendedTotalMinutes'] = amendedTotalMinutes;
      }
      
      if (notes != null) {
        updates['adminNotes'] = notes;
      }
      
      if (overrideStatus != null) {
        updates['adminOverrideStatus'] = overrideStatus;
      }

      if (updates.isNotEmpty) {
        await _db.collection('attendance_logs').doc(logId).update(updates);
        print('✅ Admin amendments saved for log $logId');
      }
    } catch (e) {
      print('Error updating attendance log: $e');
      rethrow;
    }
  }

  /// Update admin notes for an attendance log
  Future<void> updateAdminNotes({
    required String logId,
    required String notes,
  }) async {
    try {
      await _db.collection('attendance_logs').doc(logId).update({
        'adminNotes': notes,
      });
    } catch (e) {
      print('Error updating admin notes: $e');
      rethrow;
    }
  }
}
