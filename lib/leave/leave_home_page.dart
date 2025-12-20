import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


class LeavePage extends StatelessWidget {
  const LeavePage({super.key});

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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Leave Balances Section
              LeaveBalancesSection(),

              const SizedBox(height: 20),

              // Upcoming Leave Section (Separate Card)
              UpcomingLeaveSection(buildLeaveCard: _buildLeaveCard),

              const SizedBox(height: 20),

              // Pending Requests Section (Separate Card)
              PendingLeaveSection(buildLeaveCard: _buildLeaveCard),

              const SizedBox(height: 20),

              // Past Leave Section (Separate Card)
              PastLeaveSection(buildLeaveCard: _buildLeaveCard),

              const SizedBox(height: 20),

              // Add Floating Action Button for "Apply for Leave"
              Align(
                alignment: Alignment.bottomRight,
                child: FloatingActionButton(
                  onPressed: () {
                    // Navigate to leave application form
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const LeaveApplicationForm()),
                    );
                  },
                  backgroundColor: const Color(0xFF3BAECC), // Blue background
                  child: const Icon(
                    Icons.add,
                    color: Colors.white, // White icon color
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Shared helper method for building leave cards
  Widget _buildLeaveCard(String leaveType, String date, String status, Color statusColor) {
    return Card(
      color: Color(0xFF3BAECC),  // Lighter blue color for leave cards
      child: ListTile(
        title: Text(leaveType, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text(date, style: const TextStyle(color: Colors.white)),
        trailing: Chip(
          label: Text(
            status,
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: statusColor,
        ),
      ),
    );
  }
}


// Leave Balances Section Widget
// Leave Balances Section Widget
class LeaveBalancesSection extends StatelessWidget {
  const LeaveBalancesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      color: const Color(0xFF3BAECC), // Background color of leave balances section
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Leave Balances",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            // Annual Leave Progress Bar
            _buildLeaveBalanceCard("Annual Leave", 15, 0.4, true), // Progress bar here for annual leave

            const SizedBox(height: 10),
            // Line separator between the sections
            Divider(
              color: Colors.white.withOpacity(0.5), // Light white line for separator
            ),

            // Sick Leave and Unpaid Leave without progress bar, aligned next to each other
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildLeaveBalanceCard("Sick Leave", 7, 0.0, false), // No progress bar here
                _buildLeaveBalanceCard("Unpaid Leave", 0, 0.0, false), // No progress bar here
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Widget to build each leave balance card with or without a progress bar
  Widget _buildLeaveBalanceCard(String leaveType, int daysLeft, double progress, bool showProgress) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12), // Adjusted padding
      decoration: BoxDecoration(
        color: Colors.transparent, // No background for each card
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
          // Show progress bar only for Annual Leave
          if (showProgress)
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white), // White color for progress
              minHeight: 8.0,
            ),
        ],
      ),
    );
  }
}


// Upcoming Leave Section Widget (Dynamic - queries Firestore)
class UpcomingLeaveSection extends StatelessWidget {
  final Widget Function(String, String, String, Color) buildLeaveCard;

