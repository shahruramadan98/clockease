import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile.dart';

class UserService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Future<UserProfile?> getEmployeeProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final companySnap = await _db.collection("companies").get();

    for (var c in companySnap.docs) {
      final empDoc = await _db
          .collection("companies")
          .doc(c.id)
          .collection("employees")
          .doc(user.uid)
          .get();

      if (empDoc.exists && empDoc.data() != null) {
        return UserProfile.fromMap(user.uid, empDoc.data()!);
      }
    }

    return null;
  }
}
