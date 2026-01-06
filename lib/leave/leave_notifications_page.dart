import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LeaveNotificationsPage extends StatelessWidget {
  const LeaveNotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('userId', isEqualTo: uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {

          // 1️⃣ Loading (only while waiting)
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 2️⃣ Error handling (VERY IMPORTANT)
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading notifications:\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          // 3️⃣ Empty state
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("No notifications"),
            );
          }

          // 4️⃣ Render list
          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final isRead = data['isRead'] == true;

              return ListTile(
                leading: Icon(
                  Icons.notifications,
                  color: isRead ? Colors.grey : Colors.blue,
                ),
                title: Text(
                  data['title'] ?? '',
                  style: TextStyle(
                    fontWeight:
                        isRead ? FontWeight.normal : FontWeight.bold,
                  ),
                ),
                subtitle: Text(data['message'] ?? ''),
                onTap: () async {
                  if (!isRead) {
                    await doc.reference.update({'isRead': true});
                  }
                  Navigator.pop(context); // optional
                },
              );
            },
          );
        },
      ),
    );
  }
}
