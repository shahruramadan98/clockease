import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text(
                          data['userName'] ?? 'Unknown',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${data['leaveType']} • ID: ${data['employeeId']}',
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_fmt(start)} → ${_fmt(end)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
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
  // DATE FORMAT
  // ==========================
  String _fmt(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/'
        '${d.year}';
  }
}
