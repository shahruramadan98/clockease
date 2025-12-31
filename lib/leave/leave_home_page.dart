import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../services/leave_service.dart';
import '../services/company_settings_service.dart';
import '../services/user_service.dart';

import '../models/leave_policy.dart';

import 'leave_application_form.dart';

class LeavePage extends StatefulWidget {
  const LeavePage({super.key});

  @override
  State<LeavePage> createState() => _LeavePageState();
}

class _LeavePageState extends State<LeavePage> with SingleTickerProviderStateMixin {
  final LeaveService _leaveService = LeaveService();
  final CompanySettingsService _settingsService = CompanySettingsService();
  final UserService _userService = UserService();
  final DateFormat dateFormatter = DateFormat('dd/MM/yyyy');
  late TabController _tabController;

  LeavePolicy? _leavePolicy;
  bool _policyLoading = true;
  bool _isHalfDay(Map<String, dynamic> leave) {
    final duration = (leave['durationDays'] as num?)?.toDouble() ?? 0;
    return duration == 0.5;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadLeavePolicy();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    if (_policyLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final annualTotal = _leavePolicy?.annualLeave ?? 0;
    final sickTotal = _leavePolicy?.sickLeave ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Leave Application",
          style: TextStyle(color: Color(0xFF3F51B5), fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),

      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _leaveService.getUserLeaves(),
        builder: (context, snapshot) {
          // Only show loading when waiting AND we don't have previous data
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          // Show error if stream has error
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                ],
              ),
            );
          }

          final leaves = snapshot.data ?? [];

          final now = DateTime.now();

          double usedAnnual = 0.0;
          double usedSick = 0.0;

          final upcomingLeaves = <Map<String, dynamic>>[];
          final pendingLeaves = <Map<String, dynamic>>[];
          final pastLeaves = <Map<String, dynamic>>[];

          for (final leave in leaves) {
          //final startDate = (leave['startDate'] as Timestamp).toDate();
          final endDate = (leave['endDate'] as Timestamp).toDate();
          final status = leave['status'] as String;

          double duration = 0.0;

          // New system (preferred)
          if (leave.containsKey('durationDays')) {
            duration = (leave['durationDays'] as num).toDouble();
          } 
          // Old system fallback
          else {
            final startDate = (leave['startDate'] as Timestamp).toDate();
            final endDate = (leave['endDate'] as Timestamp).toDate();
            duration = endDate.difference(startDate).inDays + 1;
          }

          if (status == 'approved') {
            if (leave['leaveType'] == 'Annual') usedAnnual += duration;
            if (leave['leaveType'] == 'Sick') usedSick += duration;
          }

          if (status == 'pending') {
            pendingLeaves.add(leave);
          } else if (status == 'approved' &&
              endDate.isAfter(now.subtract(const Duration(days: 1)))) {
            upcomingLeaves.add(leave);
          } else {
            pastLeaves.add(leave);
          }
        }

          upcomingLeaves.sort((a, b) =>
              (a['startDate'] as Timestamp)
                  .toDate()
                  .compareTo((b['startDate'] as Timestamp).toDate()));

          pastLeaves.sort((a, b) =>
              (b['endDate'] as Timestamp)
                  .toDate()
                  .compareTo((a['endDate'] as Timestamp).toDate()));

          final remainingAnnual = (annualTotal - usedAnnual).clamp(0, annualTotal).toDouble();
          final remainingSick = (sickTotal - usedSick).clamp(0, sickTotal).toDouble();

          return Column(
            children: [
              // Leave Balances Section
              Padding(
                padding: const EdgeInsets.all(16),
                child: _buildLeaveBalancesSection(
                  remainingAnnual,
                  remainingSick,
                  annualTotal,
                  sickTotal,
                ),
              ),

              // Tab Bar
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    color: const Color(0xFF3BAECC),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.grey.shade700,
                  tabs: const [
                    Tab(text: 'Upcoming'),
                    Tab(text: 'Pending'),
                    Tab(text: 'Past'),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Tab Bar View
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildUpcomingTab(upcomingLeaves),
                    _buildPendingTab(pendingLeaves),
                    _buildPastTab(pastLeaves),
                  ],
                ),
              ),
            ],
          );
        },
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF3BAECC),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const LeaveApplicationForm(),
            ),
          );
        },
      ),
    );
  }

  // =============================
  // TAB BUILDERS
  // =============================
  Widget _buildUpcomingTab(List<Map<String, dynamic>> leaves) {
    if (leaves.isEmpty) {
      return _buildEmptyTabState(
        icon: Icons.event_available,
        message: "No upcoming leave",
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: leaves.length,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _buildUpcomingLeaveCard(leaves[index]),
      ),
    );
  }

  Widget _buildPendingTab(List<Map<String, dynamic>> leaves) {
    if (leaves.isEmpty) {
      return _buildEmptyTabState(
        icon: Icons.pending_actions,
        message: "No pending requests",
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: leaves.length,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _buildPendingLeaveCard(leaves[index]),
      ),
    );
  }

  Widget _buildPastTab(List<Map<String, dynamic>> leaves) {
    if (leaves.isEmpty) {
      return _buildEmptyTabState(
        icon: Icons.history,
        message: "No past leave",
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: leaves.length,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _buildPastLeaveCard(leaves[index]),
      ),
    );
  }

  Widget _buildEmptyTabState({required IconData icon, required String message}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  // =============================
  // LEAVE BALANCES
  // =============================
  Widget _buildLeaveBalancesSection(
    double remainingAnnual,
    double remainingSick,
    int annualTotal,
    int sickTotal,
    ) {
    return Card(
      color: const Color(0xFF3BAECC),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Leave Balances",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _balanceItem(
              "Annual Leave",
              remainingAnnual,
              annualTotal == 0 ? 0 : remainingAnnual / annualTotal,
            ),
            const SizedBox(height: 10),
            Divider(color: Colors.white.withOpacity(0.5)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _simpleBalance("Sick Leave", remainingSick),
                _simpleBalance("Unpaid Leave", 0),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _balanceItem(String label, double days, double progress) {
    final displayDays =
        days % 1 == 0 ? days.toInt().toString() : days.toStringAsFixed(1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "$label ($displayDays days)",
          style: const TextStyle(color: Colors.white),
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: progress.clamp(0.0, 1.0),
          backgroundColor: Colors.white24,
          valueColor: const AlwaysStoppedAnimation(Colors.white),
        ),
      ],
    );
  }

  Widget _simpleBalance(String label, double days) {
    final displayDays =
        days % 1 == 0 ? days.toInt().toString() : days.toStringAsFixed(1);

    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white)),
        const SizedBox(height: 4),
        Text("$displayDays days",
            style: const TextStyle(color: Colors.white)),
      ],
    );
  }

  // =============================
  // LEAVE CARD BUILDERS
  // =============================
  Widget _buildUpcomingLeaveCard(Map<String, dynamic> leave) {
    final leaveType = leave['leaveType'];
    final start = (leave['startDate'] as Timestamp).toDate();
    final end = (leave['endDate'] as Timestamp).toDate();

    final date = start == end
        ? _formatDate(start)
        : "${_formatDate(start)} - ${_formatDate(end)}";

    return Container(
      height: 90,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: const LinearGradient(
          colors: [Color(0xFF6BD5E1), Color(0xFF3A7BD5)],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Text(
                    leaveType,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_isHalfDay(leave)) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        "½ Day",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(date, style: const TextStyle(color: Colors.white)),
            ],
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              "Approved",
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingLeaveCard(Map<String, dynamic> leave) {
    final leaveType = leave['leaveType'];
    final start = (leave['startDate'] as Timestamp).toDate();
    final end = (leave['endDate'] as Timestamp).toDate();
    final leaveId = leave['id'];

    final date = start == end
        ? _formatDate(start)
        : "${_formatDate(start)} - ${_formatDate(end)}";

    return Container(
      height: 90,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: const LinearGradient(
          colors: [Color(0xFF6BD5E1), Color(0xFF3A7BD5)],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Text(
                    leaveType,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_isHalfDay(leave)) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        "½ Day",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(date, style: const TextStyle(color: Colors.white)),
            ],
          ),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  "Pending",
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () =>
                    _showDeleteConfirmation(leaveId, leaveType, date),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPastLeaveCard(Map<String, dynamic> leave) {
    final leaveType = leave['leaveType'];
    final start = (leave['startDate'] as Timestamp).toDate();
    final end = (leave['endDate'] as Timestamp).toDate();
    final status = leave['status'] == 'approved' ? "Taken" : "Rejected";
    final color = leave['status'] == 'approved' ? Colors.grey : Colors.red;

    final date = start == end
        ? _formatDate(start)
        : "${_formatDate(start)} - ${_formatDate(end)}";

    return Container(
      height: 90,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: const LinearGradient(
          colors: [Color(0xFF6BD5E1), Color(0xFF3A7BD5)],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Text(
                    leaveType,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_isHalfDay(leave)) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        "½ Day",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(date, style: const TextStyle(color: Colors.white)),
            ],
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteConfirmation(
      String id, String type, String date) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Leave"),
        content: Text("Delete $type ($date)?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('leave_applications')
          .doc(id)
          .delete();
    }
  }

  Future<void> _loadLeavePolicy() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final companyId = await _userService.getCompanyIdForUser(user.uid);
    if (companyId == null) return;

    final policy = await _settingsService.getLeavePolicy(companyId);

    if (!mounted) return;

    setState(() {
      _leavePolicy = policy;
      _policyLoading = false;
    });
  }

}
