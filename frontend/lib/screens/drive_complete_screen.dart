import 'package:flutter/material.dart';
import 'package:flutter_demo/providers/driving_id_notifier.dart';
import 'package:flutter_demo/theme/colors.dart';
import 'package:flutter_demo/utils/seconds_formatter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_demo/service/drive_record_service.dart';
import 'package:flutter_demo/service/matching_service.dart';
import 'package:flutter_demo/providers/drive_summary_notifier.dart';

class DriveCompleteScreen extends ConsumerWidget {
  const DriveCompleteScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final driveSummary = ref.read(driveSummaryProvider);
    bool status = true;
    int duration = 0; // 총주행시간(초)
    int attentionCount = 0; // WARNING 횟수
    int warningCount = 0; // ATTENTION 횟수
    if (driveSummary != null) {
      duration = driveSummary.duration;
      attentionCount = driveSummary.attentionCount;
      warningCount = driveSummary.warningCount;
    }

    if (warningCount > 0 || attentionCount > 3) status = false;
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle,
                size: 110,
                color: status ? mainGreen : warnYellow,
              ),
              const SizedBox(height: 24),

              const Text(
                "주행이 완료되었어요!",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 12),
              if (warningCount > 0 || attentionCount > 3)
                const Text(
                  "앞으로 주의하셔야겠어요.",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                )
              else
                const Text(
                  "오늘도 안전 운전 하셨어요.",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),

              const SizedBox(height: 32),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(50),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildRow(
                      Icons.access_time,
                      "총 주행 시간",
                      secondsFormatter(duration),
                      normal: status,
                    ),
                    _buildRow(
                      Icons.access_time,
                      "주의 횟수",
                      "$attentionCount회",
                      normal: status,
                    ),
                    _buildRow(
                      Icons.access_time,
                      "경고 횟수",
                      "$warningCount회",
                      normal: status,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    final driveIdStr = ref.read(drivingIdProvider);
                    final summary = ref.read(driveSummaryProvider);

                    if (driveIdStr == null || summary == null) {
                      Navigator.pushNamed(context, '/main');
                      return;
                    }

                    final driveId = int.tryParse(driveIdStr);
                    if (driveId == null) {
                      Navigator.pushNamed(context, '/main');
                      return;
                    }

                    final driveService = DriveRecordService();
                    final matchingService = MatchingService();

                    try {
                      final pos = await matchingService.getCurrentLocation();

                      final success = await driveService.endDrive(
                        driveId: driveId,
                        endTime: DateTime.now(),
                        duration: summary.duration,
                        avgDrowsiness: summary.avgDrowsiness,
                        warningCount: summary.warningCount,
                        attentionCount: summary.attentionCount,
                        endLat: pos.latitude,
                        endLng: pos.longitude,
                      );

                      if (success) {
                        ref.read(drivingIdProvider.notifier).clear();
                        ref.read(driveSummaryProvider.notifier).clear();
                        Navigator.pushNamed(context, '/main');
                      }
                    } catch (e) {
                      print("❌ 종료 처리 중 에러: $e");
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    "홈으로 돌아가기",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(
    IconData icon,
    String title,
    String value, {
    bool normal = true,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: normal ? mainGreen : warnYellow),
            const SizedBox(width: 10),
            Text(title, style: const TextStyle(fontSize: 16)),
          ],
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
