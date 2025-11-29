import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:clockease/services/user_service.dart'; // Import your user service
import 'package:clockease/utils/date_formatter.dart';  // Import the formatClockIn function

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  CameraController? cameraController;
  bool isLogging = false;
  final FaceDetector faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: false,
      enableLandmarks: false,
      performanceMode: FaceDetectorMode.fast,
    ),
  );

  late Timestamp clockInTimestamp;  // Store clock-in timestamp from Firestore

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

    setState(() {
      isLogging = true;
    });

    try {
      // 1️⃣ Capture image
      final XFile file = await cameraController!.takePicture();

      // 2️⃣ Detect face
      final inputImage = InputImage.fromFilePath(file.path);
      final faces = await faceDetector.processImage(inputImage);

      if (faces.isEmpty) {
        showMessage("Face not detected!");
        setState(() => isLogging = false);
        return;
      }

      // 3️⃣ Get user info from UserService
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        showMessage("User not logged in!");
        setState(() => isLogging = false);
        return;
      }

      // Retrieve user profile details
      final userProfile = await UserService().getEmployeeProfile();
      if (userProfile == null) {
        showMessage("User profile not found!");
        setState(() => isLogging = false);
        return;
      }

      final fullName = userProfile["fullName"];
      final email = userProfile["email"];

      // 4️⃣ Check if attendance already logged today
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);

      final query = await FirebaseFirestore.instance
          .collection('attendance')
          .where('userId', isEqualTo: user.uid)
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .get();

      if (query.docs.isNotEmpty) {
        showMessage("You already logged attendance today!");
        setState(() => isLogging = false);
        return;
      }

      // 5️⃣ Log attendance to Firestore
      await FirebaseFirestore.instance.collection('attendance').add({
        'userId': user.uid,
        'fullName': fullName,
        'email': email,
        'timestamp': Timestamp.now(),
        'status': 'Present', // Attendance status
      });

      // Fetch the `clockIn` timestamp after logging attendance
      clockInTimestamp = Timestamp.now();

      showMessage("Attendance logged successfully!");
    } catch (e) {
      print("Error: $e");
      showMessage("Error logging attendance");
    }

    setState(() {
      isLogging = false;
    });
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

    // Format the clockIn timestamp to a user-friendly string if it's set
    String formattedClockIn = '';
    if (clockInTimestamp != null) {
      formattedClockIn = formatClockIn(clockInTimestamp);
    }

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
            Text('Clock-in time: $formattedClockIn'),  // Display formatted clockIn time
          ],
        ],
      ),
    );
  }
}
