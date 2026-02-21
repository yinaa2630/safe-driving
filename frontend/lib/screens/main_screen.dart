import 'package:flutter/material.dart';
import 'package:flutter_demo/theme/colors.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // 상단 인사 UI
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

              // 주행 시작 카드
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: bgWhite,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(50),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "주행 보조 시작",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
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
                        onPressed: () {
                          Navigator.pushNamed(context, '/drowsiness');
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
              ),

              const SizedBox(height: 32),

              // 최근 기록 타이틀
              const Text(
                "최근 주행 기록",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 16),

              // 최근 주행 리스트 더미 2개
              _driveHistoryItem(
                date: "2024. 02. 20",
                duration: "36분",
                status: "안전",
              ),
              const SizedBox(height: 12),
              _driveHistoryItem(
                date: "2024. 02. 18",
                duration: "1시간 12분",
                status: "주의 발생 1회",
              ),

              const Spacer(),

              // 하단 내비게이션 느낌의 메뉴 (시안 반영)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: bgWhite,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(50),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: const [
                    Icon(Icons.home_filled, color: mainGreen, size: 30),
                    Icon(Icons.map, color: textMedium, size: 28),
                    Icon(Icons.person, color: textMedium, size: 28),
                  ],
                ),
              ),

              const SizedBox(height: 14),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _driveHistoryItem({
  required String date,
  required String duration,
  required String status,
}) {
  return Container(
    padding: const EdgeInsets.all(18),
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
            color: mainGreen,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}
