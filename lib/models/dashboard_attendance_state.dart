class DashboardAttendanceState {
  final bool isClockedIn;
  final String? lastAction;

  DashboardAttendanceState({
    required this.isClockedIn,
    required this.lastAction,
  });

  factory DashboardAttendanceState.initial() {
    return DashboardAttendanceState(
      isClockedIn: false,
      lastAction: null,
    );
  }

  DashboardAttendanceState copyWith({
    bool? isClockedIn,
    String? lastAction,
  }) {
    return DashboardAttendanceState(
      isClockedIn: isClockedIn ?? this.isClockedIn,
      lastAction: lastAction ?? this.lastAction,
    );
  }

  factory DashboardAttendanceState.fromMap(Map<String, dynamic> map) {
    return DashboardAttendanceState(
      isClockedIn: map['isClockedIn'] ?? false,
      lastAction: map['lastAction'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isClockedIn': isClockedIn,
      'lastAction': lastAction,
    };
  }
}
