import 'package:flutter/material.dart';
import '../../models/attendance_status.dart';

class AttendanceCard extends StatelessWidget {
  final String date;
  final String shift;
  final String breakTime;
  final String totalHours;
  final String lastAction;
  final AttendanceStatus status;
  final Duration lateDuration;

  const AttendanceCard({
    super.key,
    required this.date,
    required this.shift,
    required this.breakTime,
    required this.totalHours,
    required this.lastAction,
    required this.status,
    required this.lateDuration,
  });

  @override
  Widget build(BuildContext context) {
    // Status badge UI
    String badgeText = "";
    Color badgeColor = Colors.green;

    switch (status) {
      case AttendanceStatus.onTime:
        badgeText = "On Time";
        badgeColor = Colors.green;
        break;

      case AttendanceStatus.late:
        badgeText = "Late ${lateDuration.inMinutes} mins";
        badgeColor = Colors.red;
        break;

      case AttendanceStatus.halfDay:
        badgeText = "Half Day";
        badgeColor = Colors.orange;
        break;

      case AttendanceStatus.absent:
        badgeText = "Absent";
        badgeColor = Colors.black87;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF4CBFDA),
            Color(0xFF3BAECC),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 3),
          )
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // TOP ROW: Last out & badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Last Out: $lastAction",
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badgeText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Date
          Text(
            "Date: $date",
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 6),

          // Shift display
          Text(
            shift,
            style: const TextStyle(
              fontSize: 22,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          // Additional details
          Text(
            "Break Time: $breakTime",
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),

          Text(
            "Total: $totalHours",
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}
