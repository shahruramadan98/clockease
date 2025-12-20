import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LeaveService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get user => _auth.currentUser;

  Future<void> submitLeave({
    required String companyId,
    required String userName,
    required String employeeId,
    required String leaveType,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (user == null) return;

    await _firestore.collection('leave_applications').add({
      'userId': user!.uid,
      'companyId': companyId,
      'userName': userName,
      'employeeId': employeeId,
      'leaveType': leaveType,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'status': 'pending',
      'createdAt': Timestamp.now(),
    });
  }

  Stream<List<Map<String, dynamic>>> getUserLeaves() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Stream.empty();
    }

    return FirebaseFirestore.instance
        .collection('leave_applications')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {

          return snapshot.docs.map((doc) {
            return {
              'id': doc.id,
              ...doc.data(),
            };
          }).toList();
        });
  }
}
