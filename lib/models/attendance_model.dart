class AttendanceState {
  final bool isClockedIn;
  final String lastAction;

  AttendanceState({
    required this.isClockedIn,
    required this.lastAction,
  });

  factory AttendanceState.initial() {
    return AttendanceState(isClockedIn: false, lastAction: "No record");
  }

  AttendanceState copyWith({
    bool? isClockedIn,
    String? lastAction,
  }) {
    return AttendanceState(
      isClockedIn: isClockedIn ?? this.isClockedIn,
      lastAction: lastAction ?? this.lastAction,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isClockedIn': isClockedIn,
      'lastAction': lastAction,
    };
  }

  factory AttendanceState.fromMap(Map<String, dynamic> map) {
    return AttendanceState(
      isClockedIn: map['isClockedIn'] as bool? ?? false,
      lastAction: map['lastAction'] as String? ?? 'No record',
    );
  }
}
