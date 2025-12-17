import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:clockease/services/user_service.dart';
import 'package:clockease/utils/date_formatter.dart'; // Import date formatting utils

class FaceAttendancePage extends StatefulWidget {
  const FaceAttendancePage({super.key}); // Correct the constructor name

  @override
  State<FaceAttendancePage> createState() => _FaceAttendancePageState();
}

class _FaceAttendancePageState extends State<FaceAttendancePage> {
  CameraController? cameraController;
  bool isLogging = false;

  final FaceDetector faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: false,
      enableLandmarks: false,
      performanceMode: FaceDetectorMode.accurate,
    ),
  );

  DateTime? clockInTime;

  @override
  void initState() {
    super.initState();
    initCamera();
  }

  Future<void> initCamera() async {
    final cameras = await availableCameras();
    if (cameras.isNotEmpty) {
      cameraController = CameraController(
        cameras.first,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await cameraController!.initialize();
      setState(() {});
    }
  }

  Future<void> logAttendance() async {
    if (cameraController == null || !cameraController!.value.isInitialized) return;

    setState(() => isLogging = true);

    try {
      // 1️⃣ Capture image
      final XFile file = await cameraController!.takePicture();

      // 2️⃣ Detect face
      final inputImage = InputImage.fromFilePath(file.path);
      final faces = await faceDetector.processImage(inputImage);

      if (faces.isEmpty) {
        showMessage("Face not detected! Try again.");
        setState(() => isLogging = false);
        return;
      }

      // 3️⃣ User info
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        showMessage("User not logged in!");
        setState(() => isLogging = false);
        return;
      }

      final userProfile = await UserService().getEmployeeProfile();
      if (userProfile == null) {
        showMessage("User profile not found!");
        setState(() => isLogging = false);
        return;
      }

      final fullName = userProfile.fullName;
final email = userProfile.email;

      // 4️⃣ Check if attendance already exists today
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);

      final query = await FirebaseFirestore.instance
    .collection('attendance')
    .where('userId', isEqualTo: user.uid)
    .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
    .get();

if (query.docs.isNotEmpty) {
  showMessage("You already logged attendance today!");
  return;
}


      // 5️⃣ Save attendance in Firestore
      final now = DateTime.now();
      final todayId =
          "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      await FirebaseFirestore.instance
    .collection("users")
    .doc(user.uid)
    .collection("attendance")
    .doc(todayId)
    .set({
  "date": Timestamp.fromDate(now),
  "clockIn": Timestamp.fromDate(now),
  "clockOut": null,
  "totalHours": 0,
  "lateDuration": 0,
  "status": "onTime",
}, SetOptions(merge: true));


      clockInTime = DateTime.now();


      showMessage("Attendance logged successfully!");

      // 🔥 Return success to clock card
      Navigator.pop(context, true);

    } catch (e) {
      print("Error: $e");
      showMessage("Error logging attendance");
    }

    setState(() => isLogging = false);
  }

  void showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  void dispose() {
    cameraController?.dispose();
    faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (cameraController == null || !cameraController!.value.isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    String formattedClockIn = clockInTime != null
    ? formatClockIn(clockInTime!)
    : '';


    return Scaffold(
      appBar: AppBar(title: const Text("Attendance Logging")),
      body: Column(
        children: [
          AspectRatio(
            aspectRatio: cameraController!.value.aspectRatio,
            child: CameraPreview(cameraController!),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: isLogging ? null : logAttendance,
            child: Text(isLogging ? "Processing..." : "Log Attendance"),
          ),
          if (formattedClockIn.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text('Clock-in time: $formattedClockIn'),
          ],
        ],
      ),
    );
  }
}
