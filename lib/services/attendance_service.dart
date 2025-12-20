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

  /// Logs attendance to Firestore.
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

    final ref = _db
        .collection('users')
        .doc(uid)
        .collection('attendance')
        .doc(today);

    final docSnap = await ref.get();
    final data = docSnap.data();

    // 1. Determine Current State
    // Default to false (Clocked Out) if not present
    bool isClockedIn = false;
    if (data != null && data.containsKey('isClockedIn')) {
      isClockedIn = data['isClockedIn'] == true;
    } else if (data != null) {
      // Legacy Fallback: If has checkIn but no checkOut -> assumes IN
      if (data['checkIn'] != null && data['checkOut'] == null) {
        isClockedIn = true;
      }
    }

    // 2. Determine Next Action
    final String actionType = isClockedIn ? "checkOut" : "checkIn";
    final formattedTime = formatClock(now);

    // 3. Prepare Updates
    final Map<String, dynamic> updates = {
      "isClockedIn": !isClockedIn, // Toggle state
      "lastUpdated": Timestamp.fromDate(now),
      // Add to logs array
      "logs": FieldValue.arrayUnion([
        {
          "type": actionType,
          "time": Timestamp.fromDate(now),
          "formattedTime": formattedTime,
          "selfieUrl": selfieUrl ?? "",
          // Include location in logs array
          if (location != null) "location": location.toMap(),
        }
      ]),
    };

    if (actionType == "checkIn") {
      // --- CLOCK IN ---
      updates["formattedClockIn"] = formattedTime; // Display as last action
      
      // Keep "First Check-In" for history purposes if not set
      if (data == null || data["checkIn"] == null) {
        updates["date"] = Timestamp.fromDate(now); // Set date on first creation
        updates["checkIn"] = Timestamp.fromDate(now);
        updates["method"] = "face";
      }
    } else {
      // --- CLOCK OUT ---
      updates["formattedCheckOut"] = formattedTime; // Display as last action
      updates["checkOut"] = Timestamp.fromDate(now); // Always update last check out
      if (selfieUrl != null) {
        updates["selfieUrlCheckOut"] = selfieUrl;
      }
    }

    // 4. Commit Updates
    await ref.set(updates, SetOptions(merge: true));

    // 5. GRANULAR LOGGING (New Requirement)
    // Save a separate immutable record for every event
    try {
      final granularLog = {
        "userId": uid,
        "type": actionType, // "checkIn" or "checkOut"
        "timestamp": Timestamp.fromDate(now),
        "date": today,
        "imageUrl": selfieUrl ?? "",
        "formattedTime": formattedTime,
      };
      
      // Add location to granular log if available
      if (location != null) {
        granularLog["location"] = location.toMap();
        print('📍 Attendance Payload includes location: lat=${location.latitude}, lng=${location.longitude}');
      }
      
      await _db.collection('attendance_logs').add(granularLog);
      print('✅ Attendance logged successfully to Firestore');
    } catch (e) {
      print("❌ Error saving granular log: $e");
      // Don't fail the main flow if this auxiliary write fails
    }

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

  Future<Map<String, dynamic>?> getTodayRecord() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final uid = user.uid;
    final now = DateTime.now();
    final today = DateFormat("yyyy-MM-dd").format(now);

    final ref = _db
        .collection('users')
        .doc(uid)
        .collection('attendance')
        .doc(today);

    final doc = await ref.get();
    return doc.exists ? doc.data() : null;
  }

  /// FOR DEV TESTING ONLY: Resets today's attendance
  Future<void> resetToday() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final uid = user.uid;
    final now = DateTime.now();
    final today = DateFormat("yyyy-MM-dd").format(now);

    // Delete from unified collection
    await _db
        .collection('users')
        .doc(uid)
        .collection('attendance')
        .doc(today)
        .delete();
      
    // Delete from users collection (legacy/dashboard sync)
    // To ensure complete reset
    await _db
        .collection('users')
        .doc(uid)
        .collection('attendance')
        .doc(today) // Note: this might use formatted ID, checking FirestoreService logic
        .delete();
  }
}
