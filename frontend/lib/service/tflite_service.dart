import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:google_mlkit_face_mesh_detection/google_mlkit_face_mesh_detection.dart';

class TFLiteService {
  Interpreter? _interpreter;
  // 💡 타입을 dynamic으로 선언하여 유연성을 확보합니다.
  final List<List<double>> _inputBuffer = [];
  final List<double> _scoreHistory = [];

  static const List<int> _indexMapping = [
    162,
    21,
    54,
    103,
    67,
    109,
    10,
    338,
    297,
    332,
    284,
    251,
    389,
    356,
    454,
    323,
    361,
    70,
    63,
    105,
    66,
    107,
    336,
    296,
    334,
    293,
    300,
    168,
    6,
    197,
    195,
    5,
    4,
    1,
    275,
    440,
    33,
    160,
    158,
    133,
    153,
    144,
    362,
    385,
    387,
    263,
    373,
    380,
    61,
    39,
    37,
    0,
    267,
    269,
    291,
    405,
    314,
    17,
    84,
    181,
    78,
    191,
    80,
    13,
    310,
    415,
    308,
    95,
    159,
    386,
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
    if (_interpreter == null || meshPoints.length < 468) return null;

    // 1. 현재 프레임 데이터 생성 (에러 방지를 위해 명시적 리스트 생성)
    List<double> currentFrame = [];

    for (int i = 0; i < 70; i++) {
      int mlKitIdx = _indexMapping[i];
      final p = meshPoints[mlKitIdx];

      double nx = p.x / imgHeight;
      double ny = p.y / imgWidth;

      print("🔥 Raw Score: $imgWidth : $imgHeight");

      currentFrame.add(nx);
      currentFrame.add(ny);
    }

    _inputBuffer.add(currentFrame);
    if (_inputBuffer.length > 25) {
      _inputBuffer.removeAt(0);
    }

    if (_inputBuffer.length == 25) {
      // 💡 [타입 에러 방지] dynamic 리스트로 감싸기
      var input = [_inputBuffer];
      var output = List.generate(1, (_) => List.filled(1, 0.0));

      try {
        _interpreter!.run(input, output);

        // 💡 [[값]] 형태에서 첫 번째 값 추출
        double rawScore = output[0][0];
        print("🔥 Raw Score: $rawScore");

        _scoreHistory.add(rawScore);
        if (_scoreHistory.length > 5) _scoreHistory.removeAt(0);
        return _scoreHistory.reduce((a, b) => a + b) / _scoreHistory.length;
      } catch (e) {
        print("❌ 추론 에러: $e");
        return null;
      }
    }
    return null;
  }

  void dispose() {
    _interpreter?.close();
  }
}
