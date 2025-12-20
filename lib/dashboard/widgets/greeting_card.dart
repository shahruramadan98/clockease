import 'package:flutter/material.dart';
import '../../models/user_profile.dart';

class GreetingCard extends StatelessWidget {
  final UserProfile? profile;

  const GreetingCard({
    super.key,
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final hour = now.hour;

    final greeting = hour < 12
        ? "Good Morning"
        : hour < 17
            ? "Good Afternoon"
            : "Good Evening";

    final date =
        "${_weekday(now.weekday)}, ${now.day} ${_month(now.month)}";

    final formattedTime = _formatTime(now);

    final name = profile?.fullName ?? "User";

    return _buildCard(greeting, name, date, formattedTime);
  }
}

// =========================
// UI CARD
// =========================
Widget _buildCard(
  String greeting,
  String name,
  String date,
  String time,
) {
  return Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      gradient: const LinearGradient(
        colors: [Color(0xFF4CBFDA), Color(0xFF3BAECC)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "$greeting, $name!",
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),

              // DATE
              Text(
                date,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),

              // TIME
              Text(
                time,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),

        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: const [
            Icon(Icons.wb_sunny, color: Colors.white, size: 30),
            SizedBox(height: 6),
            Text(
              "30°C",
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              "Johor Bahru",
              style: TextStyle(
                fontSize: 13,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

// =========================
// HELPERS
// =========================
String _weekday(int weekday) {
  const names = [
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday",
    "Saturday",
    "Sunday"
  ];
  return names[weekday - 1];
}

String _month(int month) {
  const names = [
    "January",
    "February",
    "March",
    "April",
    "May",
    "June",
    "July",
    "August",
    "September",
    "October",
    "November",
    "December"
  ];
  return names[month - 1];
}

String _formatTime(DateTime time) {
  final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
  final minute = time.minute.toString().padLeft(2, '0');
  final suffix = time.hour >= 12 ? "PM" : "AM";
  return "$hour:$minute $suffix";
}
