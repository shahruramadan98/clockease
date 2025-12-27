import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../controllers/user_provider.dart';
import '../attendance/attendance_management_page.dart';
import 'widgets/greeting_card.dart';
import 'widgets/quick_action_card.dart';

class AdminDashboard extends ConsumerWidget {
  final String companyId;

  const AdminDashboard({
    super.key,
    required this.companyId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final today = DateTime.now().toString().split(' ')[0];

    return SafeArea(
      child: user.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (_, __) =>
            const Center(child: Text("Failed to load admin data")),
        data: (_) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ==========================
                // GREETING
                // ==========================
                const GreetingCard(),
                const SizedBox(height: 20),

                // ==========================
                // COMPANY OVERVIEW
                // ==========================
                _companyOverviewCard(companyId, today),
                const SizedBox(height: 30),

                // ==========================
                // QUICK ACTIONS
                // ==========================
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
                  children: [
                    Expanded(
                      child: QuickActionCard(
                        title: "Approve Leave",
                        subtitle: "Pending requests",
                        icon: Icons.approval,
                        onTap: () {
                          // TO DO
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: QuickActionCard(
                        title: "Add Staff",
                        subtitle: "Create staff account",
                        icon: Icons.person_add,
                        onTap: () {
                          // TO DO
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: QuickActionCard(
                        title: "Attendance",
                        subtitle: "View all staff",
                        icon: Icons.list_alt,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AttendanceManagementPage(
                                companyId: companyId,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: QuickActionCard(
                        title: "Company Setup",
                        subtitle: "Policies & settings",
                        icon: Icons.business,
                        onTap: () {
                          // TODO: Navigate to Company Setup
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  // ================== COMPONENTS ==================

  Widget _companyOverviewCard(String companyId, String today) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF4FC3F7),
            Color(0xFF42A5F5),
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _overviewItem(
            title: "Total Staff",
            stream: FirebaseFirestore.instance
                .collection('companies')
                .doc(companyId)
                .collection('employees')
                .snapshots(),
          ),

          _overviewItem(
            title: "Present Today",
            stream: FirebaseFirestore.instance
                .collection('companies')
                .doc(companyId)
                .collection('attendance')
                .where('date', isEqualTo: today)
                .snapshots(),
          ),

          // ✅ FIXED: Pending Leave (ROOT COLLECTION)
          _overviewItem(
            title: "Pending Leave",
            stream: FirebaseFirestore.instance
                .collection('leave_applications')
                .where('companyId', isEqualTo: companyId)
                .where('status', isEqualTo: 'pending')
                .snapshots(),
          ),
        ],
      ),
    );
  }

  Widget _overviewItem({
    required String title,
    required Stream<QuerySnapshot> stream,
  }) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        final count =
            snapshot.hasData ? snapshot.data!.docs.length : 0;

        return Column(
          children: [
            Text(
              count.toString(),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        );
      },
    );
  }
}
