// lib/services/image_utils.dart
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;

/// Fast YUV420 (NV21/NV12-like) CameraImage -> RGB img.Image
/// Uses integer math (ITU-R BT.601) and bit shifts for speed.
img.Image cameraImageToImage(CameraImage image) {
  final int width = image.width;
  final int height = image.height;

  final img.Image rgbImage = img.Image(width: width, height: height);

  // Planes (Y, U, V). On most Android phones planes[0]=Y, [1]=U, [2]=V.
  final Plane planeY = image.planes[0];
  final Plane planeU = image.planes[1];
  final Plane planeV = image.planes[2];

  final Uint8List bytesY = planeY.bytes;
  final Uint8List bytesU = planeU.bytes;
  final Uint8List bytesV = planeV.bytes;

  final int strideY = planeY.bytesPerRow;
  final int strideU = planeU.bytesPerRow;
  final int pixelStrideU = planeU.bytesPerPixel ?? 1;
  final int pixelStrideV = planeV.bytesPerPixel ?? 1;

  // Local copies for speed
  final int w = width;
  final int h = height;
  final int stepY = strideY;
  final int stepU = strideU;

  // Coeffs for integer conversion (ITU-R BT.601)
  // R = (298*C + 409*E + 128) >> 8
  // G = (298*C - 100*D - 208*E + 128) >> 8
  // B = (298*C + 516*D + 128) >> 8
  const int SHIFT = 8;
  const int HALF = 128;

  for (int y = 0; y < h; y++) {
    final int yRow = y * stepY;
    final int uvRow = (y >> 1) * stepU;

    for (int x = 0; x < w; x++) {
      final int yIndex = yRow + x;
      final int uvIndex = uvRow + ((x >> 1) * pixelStrideU);

      final int Y = bytesY[yIndex] & 0xFF;
      final int U = bytesU[uvIndex] & 0xFF;
      final int V = bytesV[uvIndex] & 0xFF;

      final int C = (Y - 16).clamp(-128, 255);
      final int D = U - 128;
      final int E = V - 128;

      int R = (298 * C + 409 * E + HALF) >> SHIFT;
      int G = (298 * C - 100 * D - 208 * E + HALF) >> SHIFT;
      int B = (298 * C + 516 * D + HALF) >> SHIFT;

      // clamp
      if (R < 0)
        R = 0;
      else if (R > 255)
        R = 255;
      if (G < 0)
        G = 0;
      else if (G > 255)
        G = 255;
      if (B < 0)
        B = 0;
      else if (B > 255)
        B = 255;

      rgbImage.setPixelRgba(x, y, R, G, B, 255);
    }
  }

  return rgbImage;
}

/// Rotate rgb image using sensorOrientation (degrees)
img.Image rotateImage(img.Image src, int rotation) {
  switch (rotation) {
    case 90:
      return img.copyRotate(src, angle: 90);
    case 180:
      return img.copyRotate(src, angle: 180);
    case 270:
      return img.copyRotate(src, angle: 270);
    default:
      return src;
  }
}

/// Mirror horizontally for front camera
img.Image mirrorIfFront(img.Image src, {required bool isFront}) {
  if (!isFront) return src;
  return img.flipHorizontal(src);
}
