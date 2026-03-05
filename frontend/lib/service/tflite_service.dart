import 'dart:math';
import 'dart:typed_data';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:google_mlkit_face_mesh_detection/google_mlkit_face_mesh_detection.dart';

class TFLiteService {
  Interpreter? _interpreter;

  // [최적화 핵심] 매번 리스트를 새로 만들지 않도록 미리 할당
  static const int frameCount = 25;
  static const int frameSize = 72;

  final List<List<double>> _inputBuffer = [];

  // Dlib 학습 순서에 맞춘 인덱스 매핑
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
  // 인덱스 에러 방지를 위한 최대 인덱스 미리 계산
  final int _maxIndex = _indexMapping.reduce(max);

  Future<void> loadModel() async {
    final options = InterpreterOptions();
    options.addDelegate(XNNPackDelegate()); // 안드로이드 CPU 가속
    try {
      _interpreter = await Interpreter.fromAsset(
        'assets/model/drowsy_model_gru.tflite',
        options: options,
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
    if (_interpreter == null ||
        meshPoints.isEmpty ||
        meshPoints.length <= _maxIndex) {
      return null;
    }

    try {
      final center = meshPoints[168];
      final double cx = center.x;
      final double cy = center.y;

      // 1. 현재 프레임 데이터 생성 (72개)
      final List<double> currentFrame = List.generate(72, (i) => 0.0);
      for (int i = 0; i < _indexMapping.length; i++) {
        final p = meshPoints[_indexMapping[i]];
        currentFrame[i * 2] = (p.x - cx) / imgWidth;
        currentFrame[i * 2 + 1] = (p.y - cy) / imgHeight;
      }

      // 2. 버퍼에 추가 (최대 25개 유지)
      _inputBuffer.add(currentFrame);
      if (_inputBuffer.length > 25) _inputBuffer.removeAt(0);

      // 25개가 꽉 찰 때까지는 계산 안 함
      if (_inputBuffer.length < 25) return null;

      // 3. 🌟 [핵심] for문 없이 바로 3차원 리스트 구조 생성
      // 껍데기([])를 씌워서 [1, 25, 72] 형상을 만듭니다.
      // _inputBuffer는 이미 [ [72개], [72개] ... ] 인 2차원 리스트입니다.
      final finalInput = [_inputBuffer];

      // 4. 출력용 버퍼 (모델 결과가 1개인 경우)
      final output = List.generate(1, (_) => List.filled(1, 0.0));

      // 5. 실행
      // 이제 subtype 에러 없이 TFLite가 알아서 내부 데이터를 가져갑니다.
      _interpreter!.run(finalInput, output);

      return output[0][0];
    } catch (e) {
      print("Inference Error (No-For-Loop): $e");
      return null;
    }
  }

  void dispose() {
    _interpreter?.close();
  }
}
