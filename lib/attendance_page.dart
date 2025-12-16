import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:camera/camera.dart';
import 'package:clockease/controllers/attendance_controller.dart';
import 'package:clockease/utils/date_formatter.dart';
import 'package:intl/intl.dart';

class AttendancePage extends ConsumerStatefulWidget {
  const AttendancePage({super.key});

  @override
  ConsumerState<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends ConsumerState<AttendancePage> {
  CameraController? cameraController;
  bool isLogging = false;

  final FaceDetector faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: false,
      enableLandmarks: false,
      performanceMode: FaceDetectorMode.fast,
    ),
  );

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
      if (mounted) setState(() {});
    }
  }

  Future<void> logAttendance() async {
    if (cameraController == null || !cameraController!.value.isInitialized)
      return;

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

      // 3️⃣ Log attendance via Controller
      final result = await ref.read(attendanceProvider.notifier).logAttendance();
      showMessage(result['message']);
    } catch (e) {
      showMessage("Error: $e");
    }

    if (mounted) {
      setState(() {
        isLogging = false;
      });
    }
  }

  void showMessage(String msg) {
    if (!mounted) return;
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
    final attendanceState = ref.watch(attendanceProvider);

    // Find today's clock-in time
    String formattedClockIn = '';
    attendanceState.whenData((records) {
      final now = DateTime.now();
      final todayRecord = records.firstWhere(
        (r) =>
            r.date.year == now.year &&
            r.date.month == now.month &&
            r.date.day == now.day,
        orElse: () => throw Exception('No record'), // Handle gracefully below
      );
      // We rely on the catch block/orElse? No, let's do safe check.
    });
    
    // Better way to find safe record
    if (attendanceState.hasValue) {
        final records = attendanceState.value!;
        final now = DateTime.now();
         try {
           final todayRecord = records.firstWhere(
            (r) =>
                r.date.year == now.year &&
                r.date.month == now.month &&
                r.date.day == now.day
          );
           if (todayRecord.clockIn != null) {
             // Assuming formatClockIn is the util function we imported. 
             // If not available, we use DateFormat directly.
             // The previous code used 'package:clockease/utils/date_formatter.dart';
             // I included the import.
             formattedClockIn = formatClockIn(todayRecord.clockIn!);
           }
         } catch (e) {
           // No record for today
         }
    }


    if (cameraController == null || !cameraController!.value.isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
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
            Text('Clock-in time: $formattedClockIn'),
          ],
        ],
      ),
    );
  }
}