  const UpcomingLeaveSection({super.key, required this.buildLeaveCard});

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    if (user == null) {
      return _buildEmptyState();
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('leave_applications')
          .where('userId', isEqualTo: user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: const CircularProgressIndicator(),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState();
        }

        final now = DateTime.now();
        final leaves = snapshot.data!.docs.map((doc) {
          return {
            'id': doc.id,
            ...doc.data() as Map<String, dynamic>,
          };
        }).toList();

        // Filter for upcoming approved leaves (startDate >= today)
        final upcomingLeaves = leaves.where((leave) {
          final status = leave['status'] as String;
          final startDate = (leave['startDate'] as Timestamp).toDate();
          return status == 'approved' && startDate.isAfter(now.subtract(const Duration(days: 1)));
        }).toList();

        // Sort by start date (earliest first)
        upcomingLeaves.sort((a, b) {
          final aDate = (a['startDate'] as Timestamp).toDate();
          final bDate = (b['startDate'] as Timestamp).toDate();
          return aDate.compareTo(bDate);
        });

        if (upcomingLeaves.isEmpty) {
          return _buildEmptyState();
        }

        // Show the next upcoming leave
        final nextLeave = upcomingLeaves.first;
        return _buildLeaveCard(nextLeave);
      },
    );
  }

  Widget _buildEmptyState() {
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
                "No upcoming leave",
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaveCard(Map<String, dynamic> leave) {
    final leaveType = leave['leaveType'] as String;
    final startDate = (leave['startDate'] as Timestamp).toDate();
    final endDate = (leave['endDate'] as Timestamp).toDate();
    
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
                    Color(0xFF6BD5E1), // Light aqua
                    Color(0xFF3A7BD5), // Blue
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left side: Leave details
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
                  // Right side: Status chip
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
}


// Pending Leave Section Widget (Dynamic - queries Firestore)
class PendingLeaveSection extends StatelessWidget {
  final Widget Function(String, String, String, Color) buildLeaveCard;

  const PendingLeaveSection({super.key, required this.buildLeaveCard});

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    if (user == null) {
      return _buildEmptyState();
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('leave_applications')
          .where('userId', isEqualTo: user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: const CircularProgressIndicator(),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState();
        }

        final leaves = snapshot.data!.docs.map((doc) {
          return {
            'id': doc.id,
            ...doc.data() as Map<String, dynamic>,
          };
        }).toList();

        // Filter for pending leaves only
        final pendingLeaves = leaves.where((leave) {
          final status = leave['status'] as String;
          return status == 'pending';
        }).toList();

        // Sort by creation date (most recent first)
        pendingLeaves.sort((a, b) {
          final aDate = (a['createdAt'] as Timestamp).toDate();
          final bDate = (b['createdAt'] as Timestamp).toDate();
          return bDate.compareTo(aDate);
        });

        if (pendingLeaves.isEmpty) {
          return _buildEmptyState();
        }

        // Show all pending leaves
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
              // Show all pending leaves
              ...pendingLeaves.map((leave) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildLeaveCard(context, leave),
              )),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Pending Requests",
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
                "No pending requests",
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaveCard(BuildContext context, Map<String, dynamic> leave) {
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
              Color(0xFF6BD5E1), // Light aqua
              Color(0xFF3A7BD5), // Blue
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left side: Leave details
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
            // Right side: Status chip and delete button
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Color(0xFFB0F39A), // Light green for pending
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    "Pending",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),
                // Delete button
                InkWell(
                  onTap: () => _showDeleteConfirmation(context, leaveId, leaveType, dateStr),
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

  // Method to show delete confirmation dialog
  void _showDeleteConfirmation(BuildContext context, String leaveId, String leaveType, String dateStr) {
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
                await _deleteLeave(context, leaveId);
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

  // Method to delete leave from Firestore
  Future<void> _deleteLeave(BuildContext context, String leaveId) async {
    try {
      await FirebaseFirestore.instance
          .collection('leave_applications')
          .doc(leaveId)
          .delete();

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Leave request deleted successfully"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to delete: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}



// Past Leave Section Widget (Dynamic - queries Firestore)
class PastLeaveSection extends StatelessWidget {
  final Widget Function(String, String, String, Color) buildLeaveCard;

  const PastLeaveSection({super.key, required this.buildLeaveCard});

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    if (user == null) {
      return _buildEmptyState();
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('leave_applications')
          .where('userId', isEqualTo: user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: const CircularProgressIndicator(),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState();
        }

        final now = DateTime.now();
        final leaves = snapshot.data!.docs.map((doc) {
          return {
            'id': doc.id,
            ...doc.data() as Map<String, dynamic>,
          };
        }).toList();

        // Filter for past approved/rejected leaves (endDate < today)
        final pastLeaves = leaves.where((leave) {
          final status = leave['status'] as String;
          final endDate = (leave['endDate'] as Timestamp).toDate();
          return (status == 'approved' || status == 'rejected') && 
                 endDate.isBefore(now.subtract(const Duration(days: 1)));
        }).toList();

        // Sort by end date (most recent first)
        pastLeaves.sort((a, b) {
          final aDate = (a['endDate'] as Timestamp).toDate();
          final bDate = (b['endDate'] as Timestamp).toDate();
          return bDate.compareTo(aDate);
        });

        if (pastLeaves.isEmpty) {
          return _buildEmptyState();
        }

        // Show the most recent past leave
        final recentPast = pastLeaves.first;
        return _buildLeaveCard(recentPast);
      },
    );
  }

  Widget _buildEmptyState() {
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
                "No past leave",
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaveCard(Map<String, dynamic> leave) {
    final leaveType = leave['leaveType'] as String;
    final startDate = (leave['startDate'] as Timestamp).toDate();
    final endDate = (leave['endDate'] as Timestamp).toDate();
    final status = leave['status'] as String;
    
    final dateStr = startDate.day == endDate.day && 
                    startDate.month == endDate.month && 
                    startDate.year == endDate.year
        ? _formatDate(startDate)
        : '${_formatDate(startDate)} - ${_formatDate(endDate)}';

    // Status display
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
                    Color(0xFF6BD5E1), // Light aqua
                    Color(0xFF3A7BD5), // Blue
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left side: Leave details
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
                  // Right side: Status chip
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
}


// Leave Application Form Screen
class LeaveApplicationForm extends StatefulWidget {
  const LeaveApplicationForm({super.key});

  @override
  _LeaveApplicationFormState createState() => _LeaveApplicationFormState();
}

class _LeaveApplicationFormState extends State<LeaveApplicationForm> {
  Future<void> submitLeave() async {
    if (selectedLeaveType == null || startDate == null || endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please complete all fields"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('leave_applications')
          .add({
        'userId': user.uid,
        'leaveType': selectedLeaveType,
        'startDate': startDate,
        'endDate': endDate,
        'status': 'pending',
        'createdAt': Timestamp.now(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Leave request submitted successfully!"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to submit: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String? selectedLeaveType;
  DateTime? startDate;
  DateTime? endDate;

  final TextEditingController startDateController = TextEditingController();
  final TextEditingController endDateController = TextEditingController();

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          "Apply for Leave",
          style: TextStyle(color: Color(0xFF3F51B5)),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF3F51B5)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Section
            Text(
              "Request Leave",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF3BAECC),
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              "Fill in the details below to submit your leave request",
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),

            // Leave Type Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.category, color: Color(0xFF3BAECC), size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          "Leave Type",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedLeaveType,
                      decoration: InputDecoration(
                        hintText: "Select leave type",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFF3BAECC), width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      items: <String>['Annual', 'Sick', 'Emergency', 'Unpaid']
                          .map((e) => DropdownMenuItem<String>(
                                value: e,
                                child: Text(e),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedLeaveType = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Date Range Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.date_range, color: Color(0xFF3BAECC), size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          "Leave Period",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Start Date
                    const Text(
                      "Start Date",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        DateTime? selectedDate = await showDatePicker(
                          context: context,
                          initialDate: startDate ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2101),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.light(
                                  primary: Color(0xFF3BAECC),
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (selectedDate != null) {
                          setState(() {
                            startDate = selectedDate;
                            startDateController.text = _formatDate(selectedDate);
                            // Reset end date if it's before the new start date
                            if (endDate != null && endDate!.isBefore(selectedDate)) {
                              endDate = null;
                              endDateController.clear();
                            }
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.white,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              startDate == null ? "Select start date" : _formatDate(startDate!),
                              style: TextStyle(
                                color: startDate == null ? Colors.grey.shade600 : Colors.black87,
                                fontSize: 14,
                              ),
                            ),
                            Icon(Icons.calendar_today, color: Color(0xFF3BAECC), size: 20),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // End Date
                    const Text(
                      "End Date",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: startDate == null
                          ? null
                          : () async {
                              DateTime? selectedDate = await showDatePicker(
                                context: context,
                                initialDate: endDate ?? startDate ?? DateTime.now(),
                                firstDate: startDate!, // Allow same day or after
                                lastDate: DateTime(2101),
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: const ColorScheme.light(
                                        primary: Color(0xFF3BAECC),
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (selectedDate != null) {
                                setState(() {
                                  endDate = selectedDate;
                                  endDateController.text = _formatDate(selectedDate);
                                });
                              }
                            },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: startDate == null ? Colors.grey.shade200 : Colors.grey.shade300,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          color: startDate == null ? Colors.grey.shade100 : Colors.white,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              endDate == null ? "Select end date" : _formatDate(endDate!),
                              style: TextStyle(
                                color: endDate == null ? Colors.grey.shade400 : Colors.black87,
                                fontSize: 14,
                              ),
                            ),
                            Icon(
                              Icons.calendar_today,
                              color: startDate == null ? Colors.grey.shade400 : Color(0xFF3BAECC),
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Duration Info
                    if (startDate != null && endDate != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3BAECC).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, color: Color(0xFF3BAECC), size: 18),
                              const SizedBox(width: 8),
                              Text(
                                "${endDate!.difference(startDate!).inDays + 1} day(s)",
                                style: const TextStyle(
                                  color: Color(0xFF3BAECC),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: submitLeave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3BAECC),
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.send, size: 20),
                    SizedBox(width: 8),
                    Text(
                      "Submit Leave Request",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}