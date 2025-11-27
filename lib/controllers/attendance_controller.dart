import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/attendance_record.dart';
import '../services/firestore_service.dart';

final attendanceProvider = StateNotifierProvider<
    AttendanceController, AsyncValue<List<AttendanceRecord>>>(
  (ref) => AttendanceController(ref),
);

class AttendanceController
    extends StateNotifier<AsyncValue<List<AttendanceRecord>>> {
  final Ref ref;

  AttendanceController(this.ref) : super(const AsyncLoading()) {
    loadAttendance();
  }

  Future<void> loadAttendance() async {
    try {
      final data =
          await ref.read(firestoreServiceProvider).fetchAttendanceList();
      state = AsyncValue.data(data);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);

    }
  }
}
