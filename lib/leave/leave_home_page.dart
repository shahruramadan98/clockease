import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/leave_service.dart';
import 'leave_application_form.dart';

class LeavePage extends StatefulWidget {
  const LeavePage({super.key});

  @override
  State<LeavePage> createState() => _LeavePageState();
}

class _LeavePageState extends State<LeavePage> {
  final LeaveService _leaveService = LeaveService();
  final DateFormat dateFormatter = DateFormat('dd/MM/yyyy');

  static const int annualTotal = 15;
  static const int sickTotal = 7;

  int calculateDays(DateTime start, DateTime end) {
    return end.difference(start).inDays + 1;
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
          
          // Only show empty state when we're sure there's no data
          // (not during connection state changes)
          if (leaves.isEmpty && snapshot.connectionState != ConnectionState.waiting) {
            return _buildEmptyState();
          }

          final now = DateTime.now();

          int usedAnnual = 0;
          int usedSick = 0;

          final upcomingLeaves = <Map<String, dynamic>>[];
          final pendingLeaves = <Map<String, dynamic>>[];
          final pastLeaves = <Map<String, dynamic>>[];

          for (final leave in leaves) {
            final startDate = (leave['startDate'] as Timestamp).toDate();
            final endDate = (leave['endDate'] as Timestamp).toDate();
            final status = leave['status'] as String;
            final days = calculateDays(startDate, endDate);

            if (status == 'approved') {
              if (leave['leaveType'] == 'Annual') usedAnnual += days;
              if (leave['leaveType'] == 'Sick') usedSick += days;
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

          final remainingAnnual = annualTotal - usedAnnual;
          final remainingSick = sickTotal - usedSick;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLeaveBalancesSection(remainingAnnual, remainingSick),
                const SizedBox(height: 20),
                _buildUpcomingLeaveSection(upcomingLeaves),
                const SizedBox(height: 20),
                _buildPendingLeaveSection(pendingLeaves),
                const SizedBox(height: 20),
                _buildPastLeaveSection(pastLeaves),
                const SizedBox(height: 80),
              ],
            ),
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
  // EMPTY STATE
  // =============================
  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildLeaveBalancesSection(annualTotal, sickTotal),
          const SizedBox(height: 20),
          _buildEmptySection("Upcoming Leave", "No upcoming leave"),
          const SizedBox(height: 20),
          _buildEmptySection("Pending Requests", "No pending requests"),
          const SizedBox(height: 20),
          _buildEmptySection("Past Leave", "No past leave"),
        ],
      ),
    );
  }

  // =============================
  // LEAVE BALANCES
  // =============================
  Widget _buildLeaveBalancesSection(int annual, int sick) {
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
            _balanceItem("Annual Leave", annual, annual / annualTotal),
            const SizedBox(height: 10),
            Divider(color: Colors.white.withOpacity(0.5)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _simpleBalance("Sick Leave", sick),
                _simpleBalance("Unpaid Leave", 0),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _balanceItem(String label, int days, double progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("$label ($days days)",
            style: const TextStyle(color: Colors.white)),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: progress.clamp(0, 1),
          backgroundColor: Colors.white24,
          valueColor: const AlwaysStoppedAnimation(Colors.white),
        ),
      ],
    );
  }

  Widget _simpleBalance(String label, int days) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white)),
        const SizedBox(height: 4),
        Text("$days days", style: const TextStyle(color: Colors.white)),
      ],
    );
  }

  // =============================
  // UPCOMING
  // =============================
  Widget _buildUpcomingLeaveSection(List<Map<String, dynamic>> leaves) {
    if (leaves.isEmpty) {
      return _buildEmptySection("Upcoming Leave", "No upcoming leave");
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Upcoming Leave",
          style: TextStyle(
            color: Color(0xFF3BAECC),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        ...leaves.map((leave) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildUpcomingLeaveCard(leave),
          );
        }),
      ],
    );
  }

  // =============================
  // PENDING (with delete)
  // =============================
  Widget _buildPendingLeaveSection(List<Map<String, dynamic>> leaves) {
    if (leaves.isEmpty) {
      return _buildEmptySection("Pending Requests", "No pending requests");
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Pending Requests",
          style: TextStyle(
            color: Color(0xFF3BAECC),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        ...leaves.map((leave) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildPendingLeaveCard(leave),
          );
        }),
      ],
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
              Text(leaveType,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold)),
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
              Text(leaveType,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold)),
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
              Text(leaveType,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold)),
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

  // =============================
  // PAST
  // =============================
  Widget _buildPastLeaveSection(List<Map<String, dynamic>> leaves) {
    if (leaves.isEmpty) {
      return _buildEmptySection("Past Leave", "No past leave");
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Past Leave",
          style: TextStyle(
            color: Color(0xFF3BAECC),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        ...leaves.map((leave) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildPastLeaveCard(leave),
          );
        }),
      ],
    );
  }


  Widget _buildEmptySection(String title, String text) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
              color: Color(0xFF3BAECC),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            )),
        const SizedBox(height: 10),
        Container(
          height: 90,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(text, style: const TextStyle(color: Colors.grey)),
        ),
      ],
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
}
