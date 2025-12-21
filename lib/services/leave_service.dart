import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import '../models/leave_info.dart';

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
    String? reason,
    String? attachmentUrl,
  }) async {
    if (user == null) return;

    final leaveData = {
      'userId': user!.uid,
      'companyId': companyId,
      'userName': userName,
      'employeeId': employeeId,
      'leaveType': leaveType,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'status': 'pending',
      'createdAt': Timestamp.now(),
    };

    // Add optional fields if provided
    if (reason != null && reason.isNotEmpty) {
      leaveData['reason'] = reason;
    }
    if (attachmentUrl != null && attachmentUrl.isNotEmpty) {
      leaveData['attachmentUrl'] = attachmentUrl;
    }

    await _firestore.collection('leave_applications').add(leaveData);
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

  /// Fetches all approved leaves for a company in a specific month
  /// and organizes them by date for calendar display
  Future<Map<DateTime, List<LeaveInfo>>> getCompanyLeavesForMonth(
    int year,
    int month,
    String companyId,
  ) async {
    // Calculate the start and end of the month
    final monthStart = DateTime(year, month, 1);
    final monthEnd = DateTime(year, month + 1, 0, 23, 59, 59);

    print('Fetching leaves for company $companyId from $monthStart to $monthEnd');

    // Query all approved leaves for this company
    final snapshot = await _firestore
        .collection('leave_applications')
        .where('companyId', isEqualTo: companyId)
        .where('status', isEqualTo: 'approved')
        .get();

    print('Found ${snapshot.docs.length} approved leaves for company');

    // Map to store leaves by date
    final Map<DateTime, List<LeaveInfo>> leavesByDate = {};

    for (var doc in snapshot.docs) {
      final leave = LeaveInfo.fromDoc(doc);

      // Check if this leave overlaps with the current month
      if (leave.endDate.isBefore(monthStart) || leave.startDate.isAfter(monthEnd)) {
        continue; // Skip leaves that don't overlap with this month
      }

      // Add this leave to all dates it covers within the month
      DateTime currentDate = leave.startDate.isBefore(monthStart) 
          ? monthStart 
          : leave.startDate;
      
      final endDate = leave.endDate.isAfter(monthEnd) 
          ? monthEnd 
          : leave.endDate;

      while (!currentDate.isAfter(endDate)) {
        final dateKey = DateTime(currentDate.year, currentDate.month, currentDate.day);
        
        if (!leavesByDate.containsKey(dateKey)) {
          leavesByDate[dateKey] = [];
        }
        
        leavesByDate[dateKey]!.add(leave);
        currentDate = currentDate.add(const Duration(days: 1));
      }
    }

    print('Organized leaves into ${leavesByDate.length} dates');
    return leavesByDate;
  }

  /// Uploads a file attachment to Firebase Storage
  /// Returns the download URL
  Future<String?> uploadAttachment(PlatformFile file) async {
    try {
      if (user == null) {
        print('Error: User not authenticated');
        return null;
      }

      // Get file bytes - this works on all platforms
      final bytes = file.bytes;
      if (bytes == null) {
        print('Error: File bytes are null');
        return null;
      }

      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('leave_attachments')
          .child(user!.uid)
          .child(fileName);

      print('Uploading attachment: $fileName (${bytes.length} bytes)');
      
      // Use putData instead of putFile for cross-platform compatibility
      final uploadTask = await storageRef.putData(
        bytes,
        SettableMetadata(
          contentType: _getContentType(file.extension),
        ),
      );
      
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      print('Upload successful: $downloadUrl');
      
      return downloadUrl;
    } catch (e, stackTrace) {
      print('Error uploading attachment: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  /// Helper method to determine content type based on file extension
  String? _getContentType(String? extension) {
    if (extension == null) return null;
    
    switch (extension.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      default:
        return null;
    }
  }
}
