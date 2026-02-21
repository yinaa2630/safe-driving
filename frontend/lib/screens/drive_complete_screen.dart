import 'package:flutter/material.dart';
import 'package:flutter_demo/theme/colors.dart';

class DriveCompleteScreen extends StatelessWidget {
  const DriveCompleteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: surface, // 연한 오프화이트 배경
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 동그란 체크 아이콘
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: mainGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 60,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 28),

              // 완료 문구
              const Text(
                "주행이 완료되었어요!",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: inkBlack,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 10),

              const Text(
                "오늘도 안전 운전 하셨어요.\n아래는 이번 주행 요약이에요!",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: textMedium,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 36),

              // 정보 카드
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 22,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  children: [
                    _buildInfoRow(
                      icon: Icons.access_time_filled,
                      label: "총 주행 시간",
                      value: "38분",
                    ),
                    _divider(),
                    _buildInfoRow(
                      icon: Icons.route,
                      label: "이동 거리",
                      value: "21.4km",
                    ),
                    _divider(),
                    _buildInfoRow(
                      icon: Icons.warning_amber_rounded,
                      label: "경고 발생",
                      value: "0회",
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // 홈으로 이동 버튼
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/main');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: inkBlack,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    "홈으로 돌아가기",
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
      ),
    );
  }

  // 구분선
  Widget _divider() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 14),
      height: 1,
      color: borderColor,
    );
  }

  // 정보 줄 위젯
  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 24, color: mainGreen),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: inkBlack,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: inkBlack,
          ),
        ),
      ],
    );
  }
}
