enum AttendanceStep { notStarted, clockedIn }

class DashboardAttendanceState {
  final AttendanceStep step;
  final String? lastAction;

  bool get isClockedIn => step == AttendanceStep.clockedIn; 

  DashboardAttendanceState({
    required this.step,
    required this.lastAction,
  });

  factory DashboardAttendanceState.initial() {
    return DashboardAttendanceState(
      step: AttendanceStep.notStarted,
      lastAction: null,
    );
  }

  DashboardAttendanceState copyWith({
    AttendanceStep? step,
    String? lastAction,
  }) {
    return DashboardAttendanceState(
      step: step ?? this.step,
      lastAction: lastAction ?? this.lastAction,
    );
  }

  factory DashboardAttendanceState.fromMap(Map<String, dynamic> map) {
    // 1. TRUST 'isClockedIn' flag if present (New Logic)
    if (map.containsKey('isClockedIn')) {
      final bool isClockedIn = map['isClockedIn'] == true;
      return DashboardAttendanceState(
        step: isClockedIn ? AttendanceStep.clockedIn : AttendanceStep.notStarted,
        lastAction: map['formattedClockIn'] ?? map['formattedCheckOut'],
      );
    }

    // 2. FALLBACK (Legacy Logic)
    // If no 'isClockedIn' field (e.g. old record), try to guess, but avoiding "completed"
    final hasCheckIn = map['checkIn'] != null;
    final hasCheckOut = map['checkOut'] != null;

    AttendanceStep derivedStep = AttendanceStep.notStarted;
    
    // If checked in but not checked out, they are IN.
    // If checked in AND checked out, we treat them as OUT (ready to clock in again), 
    // effectively removing the "completed" deadlock.
    if (hasCheckIn && !hasCheckOut) {
      derivedStep = AttendanceStep.clockedIn;
    } else {
      derivedStep = AttendanceStep.notStarted;
    }

    return DashboardAttendanceState(
      step: derivedStep,
      lastAction: map['formattedClockIn'] ?? map['formattedCheckOut'], 
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'step': step.index, // Optional, mainly for debugging or local state
      'lastAction': lastAction,
    };
  }
}
