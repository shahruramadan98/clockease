import 'package:flutter_test/flutter_test.dart';
import 'package:clockease/models/dashboard_attendance_state.dart';

void main() {
  group('DashboardAttendanceState', () {
    test('initial state should be notStarted', () {
      final state = DashboardAttendanceState.initial();
      expect(state.step, AttendanceStep.notStarted);
      expect(state.isClockedIn, false);
    });

    test('should parse isClockedIn: true as clockedIn', () {
      final map = {
        'isClockedIn': true,
        'formattedClockIn': '10:00 AM',
      };
      final state = DashboardAttendanceState.fromMap(map);
      expect(state.step, AttendanceStep.clockedIn);
      expect(state.isClockedIn, true);
      expect(state.lastAction, '10:00 AM');
    });

    test('should parse isClockedIn: false as notStarted', () {
      final map = {
        'isClockedIn': false,
        'formattedCheckOut': '06:00 PM',
      };
      final state = DashboardAttendanceState.fromMap(map);
      expect(state.step, AttendanceStep.notStarted);
      expect(state.isClockedIn, false);
      expect(state.lastAction, '06:00 PM');
    });

    test('legacy: should parse checkIn only as clockedIn', () {
      final map = {
        'checkIn': 'timestamp',
        'formattedClockIn': '09:00 AM',
      };
      final state = DashboardAttendanceState.fromMap(map);
      expect(state.step, AttendanceStep.clockedIn);
      expect(state.isClockedIn, true);
    });

    test('legacy: should parse checkIn AND checkOut as notStarted (previously completed)', () {
      final map = {
        'checkIn': 'timestamp',
        'checkOut': 'timestamp',
        'formattedCheckOut': '05:00 PM',
      };
      // Previously, this would be completed. Now it should be notStarted (ready to clock in again)
      final state = DashboardAttendanceState.fromMap(map);
      expect(state.step, AttendanceStep.notStarted);
      expect(state.isClockedIn, false);
    });
  });
}
