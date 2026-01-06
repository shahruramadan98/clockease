import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class LeaveApprovalPage extends StatefulWidget {
  final String companyId;

  const LeaveApprovalPage({
    super.key,
    required this.companyId,
  });

  @override
  State<LeaveApprovalPage> createState() => _LeaveApprovalPageState();
}

class _LeaveApprovalPageState extends State<LeaveApprovalPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _fmtRange(Map<String, dynamic> data) {
    final start = (data['startDate'] as Timestamp).toDate();
    final end = (data['endDate'] as Timestamp).toDate();

    if (start == end) {
      return '${start.day}/${start.month}/${start.year}';
    }

    return '${start.day}/${start.month}–${end.day}/${end.month}/${end.year}';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ==========================
          // PAGE HEADER
          // ==========================
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Leave Management',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3F51B5),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Review and manage staff leave requests',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),

          // ==========================
          // TAB BAR
          // ==========================
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(25),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                color: const Color(0xFF3F51B5),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey.shade700,
              tabs: const [
                Tab(text: 'Pending'),
                Tab(text: 'Approved'),
                Tab(text: 'Rejected'),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ==========================
          // TAB BAR VIEW
          // ==========================
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Pending leaves
                _buildLeaveList('pending', showActions: true),
                // Approved leaves
                _buildLeaveList('approved', showActions: false),
                // Rejected leaves
                _buildLeaveList('rejected', showActions: false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================
  // BUILD LEAVE LIST BY STATUS
  // ==========================
  Widget _buildLeaveList(String status, {required bool showActions}) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('leave_applications')
          .where('companyId', isEqualTo: widget.companyId)
          .where('status', isEqualTo: status)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  status == 'pending'
                      ? Icons.inbox
                      : status == 'approved'
                          ? Icons.check_circle_outline
                          : Icons.cancel_outlined,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  status == 'pending'
                      ? 'No pending leave requests'
                      : status == 'approved'
                          ? 'No approved leaves yet'
                          : 'No rejected leaves',
                  style: const TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ],
            ),
          );
        }

        final leaves = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          itemCount: leaves.length,
          itemBuilder: (context, index) {
            final doc = leaves[index];
            final data = doc.data() as Map<String, dynamic>;

            final start = (data['startDate'] as Timestamp).toDate();
            final end = (data['endDate'] as Timestamp).toDate();

            final reason = data['reason'] as String?;
            final attachmentUrl = data['attachmentUrl'] as String?;
            final leaveType = data['leaveType'] as String? ?? '';
            final isSickLeave = leaveType == 'Sick';
            final actionAt = data['actionAt'] as Timestamp?;

            return Card(
              elevation: 3,
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row with name and action buttons
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data['userName'] ?? 'Unknown',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              if (status != 'pending' && actionAt != null)
                                Text(
                                  'Action: ${_fmt(actionAt.toDate())}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (showActions) ...[
                          IconButton(
                            tooltip: 'Approve',
                            icon: const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                            ),
                            onPressed: () =>
                                _updateStatus(doc.reference, 'approved'),
                          ),
                          IconButton(
                            tooltip: 'Reject',
                            icon: const Icon(
                              Icons.cancel,
                              color: Colors.redAccent,
                            ),
                            onPressed: () =>
                                _updateStatus(doc.reference, 'rejected'),
                          ),
                        ] else
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: status == 'approved'
                                  ? Colors.green.shade50
                                  : Colors.red.shade50,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: status == 'approved'
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: TextStyle(
                                color: status == 'approved'
                                    ? Colors.green
                                    : Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Leave type and employee ID
                    Row(
                      children: [
                        Icon(
                          Icons.event_note,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$leaveType • ID: ${data['employeeId']}',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Date range
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${_fmt(start)} → ${_fmt(end)}',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),

                    // Reason (if provided)
                    if (reason != null && reason.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.description,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Reason: $reason',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[800],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

                    // Attachment button (only for Sick Leave with attachment)
                    if (isSickLeave &&
                        attachmentUrl != null &&
                        attachmentUrl.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () => _openAttachment(attachmentUrl),
                        icon: const Icon(Icons.attach_file, size: 18),
                        label: const Text('View Attachment'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3F51B5),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ==========================
  // UPDATE LEAVE STATUS
  // ==========================
  Future<void> _updateStatus(
    DocumentReference ref,
    String status,
  ) async {
    final snap = await ref.get();
    final data = snap.data() as Map<String, dynamic>;

    await ref.update({
      'status': status,
      'actionAt': FieldValue.serverTimestamp(),
    });

    // 🔔 Create notification for staff
    await FirebaseFirestore.instance.collection('notifications').add({
      'userId': data['userId'], // staff UID
      'title': status == 'approved'
          ? 'Leave Approved'
          : 'Leave Rejected',
      'message':
          'Your ${data['leaveType']} leave (${_fmtRange(data)}) was $status.',
      'leaveId': ref.id,
      'type': 'leave',
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ==========================
  // OPEN ATTACHMENT
  // ==========================
  Future<void> _openAttachment(String url) async {
    try {
      final uri = Uri.parse(url);
      // Use platformDefault mode which works better on Android
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    } catch (e) {
      debugPrint('Could not launch $url: $e');
    }
  }

  // ==========================
  // DATE FORMAT
  // ==========================
  String _fmt(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/'
        '${d.year}';
  }
}
