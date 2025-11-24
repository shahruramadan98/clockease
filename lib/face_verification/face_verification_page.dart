import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class FaceVerificationPage extends StatefulWidget {
  const FaceVerificationPage({super.key});

  @override
  State<FaceVerificationPage> createState() => _FaceVerificationPageState();
}

class _FaceVerificationPageState extends State<FaceVerificationPage> {
  CameraController? _controller;
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    initCamera();
  }

  Future<void> initCamera() async {
    final cameras = await availableCameras();

    // Use front camera
    final frontCam =
        cameras.firstWhere((cam) => cam.lensDirection == CameraLensDirection.front);

    _controller = CameraController(
      frontCam,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await _controller!.initialize();

    if (!mounted) return;
    setState(() => _isReady = true);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Face Verification"),
        backgroundColor: Color(0xFF4CBFDA),
        foregroundColor: Colors.white,
      ),

      body: Center(
        child: Column(
          children: [
            const SizedBox(height: 20),

            // CAMERA PREVIEW
            Container(
              height: 320,
              width: 260,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.black,
              ),
              child: _isReady
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: CameraPreview(_controller!),
                    )
                  : const Center(child: CircularProgressIndicator()),
            ),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);   // VERIFIED
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF3470D9),
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 12,
                ),
              ),
              child: const Text("Verify Face",
                  style: TextStyle(color: Colors.white, fontSize: 18)),
            ),

            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text("Cancel"),
            ),
          ],
        ),
      ),
    );
  }
}
