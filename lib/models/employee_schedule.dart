import 'package:flutter/material.dart';

/// Represents an employee's work schedule
class EmployeeSchedule {
  final TimeOfDay workStartTime;
  final TimeOfDay workEndTime;

  const EmployeeSchedule({
    required this.workStartTime,
    required this.workEndTime,
  });

  /// Default schedule: 8:00 AM - 5:00 PM
  factory EmployeeSchedule.defaultSchedule() {
    return const EmployeeSchedule(
      workStartTime: TimeOfDay(hour: 8, minute: 0),
      workEndTime: TimeOfDay(hour: 17, minute: 0),
    );
  }

  /// Parse from Firestore string format (e.g., "08:00")
  factory EmployeeSchedule.fromFirestore(String? startTime, String? endTime) {
    final start = _parseTime(startTime) ?? const TimeOfDay(hour: 8, minute: 0);
    final end = _parseTime(endTime) ?? const TimeOfDay(hour: 17, minute: 0);
    
    return EmployeeSchedule(
      workStartTime: start,
      workEndTime: end,
    );
  }

  /// Parse time from "HH:mm" format
  static TimeOfDay? _parseTime(String? timeString) {
    if (timeString == null || timeString.isEmpty) return null;
    
    try {
      final parts = timeString.split(':');
      if (parts.length != 2) return null;
      
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      
      if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
      
      return TimeOfDay(hour: hour, minute: minute);
    } catch (e) {
      return null;
    }
  }

  /// Convert to Firestore string format (e.g., "08:00")
  String timeToString(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String get startTimeString => timeToString(workStartTime);
  String get endTimeString => timeToString(workEndTime);

  /// Format for display (e.g., "08:00 AM - 05:00 PM")
  String get displayString {
    return '${_formatTime(workStartTime)} - ${_formatTime(workEndTime)}';
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }
}
