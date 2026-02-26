import 'package:flutter/material.dart';
import 'widgets/monthly_calendar_widget.dart';
import 'drive_chart_tab.dart';
import '../data/drive_repository.dart';
import 'package:flutter_demo/data/mock_drive_data.dart';

class DriveHistoryDetailScreen extends StatelessWidget {
  const DriveHistoryDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final records = MockDriveData.getData();

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

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              "${record.date.year}.${record.date.month}.${record.date.day}"),
                          Text("${record.duration.inMinutes}분"),
                        ],
                      ),
                      Text(
                        record.score.toStringAsFixed(0),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
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
}