// lib/features/attendance/face_verification_page.dart

import 'dart:io';
import 'package:camera/camera.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../services/face_detector_service.dart';
// import '../../services/attendance_service.dart';

class FaceVerificationPage extends StatefulWidget {
  const FaceVerificationPage({super.key});

  @override
  State<FaceVerificationPage> createState() => _FaceVerificationPageState();
}

class _FaceVerificationPageState extends State<FaceVerificationPage> {
  CameraController? _camera;
  bool _isProcessing = false;
  bool _autoTriggered = false;
  bool _cameraReady = false;

  final FaceDetectorService _faceDetector = FaceDetectorService();
  // final AttendanceService _attendanceService = AttendanceService(); (Removed)

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    if (kIsWeb || Platform.isIOS) {
      // iOS Simulator or Web has no camera → avoid infinite loading
      _show("Camera not supported on this device.");
      return;
    }

    try {
      final cams = await availableCameras();
      if (cams.isEmpty) {
        _show("No camera found");
        return;
      }

      final front = cams.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cams.first,
      );

      _camera = CameraController(
        front,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _camera!.initialize();

      if (!mounted) return;

      setState(() => _cameraReady = true);
      _startStream();
    } catch (e) {
      _show("Camera error: $e");
    }
  }

  void _startStream() {
    if (_camera == null || !_camera!.value.isInitialized) return;

    _camera!.startImageStream((frame) async {
      if (_autoTriggered || _isProcessing) return;

      _isProcessing = true;

      try {
        final result = await _faceDetector.detectAndCrop(
          frame,
          _camera!.description.sensorOrientation,
        );

        if (result != null) {
          _autoTriggered = true;
          await _processAutoCapture();
        }
      } catch (e) {
        debugPrint("Stream error: $e");
      }

      _isProcessing = false;
    });
  }

  Future<void> _processAutoCapture() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _show("Sila login dahulu");
      return;
    }

    try {
      await _camera!.stopImageStream();

      // wait before taking picture
      await Future.delayed(const Duration(milliseconds: 300));

      if (!_camera!.value.isInitialized) return;

      final file = await _camera!.takePicture();
      final path = file.path;

      // Validate face
      final validation = await _faceDetector.validateSelfieFromPath(path);
      if (!validation.success) {
        _show(validation.message);
        _autoTriggered = false;

        // Restart stream safely
        await Future.delayed(const Duration(milliseconds: 300));
        _startStream();
        return;
      }

      // Return result to previous page (Dashboard)
      if (mounted) Navigator.pop(context, path);
      
    } catch (e) {
      _show("Ralat: $e");
      _autoTriggered = false;

      await Future.delayed(const Duration(milliseconds: 300));
      _startStream();
    }
  }

  void _show(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    _camera?.dispose();
    _faceDetector.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Face Verification")),
      body: _cameraReady
          ? CameraPreview(_camera!)
          : const Center(child: CircularProgressIndicator()),
    );
  }
}
