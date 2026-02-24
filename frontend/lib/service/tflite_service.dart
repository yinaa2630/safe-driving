import 'dart:typed_data';

import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:google_mlkit_face_mesh_detection/google_mlkit_face_mesh_detection.dart';

class TFLiteService {
  Interpreter? _interpreter;
  // 💡 타입을 dynamic으로 선언하여 유연성을 확보합니다.
  final List<List<double>> _inputBuffer = [];
  final List<double> _scoreHistory = [];

  static const List<int> _indexMapping = [
    // 1. Nose Bridge (4개)
    168, 6, 197, 195,
    // 2. Left Eye (6개)
    33, 160, 158, 133, 153, 144,
    // 3. Right Eye (6개)
    362, 385, 387, 263, 373, 380,
    // 4. Lips Outer (12개)
    61, 39, 37, 0, 267, 269, 291, 405, 314, 17, 84, 181,
    // 5. Lips Inner (8개)
    78, 191, 80, 13, 310, 415, 308, 95,
  ];

  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset(
        'assets/model/drowsy_model.tflite',
      );
      print('✅ TFLite 모델 로드 성공');
    } catch (e) {
      print('❌ 모델 로드 실패: $e');
    }
  }

  double? predict(
    List<FaceMeshPoint> meshPoints,
    double imgWidth,
    double imgHeight,
  ) {
    if (_interpreter == null) return null;

    // 1. 기준점(미간 혹은 코끝) 좌표 가져오기 (168번 혹은 4번 점)
    final centerPoint = meshPoints[168];
    final double centerX = centerPoint.x;
    final double centerY = centerPoint.y;

    List<double> currentFrame = [];
    for (int i = 0; i < _indexMapping.length; i++) {
      final p = meshPoints[_indexMapping[i]];

      // 2. [핵심] 기준점으로부터의 상대적 거리 계산 후 아주 작은 상수로 스케일링
      // 코 끝에서 얼마나 떨어져 있는지만 계산합니다. (해상도 영향 거의 안 받음)
      // 0.1을 곱하는 이유는 값을 모델이 좋아하는 -1.0 ~ 1.0 범위로 대충 맞추기 위함입니다.
      double nx = (p.x - centerX) / imgWidth * 5.0 + 0.5;
      double ny = (p.y - centerY) / imgHeight * 5.0 + 0.5;

      currentFrame.add(nx.clamp(0.0, 1.0));
      currentFrame.add(ny.clamp(0.0, 1.0));
    }

    _inputBuffer.add(currentFrame);
    if (_inputBuffer.length > 25) _inputBuffer.removeAt(0);
    if (_inputBuffer.length < 25) return null;

    try {
      final inputTensor = Float32List.fromList(
        _inputBuffer.expand((e) => e).toList(),
      ).reshape([1, 25, 72]);

      var output = List.generate(1, (_) => List.filled(1, 0.0));
      _interpreter!.run(inputTensor, output);

      print('Raw Data : ${output[0][0]}');

      return output[0][0]; // 점수 확인
    } catch (e) {
      return null;
    }
  }

  void dispose() {
    _interpreter?.close();
  }
}
