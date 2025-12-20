import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// One-time migration script to fix missing companyId in users collection
/// Run this once to sync existing user data
Future<void> migrateUserCompanyId() async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) {
    print('Migration: No authenticated user');
    return;
  }

  print('Migration: Starting for uid: $uid');
  final fire = FirebaseFirestore.instance;

  try {
    // Search all companies to find where this user exists
    final companies = await fire.collection('companies').get();
    print('Migration: Searching ${companies.docs.length} companies');

    for (var company in companies.docs) {
      final employeeDoc = await fire
          .collection('companies')
          .doc(company.id)
          .collection('employees')
          .doc(uid)
          .get();

      if (employeeDoc.exists) {
        print('Migration: Found user in company: ${company.id}');
        
        // Update users/{uid} with companyId
        await fire.collection('users').doc(uid).set({
          'companyId': company.id,
          'role': employeeDoc.data()?['role'] ?? 'employee',
          'fullName': employeeDoc.data()?['fullName'] ?? '',
          'email': employeeDoc.data()?['email'] ?? '',
          'designation': employeeDoc.data()?['designation'] ?? '',
          'employeeId': employeeDoc.data()?['employeeId'] ?? '',
        }, SetOptions(merge: true));

        print('Migration: Successfully synced companyId to users/$uid');
        print('Migration: CompanyId = ${company.id}');
        return;
      }
    }

    print('Migration: User not found in any company');
  } catch (e, stackTrace) {
    print('Migration error: $e');
    print('Migration stack trace: $stackTrace');
  }
}
