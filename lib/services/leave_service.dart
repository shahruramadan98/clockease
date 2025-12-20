import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LeaveService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  User? get user => _auth.currentUser;

  // Submit leave
  Future<void> submitLeave({
    required String leaveType,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (user == null) return;

    await _firestore.collection('leave_applications').add({
      'userId': user!.uid,
      'leaveType': leaveType,
      'startDate': startDate,
      'endDate': endDate,
      'status': 'pending',
      'createdAt': Timestamp.now(),
    });
  }

  // Stream user leaves - optimized with Firestore-level sorting
  Stream<List<Map<String, dynamic>>> getUserLeaves() {
    if (user == null) return Stream.value([]);
    
    return _firestore
        .collection('leave_applications')
        .where('userId', isEqualTo: user!.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) {
          return snap.docs.map((doc) {
            return {
              'id': doc.id,
              ...doc.data(),
            };
          }).toList();
        });
  }
}

