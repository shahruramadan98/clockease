import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String fullName;
  final String email;
  final String employeeId;
  final String designation; // Role
  final String? phoneNumber;
  final String? gender;
  final String? profilePictureUrl;
  final DateTime? createdAt;

  UserProfile({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.employeeId,
    required this.designation,
    this.phoneNumber,
    this.gender,
    this.profilePictureUrl,
    this.createdAt,
  });

  factory UserProfile.fromMap(String uid, Map<String, dynamic> data) {
    return UserProfile(
      uid: uid,
      fullName: data['fullName'] ?? 'Unknown',
      email: data['email'] ?? '',
      employeeId: data['employeeId'] ?? 'N/A',
      designation: data['designation'] ?? 'Employee',
      phoneNumber: data['phoneNumber'],
      gender: data['gender'],
      profilePictureUrl: data['profilePictureUrl'],
      createdAt: data['createdAt'] != null ? (data['createdAt'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'email': email,
      'employeeId': employeeId,
      'designation': designation,
      'phoneNumber': phoneNumber,
      'gender': gender,
      'profilePictureUrl': profilePictureUrl,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
    };
  }
}
