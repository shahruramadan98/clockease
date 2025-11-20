import 'package:flutter/material.dart';
import 'widgets/greeting_card.dart';
import 'widgets/clock_card.dart';
import 'widgets/quick_action_card.dart';

class Dashboard extends StatelessWidget {
  final String? userEmail;

  const Dashboard({super.key, this.userEmail});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              GreetingCard(userEmail: userEmail),

              const SizedBox(height: 20),

              const ClockCard(),

              const SizedBox(height: 25),

              const Text(
                "Quick Actions",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 15),

              Row(
                children: const [
                  Expanded(child: QuickActionCard(
                    title: "Today’s Schedule",
                    subtitle: "Daily Standup: 09:00 AM",
                    icon: Icons.calendar_month,
                  )),
                  SizedBox(width: 12),
                  Expanded(child: QuickActionCard(
                    title: "Leave Balance",
                    subtitle: "Annual: 15 days",
                    icon: Icons.eco,
                  )),
                ],
              ),

              const SizedBox(height: 20),

              const Center(
                child: Text(
                  "View today’s attendance details →",
                  style: TextStyle(
                    fontSize: 15,
                    color: Color(0xFF3F51B5),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
