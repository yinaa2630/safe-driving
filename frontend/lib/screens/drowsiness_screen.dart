import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_demo/service/face_mesh_service.dart';
import 'package:flutter_demo/utils/camera_utils.dart';

class DrowsinessScreen extends StatefulWidget {
  final CameraDescription camera;

  const DrowsinessScreen({super.key, required this.camera});

  @override
  State<DrowsinessScreen> createState() => _DrowsinessScreenState();
}

class _DrowsinessScreenState extends State<DrowsinessScreen> {
  late CameraController _controller;
  final FaceMeshService _meshService = FaceMeshService();

  bool _isProcessing = false;
  double _currentEAR = 0.0;
  bool _isDrowsy = false;
  DateTime? _closedStartTime;

  // 눈 랜드마크 인덱스 (고정값)
  final List<int> _leftEyeIdx = [160, 144, 158, 153, 33, 133];
  final List<int> _rightEyeIdx = [385, 380, 387, 373, 263, 362];

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  /// 카메라 초기화 및 스트림 시작
  void _initCamera() {
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.low, // 에뮬레이터 성능 고려
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    _controller
        .initialize()
        .then((_) {
          if (!mounted) return;
          setState(() {});
          _controller.startImageStream(_processCameraImage);
        })
        .catchError((e) => debugPrint("카메라 초기화 실패: $e"));
  }

  /// 실시간 이미지 처리 루프
  void _processCameraImage(CameraImage image) async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
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

        // 4. 상태 업데이트 및 졸음 판정
        _updateUI(avgEAR);
      }
    } catch (e) {
      debugPrint("분석 에러: $e");
    } finally {
      _isProcessing = false;
    }
  }

  /// EAR 수치 업데이트 및 2초 졸음 판정 로직
  void _updateUI(double ear) {
    const double earThreshold = 0.21;

    setState(() {
      _currentEAR = ear;
    });

    if (ear < earThreshold) {
      _closedStartTime ??= DateTime.now();
      if (DateTime.now().difference(_closedStartTime!).inSeconds >= 2) {
        if (!_isDrowsy) setState(() => _isDrowsy = true);
      }
    } else {
      _closedStartTime = null;
      if (_isDrowsy) setState(() => _isDrowsy = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _meshService.dispose();
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

          // --- 2. 실시간 EAR 수치 표시 ---
          Positioned(
            top: 60,
            left: 20,
            child: Container(
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
