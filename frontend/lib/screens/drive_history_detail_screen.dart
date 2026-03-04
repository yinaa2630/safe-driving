import 'package:flutter/material.dart';
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
                            record["driveDate"],
                          ),
                          Text("${(record["duration"] ?? 0) ~/ 60}분"),
                        ],
                      ),
                      Text(
                        ((record["avgDrowsiness"] ?? 0) * 100).toStringAsFixed(0),
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