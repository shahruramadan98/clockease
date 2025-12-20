import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../controllers/dashboard_controller.dart';
import '../controllers/user_provider.dart';
import '../login_page.dart';

import 'widgets/greeting_card.dart';
import 'widgets/clock_card.dart';
import 'widgets/quick_action_card.dart';

class Dashboard extends ConsumerWidget {
  const Dashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);


    return Scaffold(
      // backgroundColor: Use theme default

      // ===========================
      // 🔥 ADDED LOGOUT BUTTON HERE
      // ===========================
      appBar: AppBar(
        title: const Text("ClockEase"),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                );
              }
            },
          ),
        ],
      ),

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
                      // color: Use theme default
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

                  Center(
                    child: Text(
                      "View today’s attendance details →",
                      style: TextStyle(
                        fontSize: 15,
                        color: Theme.of(context).colorScheme.primary,
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
