import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_demo/theme/colors.dart';
import 'package:url_launcher/url_launcher.dart';

class SevereWarningScreen extends StatefulWidget {
  const SevereWarningScreen({super.key});

  @override
  State<SevereWarningScreen> createState() => _SevereWarningScreenState();
}

class _SevereWarningScreenState extends State<SevereWarningScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
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

  Future<void> makePhoneCall(String phoneNumber) async {
    final Uri url = Uri(scheme: 'tel', path: phoneNumber);

    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      print('전화 앱을 열 수 없습니다.');
    }
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
                onPressed: () {
                  // TODO : 주행 종료로 서버에 데이터 전송
                  // 네비게이션에서 matching 라우팅으로 이동하되
                  // 기존 히스토리 지우고 직전 페이지를 /main로 설정
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/matching',
                    (route) => route.settings.name == '/main',
                  );
                },
                child: Text(
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
                onPressed: () {
                  // TODO : 전화번호의 경우 userInfo에서 받아와야함(로그인시 provider로 관리할지?)
                  makePhoneCall('01012345678');
                },
                child: Text(
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
