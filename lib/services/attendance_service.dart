// lib/services/attendance_service.dart

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import 'location_service.dart';

class AttendanceService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final LocationService _locationService = LocationService();

  String formatClock(DateTime time) {
    return DateFormat('MMMM dd, yyyy h:mm a').format(time);
  }

  Future<String> _uploadSelfie(File selfie) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not logged in");

    final now = DateTime.now().millisecondsSinceEpoch;
    final fileName = "attendance/${user.uid}/$now.jpg";

    final ref = _storage.ref(fileName);
    await ref.putFile(selfie);
    return await ref.getDownloadURL();
  }

  /// Logs attendance to attendance_logs collection.
  /// Determines check-in/out state by querying the last log entry.
  /// Throws Exception on failure.
  /// Returns a Map with {success: true, type: "checkIn" | "checkOut"}
  Future<Map<String, dynamic>> logAttendance({
    String? selfieUrl,
    LocationData? location,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not logged in");

    final uid = user.uid;
    final now = DateTime.now();
    final today = DateFormat("yyyy-MM-dd").format(now);

    // 1. Determine Current State by querying last log from attendance_logs
    final lastLogQuery = await _db
        .collection('attendance_logs')
        .where('userId', isEqualTo: uid)
        .where('date', isEqualTo: today)
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();

    // Determine if currently clocked in based on last log
    bool isClockedIn = false;
    if (lastLogQuery.docs.isNotEmpty) {
      final lastLog = lastLogQuery.docs.first.data();
      isClockedIn = lastLog['type'] == 'checkIn';
    }

    // 2. Determine Next Action
    final String actionType = isClockedIn ? "checkOut" : "checkIn";
    final formattedTime = formatClock(now);

    // 3. Create attendance log entry
    final Map<String, dynamic> logEntry = {
      "userId": uid,
      "type": actionType, // "checkIn" or "checkOut"
      "timestamp": Timestamp.fromDate(now),
      "date": today,
      "faceImagePath": selfieUrl ?? "",
      "formattedTime": formattedTime,
    };
    
    // Add location to log if available
    if (location != null) {
      logEntry["location"] = location.toMap();
      print('📍 Attendance Payload includes location: lat=${location.latitude}, lng=${location.longitude}');
    }
    
    // 4. Save to attendance_logs collection
    await _db.collection('attendance_logs').add(logEntry);
    print('✅ Attendance logged successfully to attendance_logs: $actionType');

    return {"success": true, "type": actionType};
  }

  /// Uploads selfie, captures location, and logs attendance.
  /// Throws Exception on any failure.
  /// FLOW: Use Confirmed Location → Upload Selfie → Log Attendance → Return Success
  Future<Map<String, dynamic>> uploadSelfieAndLogAttendance(
    File selfie, {
    LocationData? confirmedLocation,
  }) async {
    LocationData locationData;
    
    try {
      // STEP 1: Use confirmed location or fetch new one
      if (confirmedLocation != null) {
        // Use the location that user already confirmed
        print('📍 Using pre-confirmed location from popup');
        print('📍 Address: ${confirmedLocation.address}');
        print('📍 Coordinates: lat=${confirmedLocation.latitude}, lng=${confirmedLocation.longitude}');
        print('📍 Accuracy: ${confirmedLocation.accuracy}m');
        locationData = confirmedLocation;
      } else {
        // Fallback: Capture now (for backward compatibility)
        print('📍 Step 1: Capturing location...');
        
        try {
          locationData = await _locationService.getCurrentLocation(
            includeAddress: true,
          );
          print('✅ Location captured successfully');
        } catch (e) {
          // If location fails, we abort the entire attendance flow
          print('❌ Location capture failed: $e');
          
          // Re-throw with user-friendly message
          if (e is Exception) {
            rethrow; // Already has user-friendly message from LocationService
          } else {
            throw Exception(
              'Unable to capture your location. Please ensure GPS is enabled and location permission is granted.',
            );
          }
        }
      }

      // STEP 2: Upload Selfie
      print('📸 Step 2: Uploading selfie...');
      final url = await _uploadSelfie(selfie);
      print('✅ Selfie uploaded successfully');

      // STEP 3: Log Attendance with location
      print('💾 Step 3: Saving attendance to Firestore...');
      final result = await logAttendance(
        selfieUrl: url,
        location: locationData,
      );
      print('✅ Attendance saved with location data');

      return {
        "success": true,
        "type": result["type"],
        "selfieUrl": url,
        "location": locationData.toMap(),
      };
    } catch (e) {
      print('❌ uploadSelfieAndLogAttendance failed: $e');
      throw Exception(e.toString());
    }
  }


  /// FOR DEV TESTING ONLY: Resets today's attendance from attendance_logs
  Future<void> resetToday() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final uid = user.uid;
    final now = DateTime.now();
    final today = DateFormat("yyyy-MM-dd").format(now);

    // Delete all attendance_logs for today
    final logsQuery = await _db
        .collection('attendance_logs')
        .where('userId', isEqualTo: uid)
        .where('date', isEqualTo: today)
        .get();

    for (final doc in logsQuery.docs) {
      await doc.reference.delete();
    }
    
    print('✅ Reset complete: deleted ${logsQuery.docs.length} logs for $today');
  }
}

