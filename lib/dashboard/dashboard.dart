import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/dashboard_controller.dart';
import '../controllers/user_provider.dart';

import 'widgets/greeting_card.dart';
import 'widgets/clock_card.dart';
import 'widgets/quick_action_card.dart';

class Dashboard extends ConsumerWidget {
  const Dashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final attendance = ref.watch(dashboardProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: user.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Center(child: Text("Failed to load user")),
          data: (_) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const GreetingCard(),

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
                      Expanded(
                        child: QuickActionCard(
                          title: "Today’s Schedule",
                          subtitle: "Daily Standup: 09:00 AM",
                          icon: Icons.calendar_month,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: QuickActionCard(
                          title: "Leave Balance",
                          subtitle: "Annual: 15 days",
                          icon: Icons.eco,
                        ),
                      ),
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
            );
          },
        ),
      ),
    );
  }
}
