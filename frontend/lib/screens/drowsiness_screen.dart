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
  final List<double> _scoreHistory = []; // 점수 평균을 위한 리스트

  bool _isProcessing = false;
  double _currentEAR = 0.0; // face mesh 에서 판단한 EAR 지수
  int _modelDrowsyCounter = 0; // 모델 점수 지속 확인용
  double _drowsyScore = 0.0; // 모델이 판단한 졸음 확률
  bool _isDrowsy = false;
  int _warningCountdown = 3;
  DateTime? _drowsyStartTime;
  bool _isSeverePushed = false; // 경고 화면 중복 이동 방지
  int _frameCount = 0;
  int _blinkCount = 0; // 전체 깜빡임 횟수
  bool _isEyeClosed = false; // 현재 눈이 감겨있는 상태인지 체크

  // 눈 랜드마크 인덱스 (고정값)
  final List<int> _leftEyeIdx = [160, 144, 158, 153, 33, 133];
  final List<int> _rightEyeIdx = [385, 380, 387, 373, 263, 362];

  @override
  void initState() {
    super.initState();
    _audioPlayer.setVolume(1.0);
    _initCamera();
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
    // 2프레임당 1번만 처리
    _frameCount++;
    if (_frameCount % 2 != 0) return;

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
        // --- 깜빡임 감지 로직 ---
        // 보통 EAR 0.15~0.2 이하를 감은 것으로 판단합니다.
        if (avgEAR < 0.15) {
          _isEyeClosed = true; // 지금 눈을 감고 있음
        } else {
          // 눈을 감았다가(true였다가) 다시 떴을 때(0.15 이상이 됐을 때) 카운트 1 증가
          if (_isEyeClosed) {
            setState(() {
              _blinkCount++;
              _isEyeClosed = false;
            });
            debugPrint("✨ 깜빡임 감지! 현재 횟수: $_blinkCount");
          }
        }

        // 4. TFLite 모델 예측 추가
        // --- 추가된 좌표 변환 로직 ---
        // 모델 학습 기준: 720 x 1280
        const double targetWidth = 720.0;
        const double targetHeight = 1280.0;

        // 현재 카메라가 가로형인지 세로형인지 상관없이
        // "긴 축은 긴 축끼리, 짧은 축은 짧은 축끼리" 매칭해야 좌표가 안 찌그러집니다.
        final double srcW = (image.width > image.height)
            ? image.height.toDouble()
            : image.width.toDouble();
        final double srcH = (image.width > image.height)
            ? image.width.toDouble()
            : image.height.toDouble();
        // 좌표 스케일링: 현재 좌표 * (타겟 해상도 / 현재 해상도)
        // List<FaceMeshPoint> 타입을 유지하며 내부 값만 변경
        final List<FaceMeshPoint> scaledPoints = mesh.points.map((pt) {
          return FaceMeshPoint(
            index: pt.index,
            x: pt.x * (targetWidth / srcW),
            y: pt.y * (targetHeight / srcH),
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

  void _updateUI(double ear, double? score) async {
    const double modelUpperThreshold = 0.45; // 이 점수 넘으면 졸음 의심
    const double modelLowerThreshold = 0.35; // 이 점수 밑으로 내려가야 안심

    // 1. 모델 점수 안정화 (이동 평균)
    if (score != null) {
      _scoreHistory.add(score);
      if (_scoreHistory.length > 5) _scoreHistory.removeAt(0); // 최근 25프레임 평균
    }

    // 단순 평균 대신 가중치 부여
    double weightedSum = 0;
    double weightTotal = 0;
    for (int i = 0; i < _scoreHistory.length; i++) {
      double weight = (i + 1).toDouble(); // 최근 데이터일수록 가중치 증가
      weightedSum += _scoreHistory[i] * weight;
      weightTotal += weight;
    }

    double avgScore = _scoreHistory.isEmpty ? 0.0 : weightedSum / weightTotal;

    setState(() {
      _currentEAR = ear;
      _drowsyScore = avgScore; // 화면에는 부드러운 평균 점수 표시
    });

    // 2. 모델 판정 (점수가 높게 유지되는지 체크)
    if (avgScore > modelUpperThreshold) {
      _modelDrowsyCounter++;
    } else if (avgScore < modelLowerThreshold) {
      _modelDrowsyCounter = 0; // 확실히 눈을 떠야 초기화
    }

    bool modelDrowsy = _modelDrowsyCounter >= 5;

    if (modelDrowsy) {
      if (!_isDrowsy) {
        // *** 경고 진입 ***
        setState(() {
          _isDrowsy = true;
          _drowsyStartTime = DateTime.now();
          _warningCountdown = 3;
        });
      } else {
        // 경고 유지 및 카운트다운
        final elapsed = DateTime.now().difference(_drowsyStartTime!).inSeconds;
        setState(() {
          _warningCountdown = (3 - elapsed).clamp(0, 3);
        });

        if (elapsed >= 3 && !_isSeverePushed) {
          _isSeverePushed = true;
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SevereWarningScreen()),
          ).then((_) {
            _isSeverePushed = false;
            _modelDrowsyCounter = 0;
          });
        }
      }
    } else {
      // 정상 상태 복귀
      if (_isDrowsy && avgScore < modelLowerThreshold) {
        // 점수가 충분히 낮아지면 해제
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
                      _buildBottomInfo("졸린눈", "$_blinkCount회"), // ✨ 추가
                      _buildBottomInfo("졸음수치", _drowsyScore.toStringAsFixed(3)),
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
        ],
      ),
    );
  }

  Widget _buildBottomInfo(String label, String value) {
    final bool isWarning = label == "상태" && value == "주의";
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: isWarning ? warnYellow.withAlpha(50) : surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isWarning ? warnYellow : borderColor),
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
