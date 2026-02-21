import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_demo/service/face_mesh_service.dart';
import 'package:flutter_demo/service/tflite_service.dart';
import 'package:flutter_demo/utils/camera_utils.dart';
import 'package:google_mlkit_face_mesh_detection/google_mlkit_face_mesh_detection.dart';

class DrowsinessScreen extends StatefulWidget {
  final CameraDescription camera;

  const DrowsinessScreen({super.key, required this.camera});

  @override
  State<DrowsinessScreen> createState() => _DrowsinessScreenState();
}

class _DrowsinessScreenState extends State<DrowsinessScreen> {
  late CameraController _controller;
  final FaceMeshService _meshService = FaceMeshService();
  final TFLiteService _tfLiteService = TFLiteService();
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isProcessing = false;
  double _currentEAR = 0.0; // face mesh 에서 판단한 EAR 지수
  double _drowsyScore = 0.0; // 모델이 판단한 졸음 확률
  bool _isDrowsy = false;
  DateTime? _closedStartTime;
  DateTime? _lastProcessTime;

  // 눈 랜드마크 인덱스 (고정값)
  final List<int> _leftEyeIdx = [160, 144, 158, 153, 33, 133];
  final List<int> _rightEyeIdx = [385, 380, 387, 373, 263, 362];

  @override
  void initState() {
    super.initState();
    _audioPlayer.setVolume(1.0);
    _initCamera();
  }

  void _playBeep() async {
    try {
      // 에뮬레이터 부하를 줄이기 위해 재생 전 모드 고정
      await _audioPlayer.setPlayerMode(PlayerMode.lowLatency);
      await _audioPlayer.play(AssetSource('sound/beep.mp3'));
      debugPrint("🔔 비프음 재생 명령 전송됨");
    } catch (e) {
      debugPrint("❌ 비프음 재생 에러: $e");
    }
  }

  void _stopBeep() async {
    await _audioPlayer.stop();
  }

  /// 카메라 초기화 및 스트림 시작
  void _initCamera() async {
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.low,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    try {
      await _controller.initialize();
      if (!mounted) return;

      // 2. 카메라가 안정적으로 뜬 후에 모델 로드 (비동기)
      await _tfLiteService.loadModel();

      setState(() {});
      _controller.startImageStream(_processCameraImage);
    } catch (e) {
      debugPrint("카메라 초기화 에러: $e");
    }
  }

  /// 실시간 이미지 처리 루프
  void _processCameraImage(CameraImage image) async {
    if (_isProcessing) return;

    // 💡 150ms(약 0.5초) 마다 한 번씩만 처리하도록 제한
    final now = DateTime.now();
    if (_lastProcessTime != null &&
        now.difference(_lastProcessTime!).inMilliseconds < 500) {
      return;
    }
    _lastProcessTime = now;

    _isProcessing = true;

    try {
      // 화면 멈춤 방지를 위한 한 프레임 양보
      await Future.delayed(Duration.zero);

      // 1. 이미지 변환 (CameraUtils 사용)
      final inputImage = CameraUtils.convertCameraImageToInputImage(
        image,
        widget.camera,
      );

      // 2. 얼굴 메시 감지 (FaceMeshService 사용)
      final meshes = await _meshService.detectMesh(inputImage);

      if (meshes.isNotEmpty) {
        final mesh = meshes.first;

        // 3. EAR 계산 (CameraUtils 사용)
        final leftEAR = CameraUtils.calculateEAR(mesh.points, _leftEyeIdx);
        final rightEAR = CameraUtils.calculateEAR(mesh.points, _rightEyeIdx);
        final avgEAR = (leftEAR + rightEAR) / 2;

        // 4. TFLite 모델 예측 추가
        // --- 추가된 좌표 변환 로직 ---
        // 모델 학습 기준: 720 x 1280
        const double targetWidth = 720.0;
        const double targetHeight = 1280.0;

        // 현재 카메라 이미지 해상도 (예: 1080, 1920 등)
        final double currentWidth = image.width.toDouble();
        final double currentHeight = image.height.toDouble();

        // 좌표 스케일링: 현재 좌표 * (타겟 해상도 / 현재 해상도)
        // List<FaceMeshPoint> 타입을 유지하며 내부 값만 변경
        final List<FaceMeshPoint> scaledPoints = mesh.points.map((pt) {
          return FaceMeshPoint(
            index: pt.index,
            x: pt.x * (targetWidth / currentWidth),
            y: pt.y * (targetHeight / currentHeight),
            // 만약 z축(깊이)이나 다른 속성이 있다면 그대로 복사
            z: pt.z,
          );
        }).toList();
        // -------------------------

        // 변환된 scaledPoints를 모델에 전달
        final score = _tfLiteService.predict(
          scaledPoints,
          targetWidth, // 이제 항상 720
          targetHeight, // 이제 항상 1280
        );

        // 5. 상태 업데이트 및 졸음 판정
        _updateUI(avgEAR, score);
      }
    } catch (e) {
      debugPrint("분석 에러: $e");
    } finally {
      _isProcessing = false;
    }
  }

