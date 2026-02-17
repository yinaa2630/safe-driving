import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_mesh_detection/google_mlkit_face_mesh_detection.dart';

class CameraUtils {
  // EAR 계산 로직
  static double calculateEAR(List<FaceMeshPoint> points, List<int> idx) {
    double v1 = _dist(points[idx[0]], points[idx[1]]);
    double v2 = _dist(points[idx[2]], points[idx[3]]);
    double h = _dist(points[idx[4]], points[idx[5]]);
    return (v1 + v2) / (2.0 * h);
  }

  static double _dist(FaceMeshPoint p1, FaceMeshPoint p2) =>
      sqrt(pow(p1.x - p2.x, 2) + pow(p1.y - p2.y, 2));

  // 이미지 변환 로직
  static InputImage convertCameraImageToInputImage(
    CameraImage image,
    CameraDescription camera,
  ) {
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation:
            InputImageRotationValue.fromRawValue(camera.sensorOrientation) ??
            InputImageRotation.rotation0deg,
        format: InputImageFormat.nv21,
        bytesPerRow: image.planes[0].bytesPerRow,
      ),
    );
  }
}
