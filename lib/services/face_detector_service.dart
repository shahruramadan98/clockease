// lib/services/face_detector_service.dart

import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show WriteBuffer;
import 'package:image/image.dart' as img;
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import 'image_utils.dart';

class FaceCropResult {
  final img.Image image;
  final Face face;

  FaceCropResult(this.image, this.face);
}

class FaceValidationResult {
  final bool success;
  final String message;
  final Face? face;

  FaceValidationResult(this.success, this.message, {this.face});
}

class FaceDetectorService {
  late final FaceDetector _detector;

  FaceDetectorService() {
    _detector = FaceDetector(
      options: FaceDetectorOptions(
        performanceMode: FaceDetectorMode.accurate,
        enableClassification: true,
        enableLandmarks: true,
        minFaceSize: 0.1,
      ),
    );
  }

  Future<FaceCropResult?> detectAndCrop(
    CameraImage cameraImage,
    int rotation,
  ) async {
    try {
      final inputImage = _convertCameraFrame(cameraImage, rotation);
      final faces = await _detector.processImage(inputImage);
      if (faces.isEmpty) return null;

      final face = faces.first;

      img.Image rgb = cameraImageToImage(cameraImage);
      rgb = rotateImage(rgb, rotation);
      rgb = mirrorIfFront(rgb, isFront: true);

      final rect = face.boundingBox;

      int left = rect.left.toInt().clamp(0, rgb.width - 1);
      int top = rect.top.toInt().clamp(0, rgb.height - 1);
      int right = rect.right.toInt().clamp(1, rgb.width);
      int bottom = rect.bottom.toInt().clamp(1, rgb.height);

      final pad = ((right - left) * 0.20).toInt();
      left = (left - pad).clamp(0, rgb.width - 1);
      right = (right + pad).clamp(1, rgb.width);
      top = (top - pad).clamp(0, rgb.height - 1);
      bottom = (bottom + pad).clamp(1, rgb.height);

      final cropped = img.copyCrop(
        rgb,
        x: left,
        y: top,
        width: (right - left),
        height: (bottom - top),
      );

      final resized = img.copyResize(cropped, width: 112, height: 112);

      return FaceCropResult(resized, face);
    } catch (e) {
      debugPrint("detectAndCrop error: $e");
      return null;
    }
  }

  Future<FaceValidationResult> validateSelfieFromPath(String path) async {
    try {
      final inputImage = InputImage.fromFilePath(path);
      final faces = await _detector.processImage(inputImage);

      if (faces.isEmpty) {
        return FaceValidationResult(false, "Tiada wajah dikesan");
      }

      if (faces.length > 1) {
        return FaceValidationResult(false, "Hanya satu wajah dibenarkan");
      }

      final face = faces.first;

      final left = face.leftEyeOpenProbability;
      final right = face.rightEyeOpenProbability;

      if ((left != null && left < 0.3) || (right != null && right < 0.3)) {
        return FaceValidationResult(false, "Pastikan mata terbuka");
      }

      final yaw = face.headEulerAngleY ?? 0;
      if (yaw.abs() > 25) {
        return FaceValidationResult(false, "Menghadap kamera secara frontal");
      }

      final file = File(path);
      final decoded = img.decodeImage(await file.readAsBytes());
      if (decoded == null) {
        return FaceValidationResult(false, "Gambar tidak sah");
      }

      if (face.boundingBox.height < decoded.height * 0.22) {
        return FaceValidationResult(false, "Wajah terlalu kecil");
      }

      final brightness = _estimateBrightness(decoded);
      if (brightness < 40) {
        return FaceValidationResult(false, "Gambar terlalu gelap");
      }

      return FaceValidationResult(true, "Selfie diterima", face: face);
    } catch (e) {
      return FaceValidationResult(false, "Ralat: $e");
    }
  }

  double _estimateBrightness(img.Image image) {
    int total = 0;
    int count = 0;
    const int step = 16;

    for (int y = 0; y < image.height; y += step) {
      for (int x = 0; x < image.width; x += step) {
        final pixel = image.getPixel(x, y);
        final int r = pixel.r.toInt();
        final int g = pixel.g.toInt();
        final int b = pixel.b.toInt();

        total += ((r + g + b) ~/ 3);
        count++;
      }
    }

    return count == 0 ? 0 : (total / count);
  }

  InputImage _convertCameraFrame(CameraImage image, int rotation) {
    final WriteBuffer buffer = WriteBuffer();
    for (final plane in image.planes) {
      buffer.putUint8List(plane.bytes);
    }

    return InputImage.fromBytes(
      bytes: buffer.done().buffer.asUint8List(),
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: _rotationFromDegrees(rotation),
        format: InputImageFormat.nv21,
        bytesPerRow: image.planes[0].bytesPerRow,
      ),
    );
  }

  InputImageRotation _rotationFromDegrees(int d) {
    switch (d) {
      case 90:
        return InputImageRotation.rotation90deg;
      case 180:
        return InputImageRotation.rotation180deg;
      case 270:
        return InputImageRotation.rotation270deg;
      default:
        return InputImageRotation.rotation0deg;
    }
  }

  void dispose() => _detector.close();
}
