import 'package:flutter/material.dart';
import 'package:flutter_demo/providers/driving_id_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_demo/service/drive_record_service.dart';
import 'package:flutter_demo/service/matching_service.dart';
import 'package:flutter_demo/providers/drive_summary_notifier.dart';

class DriveCompleteScreen extends ConsumerWidget {
  const DriveCompleteScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 더미 데이터
    // TODO : 서버에서 주행 결과 가져오기
    final minutes = 10;
    final seconds = 1;
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, size: 110, color: Colors.green),
              const SizedBox(height: 24),

              const Text(
                "주행이 완료되었어요!",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 12),
              // TODO : 주의, 경고 카운트에 따라 문구 다르게 해야함
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
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildRow(
                      Icons.access_time,
                      "총 주행 시간",
                      "${minutes}분 ${seconds}초",
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

  Widget _buildRow(IconData icon, String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.green),
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
