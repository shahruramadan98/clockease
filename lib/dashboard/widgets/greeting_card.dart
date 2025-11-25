import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../controllers/user_provider.dart';

class GreetingCard extends ConsumerWidget {
  const GreetingCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userData = ref.watch(userProvider);

    final now = DateTime.now();
    final hour = now.hour;

    final greeting = hour < 12
        ? "Good Morning"
        : hour < 17
            ? "Good Afternoon"
            : "Good Evening";

    final date =
        "${_weekday(now.weekday)}, ${now.day} ${_month(now.month)}";

    return userData.when(
      loading: () => _buildCard(greeting, "Loading...", date),
      error: (_, __) => _buildCard(greeting, "User", date),
      data: (user) => _buildCard(greeting, user?.fullName ?? "User", date),
    );
  }
}

Widget _buildCard(String greeting, String name, String date) {
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
              Text(
                date,
                style: const TextStyle(fontSize: 14, color: Colors.white),
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

String _weekday(int weekday) {
  const names = [
    "Monday", "Tuesday", "Wednesday",
    "Thursday", "Friday", "Saturday", "Sunday"
  ];
  return names[weekday - 1];
}

String _month(int month) {
  const names = [
    "January","February","March","April","May","June",
    "July","August","September","October","November","December"
  ];
  return names[month - 1];
}