  /// EAR 수치 업데이트 및 2초 졸음 판정 로직
  void _updateUI(double ear, double? score) async {
    const double earThreshold = 0.21; // ear 판단 기준값
    const double modelThreshold = 0.5; // TFLite 졸음 기준값
    setState(() {
      _currentEAR = ear;
      if (score != null) _drowsyScore = score;
    });

    // 1. EAR 판정 (2초 지속되어야 함)
    bool isEarClosed = (ear < earThreshold);
    if (isEarClosed) {
      _closedStartTime ??= DateTime.now(); // 처음 눈 감았을 때 시간 기록
    } else {
      _closedStartTime = null; // 눈 뜨면 초기화
    }

    // EAR이 2초 이상 유지되었는지 확인
    bool earDrowsy =
        _closedStartTime != null &&
        DateTime.now().difference(_closedStartTime!).inSeconds >= 2;

    // 2. 모델 판정 (모델은 순간적인 판단이 중요하므로 즉시 반영하거나 짧은 지속 시간)
    // 여기서는 모델 점수가 기준치를 넘었을 때를 '졸음'으로 봅니다.
    bool modelDrowsy = (score != null && score > modelThreshold);

    // 3. 최종 결합 (OR 조건)
    // EAR이 2초 이상 낮거나, 모델이 졸음이라고 판단하면 경고!
    if (earDrowsy || modelDrowsy) {
      if (!_isDrowsy) {
        setState(() => _isDrowsy = true);
        _playBeep();
      }
    } else {
      if (_isDrowsy) {
        _stopBeep();
        setState(() => _isDrowsy = false);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _meshService.dispose();
    _tfLiteService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // 화면의 가로세로 크기
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // --- 1. 카메라 프리뷰 레이어 (회전 및 늘어짐 방지) ---
          SizedBox(
            width: size.width,
            height: size.height,
            child: FittedBox(
              fit: BoxFit.cover, // 화면 비율에 맞춰 자르고 꽉 채움 (늘어짐 방지)
              child: SizedBox(
                // 카메라의 해상도 비율에 맞춘 박스 생성
                width: _controller.value.previewSize!.height,
                height: _controller.value.previewSize!.width,
                child: RotatedBox(
                  quarterTurns: 0,
                  child: CameraPreview(_controller),
                ),
              ),
            ),
          ),

          // --- 2. 실시간 EAR 수치 & 모델 졸음 수치 표시 ---
          Positioned(
            top: 60,
            left: 20,
            child: Column(
              // Column을 사용하여 세로로 나열합니다.
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "EAR: ${_currentEAR.toStringAsFixed(3)}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 10), // 간격 추가
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(
                      alpha: 0.6,
                    ), // 모델 점수는 파란색으로 구분해볼까요?
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "Model: ${_drowsyScore.toStringAsFixed(3)}", // 변수명 수정 확인!
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // --- 3. 졸음 경고 오버레이 ---
          if (_isDrowsy)
            Container(
              color: Colors.red.withValues(alpha: 0.6),
              child: const Center(
                child: Text(
                  "졸음 경고!!",
                  style: TextStyle(
                    fontSize: 48,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
