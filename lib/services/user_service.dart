import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';
import '../models/leave_policy.dart';

class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ============================================================
  // FETCH PROFILE ONCE (used by some pages)
  // ============================================================
  Future<UserProfile?> getEmployeeProfile(String uid) async {
    // 🔍 Search employee across companies
    final companiesSnap = await _db.collection('companies').get();

    for (final company in companiesSnap.docs) {
      final empRef = _db
          .collection('companies')
          .doc(company.id)
          .collection('employees')
          .doc(uid);

      final empSnap = await empRef.get();

      if (empSnap.exists && empSnap.data() != null) {
        return UserProfile.fromMap(uid, empSnap.data()!);
      }
    }

    // ❌ Profile must exist
    return null;
  }

  // ============================================================
  // STREAM PROFILE (REAL-TIME, AUTH-SAFE)
  // ============================================================
  Stream<UserProfile?> getEmployeeProfileStream(String uid) {
    print('🔍 getEmployeeProfileStream called for UID: $uid');
    
    return _db.collection('companies').snapshots().asyncMap(
      (companiesSnap) async {
        print('📦 Found ${companiesSnap.docs.length} companies');
        
        for (final company in companiesSnap.docs) {
          print('🏢 Checking company: ${company.id}');
          
          final empRef = _db
              .collection('companies')
              .doc(company.id)
              .collection('employees')
              .doc(uid);

          final empSnap = await empRef.get();
          print('👤 Employee exists in ${company.id}: ${empSnap.exists}');

          if (empSnap.exists && empSnap.data() != null) {
            print('✅ Found profile in company: ${company.id}');
            return UserProfile.fromMap(uid, empSnap.data()!);
          }
        }
        
        print('❌ No profile found for UID: $uid');
        return null;
      },
    );
  }

  // ============================================================
  // OPTIONAL: GET COMPANY ID FOR CURRENT USER
  // (VERY USEFUL FOR ADMIN ROUTING)
  // ============================================================
  Future<String?> getCompanyIdForUser(String uid) async {
    final companiesSnap = await _db.collection('companies').get();

    for (final company in companiesSnap.docs) {
      final empSnap = await _db
          .collection('companies')
          .doc(company.id)
          .collection('employees')
          .doc(uid)
          .get();

      if (empSnap.exists) {
        return company.id;
      }
    }
    return null;
  }

  // ============================================================
  // UPDATE EMPLOYEE PROFILE
  // ============================================================
  Future<void> updateEmployeeProfile(
    String uid,
    String companyId,
    Map<String, dynamic> updates,
  ) async {
    try {
      final empRef = _db
          .collection('companies')
          .doc(companyId)
          .collection('employees')
          .doc(uid);

      await empRef.update(updates);
      print('✅ Profile updated successfully for UID: $uid');
    } catch (e) {
      print('❌ Error updating profile: $e');
      rethrow;
    }
  }

  Future<LeavePolicy?> getLeavePolicy(String companyId) async {
    final snap = await _db
        .collection('companies')
        .doc(companyId)
        .collection('settings')
        .doc('leave_policy')
        .get();

    if (!snap.exists || snap.data() == null) return null;

    return LeavePolicy.fromMap(snap.data()!);
  }
}
