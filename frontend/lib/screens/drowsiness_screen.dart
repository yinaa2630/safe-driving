import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_demo/screens/severe_warning_screen.dart';
import 'package:flutter_demo/service/face_mesh_service.dart';
import 'package:flutter_demo/service/tflite_service.dart';
import 'package:flutter_demo/theme/colors.dart';
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
  int _warningCountdown = 3;
  DateTime? _drowsyStartTime;
  bool _isSeverePushed = false; // 경고 화면 중복 이동 방지
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
    // EAR 또는 모델이 졸음 상태로 판단된 경우
    if (earDrowsy || modelDrowsy) {
      if (!_isDrowsy) {
        // *** 1단계 경고 진입 ***
        setState(() {
          _isDrowsy = true;
          _drowsyStartTime = DateTime.now(); // 경고 시작 시간 기록
          _warningCountdown = 3; // 카운트다운 초기화
        });

        _playBeep();
      } else {
        // 이미 졸음 상태 → 지속 시간 체크
        final elapsed = DateTime.now().difference(_drowsyStartTime!).inSeconds;

        setState(() {
          _warningCountdown = (3 - elapsed).clamp(0, 3);
        });

        // *** 3초 지속 시 2단계 강한 경고 화면 이동 ***
        if (elapsed >= 3 && !_isSeverePushed) {
          _isSeverePushed = true; // 중복 push 방지

          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => SevereWarningScreen()),
          ).then((_) {
            // 뒤로 돌아오면 다시 push 허용
            _isSeverePushed = false;
          });
        }
      }
    } else {
      // 정상 상태로 돌아간 경우
      if (_isDrowsy) {
        _stopBeep();
        setState(() {
          _isDrowsy = false;
          _drowsyStartTime = null;
          _warningCountdown = 3;
        });
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

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ---------------------------
          // 1) 카메라 화면 (배경 전체)
          // ---------------------------
          Positioned.fill(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _controller.value.previewSize!.height,
                height: _controller.value.previewSize!.width,
                child: CameraPreview(_controller),
              ),
            ),
          ),

          // ---------------------------
          // 3) 상단 상태바 - "감지 중"
          // ---------------------------
          Positioned(
            top: 60,
            left: 20,
            child: Row(
              children: [
                Icon(Icons.circle, size: 12, color: Color(0xFF1DB954)),
                const SizedBox(width: 8),
                const Text(
                  "감지 중",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // ---------------------------
          // 4) 하단 분석 패널 (검정 카드)
          // ---------------------------
          Positioned(
            left: 0,
            right: 0,
            bottom: 180,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.55),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "EYE TRACKING",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "정상 감지됨",
                        style: TextStyle(
                          color: mainGreen,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        "PERCLOS",
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      Text(
                        "${(_drowsyScore * 100).toStringAsFixed(1)}%",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ---------------------------
          // 5) 하단 바텀 시트
          // ---------------------------
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    offset: const Offset(0, -2),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 작은 바
                  Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 3개 정보 박스
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildBottomInfo("EAR", _currentEAR.toStringAsFixed(3)),
                      _buildBottomInfo(
                        "MODEL",
                        _drowsyScore.toStringAsFixed(3),
                      ),
                      _buildBottomInfo("상태", _isDrowsy ? "주의" : "정상"),
                    ],
                  ),

                  const SizedBox(height: 26),

                  // 운전 종료 버튼
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/complete');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        "운전 종료",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ---------------------------
          // 6) 졸음 경고 오버레이
          // ---------------------------
          if (_isDrowsy) _buildFirstWarningOverlay(),
        ],
      ),
    );
  }

  Widget _buildFirstWarningOverlay() {
    return SizedBox.expand(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFF7E9), Color(0xFFFFF2D9)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 아이콘
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha(50),
                border: Border.all(color: warnYellow, width: 2),
              ),
              child: Icon(Icons.bedtime_rounded, size: 60, color: warnYellow),
            ),

            SizedBox(height: 24),

            // 제목
            Text(
              "눈 감김 감지됨",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: warnYellow,
              ),
            ),

            SizedBox(height: 8),

            // 설명
            Text(
              "잠시 후에도 지속되면\n경보가 울립니다",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: textMedium),
            ),

            SizedBox(height: 20),

            // 카운트다운
            Container(
              padding: EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Text(
                "⚠ 경보 울림 · ${_warningCountdown}s 후 경보",
                style: TextStyle(
                  color: warnYellow,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            SizedBox(height: 40),

            // 버튼
            GestureDetector(
              onTap: () {
                setState(() {
                  _isDrowsy = false; // 오버레이 닫힘
                  _drowsyStartTime = null; // 타이머 초기화
                  _warningCountdown = 3;
                });
                _stopBeep(); // 혹시 소리 나고 있으면 멈춤
              },
              child: Container(
                width: 220,
                padding: EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: warnYellow, width: 1.2),
                ),
                child: Center(
                  child: Text(
                    "괜찮아요",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: warnYellow,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomInfo(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F7F4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEDEDED)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF6B6B78),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
