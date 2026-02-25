import 'dart:typed_data';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:google_mlkit_face_mesh_detection/google_mlkit_face_mesh_detection.dart';

class TFLiteService {
  Interpreter? _interpreter;

  // 💡 데이터 버퍼: 25프레임을 담는 용도
  final List<List<double>> _inputBuffer = [];

  // 💡 [최적화 핵심] 매번 리스트를 새로 만들지 않도록 미리 할당 (1 * 25 * 72)
  final Float32List _inputMatrix = Float32List(25 * 72);

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

  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset(
        'assets/model/drowsy_model_gru.tflite',
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

    final center = meshPoints[168]; // 미간 기준점
    List<double> currentFrame = [];

    // 1. 전처리: 상대 좌표 계산
    for (int idx in _indexMapping) {
      final p = meshPoints[idx];
      currentFrame.add((p.x - center.x) / imgWidth);
      currentFrame.add((p.y - center.y) / imgHeight);
    }

    // 2. 슬라이딩 윈도우 업데이트
    _inputBuffer.add(currentFrame);
    if (_inputBuffer.length > 25) _inputBuffer.removeAt(0);
    if (_inputBuffer.length < 25) return null; // 25프레임 찰 때까지 대기

    try {
      // 3. 💡 [최적화] expand().toList() 대신 고정된 메모리에 값만 복사
      int offset = 0;
      for (int i = 0; i < _inputBuffer.length; i++) {
        final frame = _inputBuffer[i];
        for (int j = 0; j < frame.length; j++) {
          _inputMatrix[offset++] = frame[j];
        }
      }

      // 4. 추론 실행
      final inputTensor = _inputMatrix.reshape([1, 25, 72]);

      // 출력 텐서 모양 정의 (1행 1열)
      var output = List.generate(1, (_) => List.filled(1, 0.0));

      _interpreter!.run(inputTensor, output);

      return output[0][0]; // 0.0 ~ 1.0 사이의 졸음 확률 반환
    } catch (e) {
      print("Inference Error: $e");
      return null;
    }
  }

  void dispose() {
    _interpreter?.close();
  }
}
