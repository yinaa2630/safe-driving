import 'package:flutter/material.dart';
import 'package:flutter_demo/providers/driving_id_notifier.dart';
import 'package:flutter_demo/theme/colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'widgets/monthly_calendar_widget.dart';
import 'drowsiness_screen.dart';
import 'package:camera/camera.dart';
import 'package:flutter_demo/service/matching_service.dart';
import 'package:flutter_demo/service/drive_record_service.dart';

class MainScreen extends ConsumerWidget {
  final CameraDescription camera;

  const MainScreen({super.key, required this.camera});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),

                    const Text(
                      "안녕하세요 👋",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),

                    const SizedBox(height: 6),

                    const Text(
                      "오늘도 안전하게 운전해볼까요?",
                      style: TextStyle(fontSize: 14, color: textMedium),
                    ),

                    const SizedBox(height: 32),

                    _buildStartCard(context, ref),

                    const SizedBox(height: 32),

                    const Text(
                      "최근 주행 기록",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),

                    const SizedBox(height: 16),

                    _driveHistoryItem(
                      date: "2026. 02. 20",
                      duration: "36분",
                      status: "안전",
                    ),

                    const SizedBox(height: 12),

                    _driveHistoryItem(
                      date: "2026. 02. 18",
                      duration: "1시간 12분",
                      status: "주의 발생 1회",
                    ),

                    const SizedBox(height: 32),

                    const Text(
                      "이번 달 주행 상태",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),

                    const SizedBox(height: 16),

                    const MonthlyCalendarWidget(),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),

            _buildBottomNav(context),
            const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildStartCard(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgWhite,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "주행 보조 시작",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text(
            "AI가 운전 중 졸음을 실시간으로 감지해 알려드려요.",
            style: TextStyle(fontSize: 14, color: textMedium),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: mainGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () async {
                final startTime = DateTime.now();
                final driveService = DriveRecordService();
                final matchingService = MatchingService();

                try {
                  // 현재 위치 가져오기
                  final pos = await matchingService.getCurrentLocation();

                  final driveId = await driveService.startDrive(
                    driveDate: startTime.toIso8601String(),
                    startTime: startTime,
                    startLat: pos.latitude,
                    startLng: pos.longitude,
                  );

                  if (driveId != null) {
                    ref.read(drivingIdProvider.notifier).setId(driveId.toString());

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DrowsinessScreen(camera: camera),
                      ),
                    );
                  } else {
                    print("❌ drive_record 생성 실패");
                  }
                } catch (e) {
                  print("❌ 위치 가져오기 실패: $e");
                }
              },
              
              child: const Text(
                "주행 시작하기",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: bgWhite,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          const Icon(Icons.home_filled, color: mainGreen, size: 30),
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, '/matching');
            },
            icon: const Icon(Icons.map, color: textMedium, size: 28),
          ),
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, '/profile');
            },
            icon: const Icon(Icons.person, color: textMedium, size: 28),
          ),
        ],
      ),
    );
  }

  Widget _driveHistoryItem({
    required String date,
    required String duration,
    required String status,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                date,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                duration,
                style: const TextStyle(fontSize: 13, color: textMedium),
              ),
            ],
          ),
          Text(
            status,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: mainGreen,
            ),
          ),
        ],
      ),
    );
  }
}
