import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

enum DriveStatus { none, good, normal, bad }

class MonthlyCalendarWidget extends StatefulWidget {
  const MonthlyCalendarWidget({super.key});

  @override
  State<MonthlyCalendarWidget> createState() =>
      _MonthlyCalendarWidgetState();
}

class _MonthlyCalendarWidgetState
    extends State<MonthlyCalendarWidget> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // 🔹 더미 데이터
  final Map<DateTime, DriveStatus> _mockData = {
    DateTime(2026, 2, 20): DriveStatus.good,
    DateTime(2026, 2, 18): DriveStatus.bad,
    DateTime(2026, 2, 21): DriveStatus.normal,
  };

  DriveStatus _getStatus(DateTime day) {
    final normalized =
        DateTime(day.year, day.month, day.day);
    return _mockData[normalized] ?? DriveStatus.none;
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
      selectedDayPredicate: (day) =>
          isSameDay(_selectedDay, day),
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
        });
      },
      calendarBuilders: CalendarBuilders(
        defaultBuilder: (context, day, focusedDay) {
          final status = _getStatus(day);
          return _buildDayCell(day, status);
        },
        todayBuilder: (context, day, focusedDay) {
          final status = _getStatus(day);
          return _buildDayCell(day, status, isToday: true);
        },
      ),
    );
  }

  Widget _buildDayCell(DateTime day, DriveStatus status,
      {bool isToday = false}) {
    String emoji;

    switch (status) {
      case DriveStatus.good:
        emoji = "😊";
        break;
      case DriveStatus.normal:
        emoji = "🙂";
        break;
      case DriveStatus.bad:
        emoji = "😴";
        break;
      default:
        emoji = "-";
    }

    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: isToday
            ? Border.all(color: Colors.green, width: 1.5)
            : Border.all(color: Colors.grey.shade300),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 4,
            left: 4,
            child: Text(
              "${day.day}",
              style: const TextStyle(fontSize: 10),
            ),
          ),
          Center(
            child: Text(
              emoji,
              style: const TextStyle(fontSize: 20),
            ),
          ),
        ],
      ),
    );
  }
}