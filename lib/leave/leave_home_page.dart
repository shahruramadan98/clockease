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
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Leave Application",
          style: TextStyle(color: Color(0xFF3F51B5)), // Apply color to text
        ),
        backgroundColor: Colors.white, // Set background to white
        elevation: 0, // Remove shadow for a clean look
        actions: [
          IconButton(
            icon: Icon(
              Icons.notifications,
              color: Color(0xFF3F51B5), // Change icon color to match text
            ),
            onPressed: () {
              // Handle notifications if any
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _leaveService.getUserLeaves(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }

          final leaves = snapshot.data!;
          final now = DateTime.now();

          // Calculate leave balances
          int usedAnnual = 0;
          int usedSick = 0;

          // Categorize leaves
          final List<Map<String, dynamic>> upcomingLeaves = [];
          final List<Map<String, dynamic>> pendingLeaves = [];
          final List<Map<String, dynamic>> pastLeaves = [];

          for (var leave in leaves) {
            final startDate = (leave['startDate'] as Timestamp).toDate();
            final endDate = (leave['endDate'] as Timestamp).toDate();
            final status = leave['status'] as String;
            final days = calculateDays(startDate, endDate);

            // Calculate used leave days
            if (status == 'approved') {
              if (leave['leaveType'] == 'Annual') usedAnnual += days;
              if (leave['leaveType'] == 'Sick') usedSick += days;
            }

            // Categorize leaves
            if (status == 'pending') {
              pendingLeaves.add(leave);
            } else if (status == 'approved' && endDate.isAfter(now.subtract(const Duration(days: 1)))) {
              upcomingLeaves.add(leave);
            } else if ((status == 'approved' || status == 'rejected') && 
                       endDate.isBefore(now.subtract(const Duration(days: 1)))) {
              pastLeaves.add(leave);
            }
          }

          // Sort upcoming by start date (earliest first)
          upcomingLeaves.sort((a, b) {
            final aDate = (a['startDate'] as Timestamp).toDate();
            final bDate = (b['startDate'] as Timestamp).toDate();
            return aDate.compareTo(bDate);
          });

          // Sort past by end date (most recent first)
          pastLeaves.sort((a, b) {
            final aDate = (a['endDate'] as Timestamp).toDate();
            final bDate = (b['endDate'] as Timestamp).toDate();
            return bDate.compareTo(aDate);
          });

          final remainingAnnual = annualTotal - usedAnnual;
          final remainingSick = sickTotal - usedSick;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Leave Balances Section
                  _buildLeaveBalancesSection(remainingAnnual, remainingSick),

                  const SizedBox(height: 20),

                  // Upcoming Leave Section
                  _buildUpcomingLeaveSection(upcomingLeaves),

                  const SizedBox(height: 20),

                  // Pending Requests Section
                  _buildPendingLeaveSection(pendingLeaves),

                  const SizedBox(height: 20),

                  // Past Leave Section
                  _buildPastLeaveSection(pastLeaves),

                  const SizedBox(height: 80), // Add bottom padding for FAB
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const LeaveApplicationForm(),
            ),
          );
        },
        backgroundColor: const Color(0xFF3BAECC),
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),

    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLeaveBalancesSection(annualTotal, sickTotal),
            const SizedBox(height: 20),
            _buildUpcomingLeaveSection([]),
            const SizedBox(height: 20),
            _buildPendingLeaveSection([]),
            const SizedBox(height: 20),
            _buildPastLeaveSection([]),
            const SizedBox(height: 80), // Add bottom padding for FAB
          ],

        ),
      ),
    );
  }


  // Leave Balances Section
  Widget _buildLeaveBalancesSection(int remainingAnnual, int remainingSick) {
    return Card(
      elevation: 6,
      color: const Color(0xFF3BAECC),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Leave Balances",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            // Annual Leave Progress Bar
            _buildLeaveBalanceCard(
              "Annual Leave",
              remainingAnnual,
              remainingAnnual / annualTotal,
              true,
            ),
            const SizedBox(height: 10),
            // Line separator between the sections
            Divider(
              color: Colors.white.withOpacity(0.5),
            ),
            // Sick Leave and Unpaid Leave without progress bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildLeaveBalanceCard("Sick Leave", remainingSick, 0.0, false),
                _buildLeaveBalanceCard("Unpaid Leave", 0, 0.0, false),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaveBalanceCard(String leaveType, int daysLeft, double progress, bool showProgress) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            leaveType,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            "$daysLeft days",
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 4),
          if (showProgress)
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 8.0,
            ),
        ],
      ),
    );
  }


  // Upcoming Leave Section
  Widget _buildUpcomingLeaveSection(List<Map<String, dynamic>> upcomingLeaves) {
    if (upcomingLeaves.isEmpty) {
      return _buildEmptySectionCard("Upcoming Leave", "No upcoming leave");
    }

    final nextLeave = upcomingLeaves.first;
    final leaveType = nextLeave['leaveType'] as String;
    final startDate = (nextLeave['startDate'] as Timestamp).toDate();
    final endDate = (nextLeave['endDate'] as Timestamp).toDate();
    
    final dateStr = startDate.day == endDate.day && 
                    startDate.month == endDate.month && 
                    startDate.year == endDate.year
        ? _formatDate(startDate)
        : '${_formatDate(startDate)} - ${_formatDate(endDate)}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Upcoming Leave",
            style: TextStyle(color: Color(0xFF3BAECC), fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 90,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF6BD5E1),
                    Color(0xFF3A7BD5),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          leaveType,
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dateStr,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      "Approved",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }



  // Pending Leave Section
  Widget _buildPendingLeaveSection(List<Map<String, dynamic>> pendingLeaves) {
    if (pendingLeaves.isEmpty) {
      return _buildEmptySectionCard("Pending Requests", "No pending requests");
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Pending Requests",
                style: TextStyle(color: Color(0xFF3BAECC), fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Color(0xFFB0F39A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "${pendingLeaves.length}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...pendingLeaves.map((leave) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildPendingLeaveCard(leave),
          )),
        ],
      ),
    );
  }

  Widget _buildPendingLeaveCard(Map<String, dynamic> leave) {
    final leaveType = leave['leaveType'] as String;
    final startDate = (leave['startDate'] as Timestamp).toDate();
    final endDate = (leave['endDate'] as Timestamp).toDate();
    final leaveId = leave['id'] as String;
    
    final dateStr = startDate.day == endDate.day && 
                    startDate.month == endDate.month && 
                    startDate.year == endDate.year
        ? _formatDate(startDate)
        : '${_formatDate(startDate)} - ${_formatDate(endDate)}';

    return SizedBox(
      width: double.infinity,
      height: 90,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: const LinearGradient(
            colors: [
              Color(0xFF6BD5E1),
              Color(0xFF3A7BD5),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    leaveType,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateStr,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Color(0xFFB0F39A),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    "Pending",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => _showDeleteConfirmation(leaveId, leaveType, dateStr),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.delete_outline,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Past Leave Section
  Widget _buildPastLeaveSection(List<Map<String, dynamic>> pastLeaves) {
    if (pastLeaves.isEmpty) {
      return _buildEmptySectionCard("Past Leave", "No past leave");
    }

    final recentPast = pastLeaves.first;
    final leaveType = recentPast['leaveType'] as String;
    final startDate = (recentPast['startDate'] as Timestamp).toDate();
    final endDate = (recentPast['endDate'] as Timestamp).toDate();
    final status = recentPast['status'] as String;
    
    final dateStr = startDate.day == endDate.day && 
                    startDate.month == endDate.month && 
                    startDate.year == endDate.year
        ? _formatDate(startDate)
        : '${_formatDate(startDate)} - ${_formatDate(endDate)}';

    final statusText = status == 'approved' ? 'Taken' : 'Rejected';
    final statusColor = status == 'approved' ? Colors.grey : Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Past Leave",
            style: TextStyle(color: Color(0xFF3BAECC), fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 90,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF6BD5E1),
                    Color(0xFF3A7BD5),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          leaveType,
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dateStr,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      statusText,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method for empty section cards
  Widget _buildEmptySectionCard(String title, String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(color: Color(0xFF3BAECC), fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            height: 90,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey.shade200,
            ),
            child: Center(
              child: Text(
                message,
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Delete confirmation dialog
  void _showDeleteConfirmation(String leaveId, String leaveType, String dateStr) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
              const SizedBox(width: 12),
              const Text(
                "Delete Leave?",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Are you sure you want to delete this leave request?",
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      leaveType,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateStr,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                "Cancel",
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await _deleteLeave(leaveId);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );
  }

  // Delete leave from Firestore
  Future<void> _deleteLeave(String leaveId) async {
    try {
      await FirebaseFirestore.instance
          .collection('leave_applications')
          .doc(leaveId)
          .delete();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Leave request deleted successfully"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to delete: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}