import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';

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
    return _db.collection('companies').snapshots().asyncMap(
      (companiesSnap) async {
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
}
