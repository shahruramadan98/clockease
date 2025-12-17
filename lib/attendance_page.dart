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

  Future<void> handleAttendanceAction() async {
    if (cameraController == null || !cameraController!.value.isInitialized) {
      showErrorDialog("Camera not ready. Please restart the app or check camera permissions.");
      return;
    }

    print("DEBUG: handleAttendanceAction called");
    setState(() {
      isLogging = true;
    });

    try {
      // 1️⃣ Capture image
      final XFile file = await cameraController!.takePicture();

      // 2️⃣ Detect face
      final inputImage = InputImage.fromFilePath(file.path);
      final faces = await faceDetector.processImage(inputImage);
      print("DEBUG: Detected ${faces.length} faces");

      if (faces.isEmpty) {
        showErrorDialog("Face not detected! Please ensure your face is clearly visible.");
        setState(() => isLogging = false);
        return;
      }

      // 3️⃣ Determine Action
      final controller = ref.read(attendanceControllerProvider);
      print("DEBUG: Calling getNextAction...");
      final action = await controller.getNextAction().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw Exception("Network timeout. Please check your internet connection.");
        },
      );
      print("DEBUG: Determined action: $action");

      if (action == AttendanceAction.alreadyCompleted) {
        showMessage("You have already completed attendance for today.");
        setState(() => isLogging = false);
        return;
      }

      if (action == AttendanceAction.earlyCheckOut) {
        // Confirm Early Checkout
        if (!mounted) return;
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Early clock out"),
            content: const Text(
                "You are clocking out before completing your scheduled working hours\n\nThis may affect your attendance record"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text("Clock out anyway"),
              ),
            ],
          ),
        );

        if (confirm != true) {
          setState(() => isLogging = false);
          return;
        }
      } else if (action == AttendanceAction.checkOut) {
        // Confirm Normal Checkout
        if (!mounted) return;
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Confirm clock out"),
            content: const Text(
                "Are you sure you want to clock out?\nThis will end your current work session"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text("Clock out"),
              ),
            ],
          ),
        );

        if (confirm != true) {
          setState(() => isLogging = false);
          return;
        }
      }

      // 4️⃣ Execute Action
      print("DEBUG: Calling logAttendance...");
      final result = await controller.logAttendance().timeout(
         const Duration(seconds: 10),
         onTimeout: () => throw Exception("Network timeout during logging."),
      );

      print("DEBUG: logAttendance result: $result");

      if (result['success'] == true) {
        if (action == AttendanceAction.checkIn) {
          showMessage(
            "You are now clocked in\nHave a productive day",
            subtitle: "Time recorded successfully",
          );
        } else if (action == AttendanceAction.earlyCheckOut) {
          showMessage("Clock out recorded");
        } else if (action == AttendanceAction.checkOut) {
          showMessage("You are now clocked out\nSee you next time");
        }
      } else {
        showErrorDialog(result['message'] ?? "Unknown error");
      }
    } catch (e) {
      print("DEBUG: Exception in handleAttendanceAction: $e");
      String msg = e.toString().replaceAll("Exception: ", "");
      if (msg.contains("Network timeout") || msg.contains("Client is offline")) {
        msg = "Unable to connect.\n\nPlease check your internet connection and try again.";
      }
      showErrorDialog(msg);
    }

    if (mounted) {
      setState(() {
        isLogging = false;
      });
    }
  }

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
        behavior: SnackBarBehavior.floating,
      ),
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
            onPressed: isLogging ? null : handleAttendanceAction,
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
