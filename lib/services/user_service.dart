import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile.dart';

class UserService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  /// Fetches the profile from users/{uid}. 
  /// Optimized for ClockEase and ensures auto-creation.
  Future<UserProfile?> getEmployeeProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final docRef = _db.collection("users").doc(user.uid);
    final docSnap = await docRef.get();

    if (docSnap.exists) {
      return UserProfile.fromMap(user.uid, docSnap.data()!);
    } else {
      // Auto-create missing profile safely (Idempotent)
      final newProfile = {
        'fullName': user.displayName ?? 'New User',
        'email': user.email ?? '',
        'designation': 'Employee',
        'employeeId': 'N/A',
        'createdAt': FieldValue.serverTimestamp(),
      };
      
      await docRef.set(newProfile, SetOptions(merge: true));
      
      // Return the newly created profile (or refetch)
      final finalSnap = await docRef.get();
      return UserProfile.fromMap(user.uid, finalSnap.data()!);
    }
  }

  /// Reactive stream for real-time profile updates
  Stream<UserProfile?> getUserProfileStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(null);

    return _db.collection("users").doc(user.uid).snapshots().map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        return UserProfile.fromMap(user.uid, snapshot.data()!);
      }
      return null;
    });
  }
}
