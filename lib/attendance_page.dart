import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:camera/camera.dart';
import 'package:clockease/controllers/attendance_controller.dart';
import 'package:clockease/utils/date_formatter.dart';

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

  // =====================================================
  // ATTENDANCE HANDLER
  // =====================================================
  Future<void> handleAttendanceAction() async {
    if (cameraController == null || !cameraController!.value.isInitialized) {
      showErrorDialog(
        "Camera not ready. Please restart the app or check permissions.",
      );
      return;
    }

    setState(() => isLogging = true);

    try {
      // 1️⃣ Capture image
      final XFile file = await cameraController!.takePicture();

      // 2️⃣ Face detection
      final inputImage = InputImage.fromFilePath(file.path);
      final faces = await faceDetector.processImage(inputImage);

      if (faces.isEmpty) {
        showErrorDialog(
          "Face not detected. Please ensure your face is clearly visible.",
        );
        setState(() => isLogging = false);
        return;
      }

      // 3️⃣ Log attendance (controller decides check-in / check-out)
      final controller = ref.read(attendanceControllerProvider);

      final result = await controller.logAttendance().timeout(
        const Duration(seconds: 10),
        onTimeout: () =>
            throw Exception("Network timeout. Please try again."),
      );

      if (result['success'] == true) {
        final type = result['type'];

        if (type == 'checkIn') {
          showMessage(
            "You are now clocked in",
            subtitle: "Have a productive day",
          );
        } else if (type == 'checkOut') {
          showMessage(
            "You are now clocked out",
            subtitle: "See you next time",
          );
        }
      } else {
        showErrorDialog(result['message'] ?? "Unknown error");
      }
    } catch (e) {
      String msg = e.toString().replaceAll("Exception: ", "");
      showErrorDialog(msg);
    }

    if (mounted) {
      setState(() => isLogging = false);
    }
  }

  // =====================================================
  // UI HELPERS
  // =====================================================
  Future<void> showErrorDialog(String message) async {
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void showMessage(String msg, {String? subtitle}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(msg, style: const TextStyle(fontWeight: FontWeight.bold)),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    cameraController?.dispose();
    faceDetector.close();
    super.dispose();
  }

  // =====================================================
  // BUILD
  // =====================================================
  @override
  Widget build(BuildContext context) {
    final attendanceState = ref.watch(attendanceProvider);

    String formattedClockIn = '';

    if (attendanceState.hasValue) {
      final records = attendanceState.value!;
      final now = DateTime.now();

      try {
        final todayRecord = records.firstWhere(
          (r) =>
              r.date.year == now.year &&
              r.date.month == now.month &&
              r.date.day == now.day,
        );

        if (todayRecord.clockIn != null) {
          formattedClockIn = formatClockIn(todayRecord.clockIn!);
        }
      } catch (_) {
        // No record today
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
            onPressed: isLogging ? null : handleAttendanceAction,
            child: Text(isLogging ? "Processing..." : "Log Attendance"),
          ),
          if (formattedClockIn.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text("Clock-in time: $formattedClockIn"),
          ],
        ],
      ),
    );
  }
}
