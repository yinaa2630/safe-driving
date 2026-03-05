import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_demo/theme/colors.dart';
import '../models/drive_record.dart';
import '../service/drive_record_service.dart';

class DriveChartTab extends StatefulWidget {
  const DriveChartTab({super.key});

  @override
  State<DriveChartTab> createState() => _DriveChartTabState();
}

class _DriveChartTabState extends State<DriveChartTab> {
  double minX = 0;
  double maxX = 6;

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
    if (records.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        const SizedBox(height: 20),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: LineChart(
              LineChartData(
                minX: minX,
                maxX: maxX,
                minY: 0,
                maxY: 100,
                lineBarsData: [
                  LineChartBarData(
                    isCurved: true,
                    color: mainGreen.withAlpha(90),
                    spots: records
                      .asMap()
                      .entries
                      .map(
                        (e) => FlSpot(
                          e.key.toDouble(),
                          ((e.value["avgDrowsiness"] ?? 0) as num).toDouble() * 100,
                        ),
                      )
                      .toList(),
                    dotData: FlDotData(
                      getDotPainter: (spot, percent, bar, index) {
                        final date = DateTime.parse(
                          records[index]["driveDate"] ?? DateTime.now().toIso8601String(),
                        );

                        bool isToday = date.day == DateTime.now().day;

                        return FlDotCirclePainter(
                          radius: 4,
                          color: isToday ? dangerRed : mainGreen,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                if (minX > 0) {
                  setState(() {
                    minX -= 1;
                    maxX -= 1;
                  });
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward),
              onPressed: () {
                if (maxX < records.length - 1) {
                  setState(() {
                    minX += 1;
                    maxX += 1;
                  });
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}