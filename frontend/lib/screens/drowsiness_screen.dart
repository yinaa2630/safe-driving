import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_demo/screens/severe_warning_screen.dart';
import 'package:flutter_demo/screens/drive_complete_screen.dart';
import 'package:flutter_demo/service/face_mesh_service.dart';
import 'package:flutter_demo/service/tflite_service.dart';
import 'package:flutter_demo/service/drive_record_service.dart';
import 'package:flutter_demo/utils/camera_utils.dart';
import 'package:google_mlkit_face_mesh_detection/google_mlkit_face_mesh_detection.dart';

class DrowsinessScreen extends StatefulWidget {
  final CameraDescription camera;
  final DateTime startTime;

  const DrowsinessScreen({
    super.key,
    required this.camera,
    required this.startTime,
  });

  @override
  State<DrowsinessScreen> createState() => _DrowsinessScreenState();
}

class _DrowsinessScreenState extends State<DrowsinessScreen> {
  late CameraController _controller;

  final FaceMeshService _meshService = FaceMeshService();
  final TFLiteService _tfLiteService = TFLiteService();
  final DriveRecordService _driveService = DriveRecordService();
  final AudioPlayer _audioPlayer = AudioPlayer();

  final List<double> _scoreHistory = [];

  bool _isProcessing = false;
  double _currentEAR = 0.0;
  double _drowsyScore = 0.0;

  int _modelDrowsyCounter = 0;
  int _frameCount = 0;
  int _blinkCount = 0;
  int _severeCount = 0;

  bool _isEyeClosed = false;
  bool _isSeverePushed = false;

  final List<int> _leftEyeIdx = [160, 144, 158, 153, 33, 133];
  final List<int> _rightEyeIdx = [385, 380, 387, 373, 263, 362];

  @override
  void initState() {
    super.initState();
    _audioPlayer.setVolume(1.0);
    _initCamera();
  }

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

      await _tfLiteService.loadModel();
      setState(() {});
      _controller.startImageStream(_processCameraImage);
    } catch (e) {
      debugPrint("카메라 초기화 에러: $e");
    }
  }

  void _processCameraImage(CameraImage image) async {
    if (_isProcessing) return;

    _frameCount++;
    if (_frameCount % 2 != 0) return;

    _isProcessing = true;

    try {
      final inputImage =
          CameraUtils.convertCameraImageToInputImage(image, widget.camera);

      final meshes = await _meshService.detectMesh(inputImage);

      if (meshes.isNotEmpty) {
        final mesh = meshes.first;

        final leftEAR =
            CameraUtils.calculateEAR(mesh.points, _leftEyeIdx);
        final rightEAR =
            CameraUtils.calculateEAR(mesh.points, _rightEyeIdx);

        final avgEAR = (leftEAR + rightEAR) / 2;

        if (avgEAR < 0.15) {
          _isEyeClosed = true;
        } else {
          if (_isEyeClosed) {
            _blinkCount++;
            _isEyeClosed = false;
          }
        }

        const double targetWidth = 720.0;
        const double targetHeight = 1280.0;

        final double srcW =
            (image.width > image.height)
                ? image.height.toDouble()
                : image.width.toDouble();
        final double srcH =
            (image.width > image.height)
                ? image.width.toDouble()
                : image.height.toDouble();

        final scaledPoints = mesh.points.map((pt) {
          return FaceMeshPoint(
            index: pt.index,
            x: pt.x * (targetWidth / srcW),
            y: pt.y * (targetHeight / srcH),
            z: pt.z,
          );
        }).toList();

        final score = _tfLiteService.predict(
          scaledPoints,
          targetWidth,
          targetHeight,
        );

        _updateUI(avgEAR, score);
      }
    } catch (e) {
      debugPrint("분석 에러: $e");
    } finally {
      _isProcessing = false;
    }
  }

  void _updateUI(double ear, double? score) {
    const double upper = 0.5;
    const double lower = 0.4;

    if (score != null) {
      _scoreHistory.add(score);
      if (_scoreHistory.length > 5) {
        _scoreHistory.removeAt(0);
      }
    }

    double avgScore = 0.0;
    if (_scoreHistory.isNotEmpty) {
      avgScore =
          _scoreHistory.reduce((a, b) => a + b) /
          _scoreHistory.length;
    }

    setState(() {
      _currentEAR = ear;
      _drowsyScore = avgScore;
    });

    if (avgScore > upper) {
      _modelDrowsyCounter++;
    } else if (avgScore < lower) {
      _modelDrowsyCounter = 0;
    }

    if (_modelDrowsyCounter >= 5 && !_isSeverePushed) {
      _isSeverePushed = true;
      _severeCount++;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const SevereWarningScreen(),
        ),
      ).then((_) {
        _modelDrowsyCounter = 0;
        _isSeverePushed = false;
      });
    }
  }

  String _getStatusText() {
    if (_drowsyScore > 0.5) return "위험";
    if (_drowsyScore > 0.4) return "주의";
    return "정상";
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
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: CameraPreview(_controller),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      _buildInfo("EAR", _currentEAR.toStringAsFixed(3)),
                      _buildInfo("깜빡임", "$_blinkCount회"),
                      _buildInfo("MODEL", _drowsyScore.toStringAsFixed(3)),
                      _buildInfo("상태", _getStatusText()),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () async {
                      final endTime = DateTime.now();
                      final duration =
                          endTime.difference(widget.startTime);

                      final success =
                          await _driveService.createDriveRecord(
                        driveDate: widget.startTime
                            .toIso8601String()
                            .split("T")[0],
                        startTime: widget.startTime,
                        endTime: endTime,
                        duration: duration.inSeconds,
                        avgDrowsiness: _drowsyScore,
                        warningCount: _severeCount,
                      );

                      if (success) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                DriveCompleteScreen(
                                    duration: duration),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                    ),
                    child: const Text("운전 종료"),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfo(String label, String value) {
    return Column(
      children: [
        Text(label),
        const SizedBox(height: 4),
        Text(
          value,
          style:
              const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}