import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/attendance_record.dart';
import '../services/firestore_service.dart';

final attendanceProvider = StreamProvider.autoDispose<List<AttendanceRecord>>((ref) {
  final firestore = ref.watch(firestoreServiceProvider);
  return firestore.getAttendanceStream();
});
