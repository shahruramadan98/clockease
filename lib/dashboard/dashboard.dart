import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/profile_controller.dart';
import 'widgets/greeting_card.dart';
import 'widgets/clock_card.dart';
import 'widgets/quick_action_card.dart';

class Dashboard extends ConsumerWidget {
  final Function(int)? onNavigateToTab;
  
  const Dashboard({super.key, this.onNavigateToTab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);

    return profileAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const Scaffold(
        body: Center(child: Text("Failed to load user")),
      ),
      data: (profile) {
        return Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🔹 Greeting Card (now reactive)
                  GreetingCard(profile: profile),
                  const SizedBox(height: 20),

                  const ClockCard(),
                  const SizedBox(height: 25),

                  const Text(
                    "Quick Actions",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      // color: Use theme default
                    ),
                  ),
                  const SizedBox(height: 15),

                  Row(
                    children: [
                      Expanded(
                        child: QuickActionCard(
                          title: "Today’s Schedule",
                          subtitle: "Daily Standup: 09:00 AM",
                          icon: Icons.calendar_month,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: QuickActionCard(
                          title: "Leave Balance",
                          subtitle: "Annual: 15 days",
                          icon: Icons.eco,
                          onTap: () {
                            // Navigate to Leaves page (index 1)
                            onNavigateToTab?.call(1);
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  Center(
                    child: GestureDetector(
                      onTap: () {
                        // Navigate to Attendance page (index 0)
                        onNavigateToTab?.call(0);
                      },
                      child: Text(
                        "View today’s attendance details →",
                        style: TextStyle(
                          fontSize: 15,
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
