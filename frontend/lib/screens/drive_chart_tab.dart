import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_demo/theme/colors.dart';
import '../data/drive_repository.dart';
import '../models/drive_record.dart';
import 'package:flutter_demo/data/drive_repository.dart';
import 'package:flutter_demo/data/mock_drive_data.dart';

class DriveChartTab extends StatefulWidget {
  const DriveChartTab({super.key});

  @override
  State<DriveChartTab> createState() => _DriveChartTabState();
}

class _DriveChartTabState extends State<DriveChartTab> {
  double minX = 0;
  double maxX = 6;

  final List<DriveRecord> records = MockDriveData.getData();

  @override
  Widget build(BuildContext context) {
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
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (touchedSpot) => bgWhite,
                    getTooltipItems: (spots) {
                      return spots.map((spot) {
                        return LineTooltipItem(
                          spot.y.toString(),
                          TextStyle(
                            color: mainGreen, // 원하는 텍스트 색
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    isCurved: true,
                    color: mainGreen.withAlpha(90),
                    spots: records
                        .asMap()
                        .entries
                        .map((e) => FlSpot(e.key.toDouble(), e.value.score))
                        .toList(),
                    dotData: FlDotData(
                      getDotPainter: (spot, percent, bar, index) {
                        bool isToday =
                            records[index].date.day == DateTime.now().day;
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
