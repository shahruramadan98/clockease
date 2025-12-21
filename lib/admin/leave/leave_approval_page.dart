import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class LeaveApprovalPage extends StatelessWidget {
  final String companyId;

  const LeaveApprovalPage({
    super.key,
    required this.companyId,
  });

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
                  'Leave Approval',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3F51B5),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Review and approve staff leave requests',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),

          // ==========================
          // LEAVE LIST
          // ==========================
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('leave_applications')
                  .where('companyId', isEqualTo: companyId)
                  .where('status', isEqualTo: 'pending')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No pending leave requests',
                      style: TextStyle(color: Colors.grey),
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

                    final start =
                        (data['startDate'] as Timestamp).toDate();
                    final end =
                        (data['endDate'] as Timestamp).toDate();

                    final reason = data['reason'] as String?;
                    final attachmentUrl = data['attachmentUrl'] as String?;
                    final leaveType = data['leaveType'] as String? ?? '';
                    final isSickLeave = leaveType == 'Sick';

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
                                  child: Text(
                                    data['userName'] ?? 'Unknown',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
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
                            if (isSickLeave && attachmentUrl != null && attachmentUrl.isNotEmpty) ...[
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
            ),
          ),
        ],
      ),
    );
  }

  // ==========================
  // UPDATE LEAVE STATUS
  // ==========================
  Future<void> _updateStatus(
    DocumentReference ref,
    String status,
  ) async {
    await ref.update({
      'status': status,
      'actionAt': FieldValue.serverTimestamp(),
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
