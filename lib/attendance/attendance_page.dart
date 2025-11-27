import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/attendance_controller.dart';
import 'widgets/attendance_card.dart';
import '../models/attendance_status.dart';

class AttendancePage extends ConsumerWidget {
  const AttendancePage({super.key});

  String _formatTime(DateTime t) {
    final hour = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final minute = t.minute.toString().padLeft(2, '0');
    final suffix = t.hour >= 12 ? "PM" : "AM";
    return "$hour:$minute $suffix";
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes % 60;
    return "${hours}h ${minutes}m";
  }

  String _formatHours(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return "${h}h ${m}m";
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attendanceState = ref.watch(attendanceProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF4CBFDA),
        elevation: 0,
        title: const Text(
          "ClockEase",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),

      body: attendanceState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("Failed to load: $e")),
        data: (records) {
          if (records.isEmpty) {
            return const Center(child: Text("No attendance records yet"));
          }

          final now = DateTime.now();

          // Filter: current month only
          final thisMonthRecords = records.where((r) =>
              r.date.year == now.year && r.date.month == now.month).toList();

          // Total working minutes this month
          final totalMinutes = thisMonthRecords.fold(
            0,
            (sum, r) => sum + r.totalHours.inMinutes,
          );

          // Count statuses
          final onTimeCount = thisMonthRecords
              .where((r) => r.status == AttendanceStatus.onTime)
              .length;

          final lateCount = thisMonthRecords
              .where((r) => r.status == AttendanceStatus.late)
              .length;

          final halfDayCount = thisMonthRecords
              .where((r) => r.status == AttendanceStatus.halfDay)
              .length;

          final absentCount = thisMonthRecords
              .where((r) => r.status == AttendanceStatus.absent)
              .length;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // PAGE TITLE
                const Text(
                  "Attendance History",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF3F51B5),
                  ),
                ),

                const SizedBox(height: 16),

                // MONTHLY SUMMARY TITLE
                const Text(
                  "Monthly Summaries",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF3F51B5),
                  ),
                ),

                const SizedBox(height: 12),

                // SUMMARY BOXES
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      SummaryBox(
                        title: "Total Hours",
                        value: _formatHours(totalMinutes),
                      ),
                      const SizedBox(width: 10),
                      SummaryBox(
                        title: "On Time",
                        value: "$onTimeCount days",
                      ),
                      const SizedBox(width: 10),
                      SummaryBox(
                        title: "Late",
                        value: "$lateCount days",
                      ),
                      const SizedBox(width: 10),
                      SummaryBox(
                        title: "Half Day",
                        value: "$halfDayCount days",
                      ),
                      const SizedBox(width: 10),
                      SummaryBox(
                        title: "Absent",
                        value: "$absentCount days",
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                const Text(
                  "Daily Attendance",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF3F51B5),
                  ),
                ),

                const SizedBox(height: 16),

                // LIST OF ATTENDANCE CARDS
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: records.length,
                  itemBuilder: (context, index) {
                    final r = records[index];

                    return AttendanceCard(
                      date: r.dateString,
                      shift: "8AM - 5PM",
                      breakTime: "1h",
                      totalHours: _formatDuration(r.totalHours),
                      lastAction: r.clockOut != null
                          ? _formatTime(r.clockOut!)
                          : "--",
                      status: r.status,
                      lateDuration: r.lateDuration,
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class SummaryBox extends StatelessWidget {
  final String title;
  final String value;

  const SummaryBox({
    super.key,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      width: 110,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF4CBFDA), Color(0xFF6BC5F8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
