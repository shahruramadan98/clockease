import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/leave_policy.dart';

class CompanySettingsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _policyRef(String companyId) {
    return _db
        .collection('companies')
        .doc(companyId)
        .collection('settings')
        .doc('leave_policy');
  }

  // =============================
  // FETCH LEAVE POLICY
  // =============================
  Future<LeavePolicy?> getLeavePolicy(String companyId) async {
    final snap = await _policyRef(companyId).get();

    if (!snap.exists || snap.data() == null) return null;

    // ✅ Explicit cast (THIS FIXES YOUR ERROR)
    final data = snap.data() as Map<String, dynamic>;

    return LeavePolicy.fromMap(data);
  }

  // =============================
  // SAVE LEAVE POLICY
  // =============================
  Future<void> saveLeavePolicy(
    String companyId,
    LeavePolicy policy,
  ) async {
    await _policyRef(companyId).set(
      policy.toMap(),
      SetOptions(merge: true),
    );
  }
}
