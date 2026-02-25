import 'package:flutter/material.dart';
import 'package:flutter_demo/theme/colors.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../data/drive_repository.dart';
import '../../models/drive_record.dart';

enum DriveStatus { none, good, normal, bad }

class MonthlyCalendarWidget extends StatefulWidget {
  const MonthlyCalendarWidget({super.key});

  @override
  State<MonthlyCalendarWidget> createState() => _MonthlyCalendarWidgetState();
}

class _MonthlyCalendarWidgetState extends State<MonthlyCalendarWidget> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  final List<DriveRecord> records = DriveRepository.getMockData();

  DriveStatus _getStatus(DateTime day) {
    for (var record in records) {
      if (record.date.year == day.year &&
          record.date.month == day.month &&
          record.date.day == day.day) {
        if (record.score >= 80) return DriveStatus.good;
        if (record.score >= 60) return DriveStatus.normal;
        return DriveStatus.bad;
      }
    }
    return DriveStatus.none;
  }

  @override
  Widget build(BuildContext context) {
    return TableCalendar(
      focusedDay: _focusedDay,
      firstDay: DateTime(2020),
      lastDay: DateTime(2030),
      headerStyle: const HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
      ),
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
        });
      },
      calendarBuilders: CalendarBuilders(
        defaultBuilder: (context, day, focusedDay) {
          return _buildDayCell(day, _getStatus(day));
        },
        todayBuilder: (context, day, focusedDay) {
          return _buildDayCell(day, _getStatus(day), isToday: true);
        },
      ),
    );
  }

  Widget _buildDayCell(
    DateTime day,
    DriveStatus status, {
    bool isToday = false,
  }) {
    String emoji = switch (status) {
      DriveStatus.good => "🥰",
      DriveStatus.normal => "🙁",
      DriveStatus.bad => "😡",
      _ => "-",
    };

    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: isToday
            ? Border.all(color: mainGreen, width: 1.5)
            : Border.all(color: Colors.grey.shade300),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 4,
            left: 4,
            child: Text("${day.day}", style: const TextStyle(fontSize: 10)),
          ),
          Center(child: Text(emoji, style: const TextStyle(fontSize: 20))),
        ],
      ),
    );
  }
}
