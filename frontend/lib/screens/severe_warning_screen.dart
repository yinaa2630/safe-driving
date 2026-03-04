import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_demo/providers/drive_summary_notifier.dart';
import 'package:flutter_demo/providers/driving_id_notifier.dart';
import 'package:flutter_demo/providers/me_data_notifier.dart';
import 'package:flutter_demo/service/drive_record_service.dart';
import 'package:flutter_demo/service/matching_service.dart';
import 'package:flutter_demo/theme/colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

class SevereWarningScreen extends ConsumerStatefulWidget {
  const SevereWarningScreen({super.key});

  @override
  ConsumerState<SevereWarningScreen> createState() =>
      _SevereWarningScreenState();
}

class _SevereWarningScreenState extends ConsumerState<SevereWarningScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isFinding = false; // 가까운 휴게소 찾을시 UI 로딩
  bool _isCalling = false; // 비상연락시 UI 로딩

  @override
  void initState() {
    super.initState();
    _audioPlayer.setVolume(1.0);
    _playBeep();
  }

  void _playBeep() async {
    try {
      // 에뮬레이터 부하를 줄이기 위해 재생 전 모드 고정
      await _audioPlayer.setPlayerMode(PlayerMode.mediaPlayer);
      await _audioPlayer.play(AssetSource('sound/beep.mp3'));
      debugPrint("🔔 비프음 재생 명령 전송됨");
    } catch (e) {
      debugPrint("❌ 비프음 재생 에러: $e");
    }
  }

  void _stopBeep() async {
    await _audioPlayer.stop();
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri url = Uri(scheme: 'tel', path: phoneNumber);

    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      print('전화 앱을 열 수 없습니다.');
    }
  }

  Future<bool> _endDrive() async {
    final driveSummary = ref.read(driveSummaryProvider);
    final driveIdStr = ref.read(drivingIdProvider);

    if (driveSummary == null || driveIdStr == null) return false;

    final driveId = int.parse(driveIdStr);
    final driveService = DriveRecordService();
    final matchingService = MatchingService();

    final pos = await matchingService.getCurrentLocation();

    return await driveService.endDrive(
      driveId: driveId,
      endTime: DateTime.now(),
      duration: driveSummary.duration,
      avgDrowsiness: driveSummary.avgDrowsiness,
      warningCount: driveSummary.warningCount,
      attentionCount: driveSummary.attentionCount,
      endLat: pos.latitude,
      endLng: pos.longitude,
    );
  }

  @override
  void dispose() {
    _stopBeep();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning_amber_rounded, size: 80, color: dangerRed),

            SizedBox(height: 20),

            Text(
              "졸음운전 감지!",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: dangerRed,
              ),
            ),

            SizedBox(height: 10),

            Text(
              "지금 바로 안전한 곳에\n정차해 주세요",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: textMedium),
            ),

            SizedBox(height: 40),

            // 가까운 휴게소 찾기 버튼
            SizedBox(
              width: 240,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: dangerRed,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isFinding
                    ? null
                    : () async {
                        setState(() {
                          _isFinding = true;
                        });
                        try {
                          final success = await _endDrive();
                          if (success && mounted) {
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              '/matching',
                              (route) => route.settings.name == '/main',
                            );
                          }
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("휴게소 찾기 처리 에러")),
                          );
                        } finally {
                          if (mounted) {
                            setState(() {
                              _isFinding = false;
                            });
                          }
                        }
                      },
                child: _isFinding
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text(
                        "🚨 가까운 휴게소 찾기",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),

            SizedBox(height: 12),

            // 전화걸기 버튼
            SizedBox(
              width: 240,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: warnYellow,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isCalling
                    ? null
                    : () async {
                        setState(() {
                          _isCalling = true;
                        });
                        try {
                          final success = await _endDrive();
                          if (!success) return;

                          final meData = ref.read(meDataProvider);
                          if (meData == null) return;

                          await _makePhoneCall(meData.emergencyCall);

                          if (mounted) {
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              '/main',
                              (route) => route.settings.name == '/main',
                            );
                          }
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("통화 처리 에러")),
                          );
                        } finally {
                          if (mounted) {
                            setState(() {
                              _isCalling = false;
                            });
                          }
                        }
                      },
                child: _isCalling
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text(
                        "📞 비상 연락하기",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),

            SizedBox(height: 12),
            // 계속 주행 버튼
            SizedBox(
              width: 240,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent, // 배경 투명
                  shadowColor: Colors.transparent, // 그림자 제거
                  elevation: 0, // 높이 제거
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12), // 라운드
                    side: BorderSide(
                      // 테두리
                      color: dangerRed,
                      width: 1,
                    ),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(
                  "괜찮아요, 계속 주행",
                  style: TextStyle(
                    color: dangerRed,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
