import 'package:flutter_test/flutter_test.dart';
import 'package:clockease/models/attendance_status.dart';
import 'package:clockease/models/attendance_status_calculator.dart';

void main() {
  group('AttendanceStatusCalculator', () {
    group('calculateStatus', () {
      test('should return absent when clockIn is null', () {
        final result = AttendanceStatusCalculator.calculateStatus(null);
        
        expect(result['status'], AttendanceStatus.absent);
        expect(result['lateDuration'], Duration.zero);
      });

      test('should return onTime when clocking in before 8:00 AM', () {
        final clockIn = DateTime(2025, 12, 21, 7, 30); // 7:30 AM
        final result = AttendanceStatusCalculator.calculateStatus(clockIn);
        
        expect(result['status'], AttendanceStatus.onTime);
        expect(result['lateDuration'], Duration.zero);
      });

      test('should return onTime when clocking in exactly at 8:00 AM', () {
        final clockIn = DateTime(2025, 12, 21, 8, 0); // 8:00 AM
        final result = AttendanceStatusCalculator.calculateStatus(clockIn);
        
        expect(result['status'], AttendanceStatus.onTime);
        expect(result['lateDuration'], Duration.zero);
      });

      test('should return late when clocking in 1 minute after 8:00 AM', () {
        final clockIn = DateTime(2025, 12, 21, 8, 1); // 8:01 AM
        final result = AttendanceStatusCalculator.calculateStatus(clockIn);
        
        expect(result['status'], AttendanceStatus.late);
        expect(result['lateDuration'], const Duration(minutes: 1));
      });

      test('should return late when clocking in 30 minutes after 8:00 AM', () {
        final clockIn = DateTime(2025, 12, 21, 8, 30); // 8:30 AM
        final result = AttendanceStatusCalculator.calculateStatus(clockIn);
        
        expect(result['status'], AttendanceStatus.late);
        expect(result['lateDuration'], const Duration(minutes: 30));
      });

      test('should return late when clocking in 1.5 hours after 8:00 AM', () {
        final clockIn = DateTime(2025, 12, 21, 9, 30); // 9:30 AM
        final result = AttendanceStatusCalculator.calculateStatus(clockIn);
        
        expect(result['status'], AttendanceStatus.late);
        expect(result['lateDuration'], const Duration(hours: 1, minutes: 30));
      });

      test('should return late when clocking in at 4:59 PM (before cutoff)', () {
        final clockIn = DateTime(2025, 12, 21, 16, 59); // 4:59 PM
        final result = AttendanceStatusCalculator.calculateStatus(clockIn);
        
        expect(result['status'], AttendanceStatus.late);
        expect((result['lateDuration'] as Duration).inHours, greaterThanOrEqualTo(8));
      });

      test('should return absent when clocking in exactly at 5:00 PM', () {
        final clockIn = DateTime(2025, 12, 21, 17, 0); // 5:00 PM
        final result = AttendanceStatusCalculator.calculateStatus(clockIn);
        
        // After 5:00 PM is considered absent
        expect(result['status'], AttendanceStatus.absent);
        expect(result['lateDuration'], Duration.zero);
      });

      test('should return absent when clocking in at 5:01 PM', () {
        final clockIn = DateTime(2025, 12, 21, 17, 1); // 5:01 PM
        final result = AttendanceStatusCalculator.calculateStatus(clockIn);
        
        expect(result['status'], AttendanceStatus.absent);
        expect(result['lateDuration'], Duration.zero);
      });

      test('should return absent when clocking in at 6:00 PM', () {
        final clockIn = DateTime(2025, 12, 21, 18, 0); // 6:00 PM
        final result = AttendanceStatusCalculator.calculateStatus(clockIn);
        
        expect(result['status'], AttendanceStatus.absent);
        expect(result['lateDuration'], Duration.zero);
      });

    });

    group('calculateTotalHours', () {
      test('should return zero when clockIn is null', () {
        final clockOut = DateTime(2025, 12, 21, 17, 0);
        final result = AttendanceStatusCalculator.calculateTotalHours(null, clockOut);
        
        expect(result, Duration.zero);
      });

      test('should return zero when clockOut is null', () {
        final clockIn = DateTime(2025, 12, 21, 8, 0);
        final result = AttendanceStatusCalculator.calculateTotalHours(clockIn, null);
        
        expect(result, Duration.zero);
      });

      test('should calculate correct hours with 1-hour break', () {
        final clockIn = DateTime(2025, 12, 21, 8, 0); // 8:00 AM
        final clockOut = DateTime(2025, 12, 21, 17, 0); // 5:00 PM
        final result = AttendanceStatusCalculator.calculateTotalHours(clockIn, clockOut);
        
        // 9 hours - 1 hour break = 8 hours
        expect(result, const Duration(hours: 8));
      });

      test('should return zero when total is negative (left before break)', () {
        final clockIn = DateTime(2025, 12, 21, 8, 0); // 8:00 AM
        final clockOut = DateTime(2025, 12, 21, 8, 30); // 8:30 AM
        final result = AttendanceStatusCalculator.calculateTotalHours(clockIn, clockOut);
        
        // 0.5 hours - 1 hour break = -0.5 hours → should return zero
        expect(result, Duration.zero);
      });

      test('should handle custom break duration', () {
        final clockIn = DateTime(2025, 12, 21, 8, 0); // 8:00 AM
        final clockOut = DateTime(2025, 12, 21, 17, 0); // 5:00 PM
        final result = AttendanceStatusCalculator.calculateTotalHours(
          clockIn,
          clockOut,
          breakDuration: const Duration(minutes: 30),
        );
        
        // 9 hours - 0.5 hour break = 8.5 hours
        expect(result, const Duration(hours: 8, minutes: 30));
      });

      test('should handle overnight shift', () {
        final clockIn = DateTime(2025, 12, 21, 22, 0); // 10:00 PM
        final clockOut = DateTime(2025, 12, 22, 6, 0); // 6:00 AM next day
        final result = AttendanceStatusCalculator.calculateTotalHours(clockIn, clockOut);
        
        // 8 hours - 1 hour break = 7 hours
        expect(result, const Duration(hours: 7));
      });
    });
  });
}
