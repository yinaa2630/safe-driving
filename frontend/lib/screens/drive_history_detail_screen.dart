import 'package:flutter/material.dart';
import 'package:flutter_demo/theme/colors.dart';
import 'package:flutter_demo/utils/format_seconds.dart';
import 'widgets/monthly_calendar_widget.dart';
import 'drive_chart_tab.dart';
// import 'package:flutter_demo/data/mock_drive_data.dart';
import '../service/drive_record_service.dart';

class DriveHistoryDetailScreen extends StatefulWidget {
  const DriveHistoryDetailScreen({super.key});

  @override
  State<DriveHistoryDetailScreen> createState() =>
      _DriveHistoryDetailScreenState();
}

class _DriveHistoryDetailScreenState extends State<DriveHistoryDetailScreen> {
  List<dynamic> records = [];

  @override
  void initState() {
    super.initState();
    loadRecords();
  }

  Future<void> loadRecords() async {
    final data = await DriveRecordService().getDriveRecords();

    setState(() {
      records = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("주행 기록"),
          bottom: const TabBar(
            tabs: [
              Tab(text: "최근 내역"),
              Tab(text: "캘린더"),
              Tab(text: "차트"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: records.length,
              itemBuilder: (context, index) {
                final record = records[index];
                final date = DateTime.parse(
                  record["driveDate"] ?? DateTime.now().toIso8601String(),
                );

                final int duration = record["duration"] ?? 0;
                final warningCount = record['warningCount'] ?? 0;
                final attentionCount = record['attentionCount'] ?? 0;
                final double score = double.parse(
                  ((record["avgDrowsiness"] ?? 0) * 100).toStringAsFixed(2),
                );

                String status;
                if (score >= 80 || warningCount > 0 || attentionCount > 3) {
                  status = "위험";
                } else if (score >= 60 || attentionCount > 1) {
                  status = "주의";
                } else {
                  status = "안전";
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _driveHistoryItem(
                    date: "${date.year}.${date.month}.${date.day}",
                    score: score,
                    duration: formatSeconds(duration),
                    attentionCount: attentionCount,
                    warningCount: warningCount,
                    status: status,
                  ),
                );
              },
            ),
            const MonthlyCalendarWidget(),
            const DriveChartTab(),
          ],
        ),
      ),
    );
  }

  Widget _driveHistoryItem({
    required String date,
    required String duration,
    required double score,
    required int attentionCount,
    required int warningCount,
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '주의',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$attentionCount',
                style: const TextStyle(fontSize: 13, color: textMedium),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '경고',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$warningCount',
                style: const TextStyle(fontSize: 13, color: textMedium),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '평균지수',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$score',
                style: const TextStyle(fontSize: 13, color: textMedium),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '상태',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                status,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: status == '안전'
                      ? mainGreen
                      : status == '주의'
                      ? warnYellow
                      : dangerRed,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
