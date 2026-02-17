import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_demo/screens/drowsiness_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. 사용 가능한 카메라 리스트 가져오기
  final cameras = await availableCameras();

  if (cameras.isEmpty) {
    // 카메라가 아예 없는 경우 예외 처리
    print('사용 가능한 카메라가 없습니다.');
    return;
  }

  // 2. 안전하게 카메라 선택 (전면 -> 후면 -> 첫 번째 순)
  CameraDescription selectedCamera;
  try {
    selectedCamera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
    );
  } catch (e) {
    try {
      selectedCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
      );
    } catch (e) {
      selectedCamera = cameras.first;
    }
  }

  runApp(MaterialApp(home: DrowsinessScreen(camera: selectedCamera)));
}
