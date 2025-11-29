import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

final userProvider = FutureProvider<UserModel?>((ref) async {
  final authUser = FirebaseAuth.instance.currentUser;
  if (authUser == null) return null;

  final fire = FirebaseFirestore.instance;

  // Search all companies
  final companies = await fire.collection('companies').get();

  for (var company in companies.docs) {
    final employeeDoc = await fire
        .collection('companies')
        .doc(company.id)
        .collection('employees')
        .doc(authUser.uid)
        .get();

    if (employeeDoc.exists) {
      return UserModel(
        fullName: employeeDoc.data()?['fullName'] ?? "",
        email: employeeDoc.data()?['email'],
        companyId: company.id,
        role: employeeDoc.data()?['role'] ?? "employee",
      );
    }
  }

  return null;
});

class UserModel {
  final String fullName;
  final String? email;
  final String companyId;
  final String role;

  UserModel({
    required this.fullName,
    required this.email,
    required this.companyId,
    required this.role,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      fullName: map['fullName'] ?? '',
      email: map['email'],
      companyId: map['companyId'] ?? '',
      role: map['role'] ?? 'employee',
    );
  }
}
