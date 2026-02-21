import 'package:flutter/material.dart';

class MatchingScreen extends StatelessWidget {
  const MatchingScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Stack(
        children: [
          // ----------------------------------------
          // 상단 지도 영역 (예시는 Container로 대체)
          // ----------------------------------------
          Positioned.fill(
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    color: const Color(0xFFE8ECEC),
                    child: Stack(
                      children: [
                        // 예시 지도 레이어
                        Positioned(
                          top: 120,
                          left: 40,
                          child: Icon(
                            Icons.location_on,
                            color: Colors.blue,
                            size: 22,
                          ),
                        ),
                        Positioned(
                          top: 200,
                          right: 80,
                          child: Icon(
                            Icons.location_on,
                            color: Colors.green,
                            size: 22,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ----------------------------------------
          // 하단 반시트
          // ----------------------------------------
          DraggableScrollableSheet(
            initialChildSize: 0.45,
            minChildSize: 0.45,
            maxChildSize: 0.95,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 10,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 12),

                    // 회색 드래그 바
                    Container(
                      width: 45,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 제목
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: const [
                          Text(
                            "가까운 쉼터",
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // 스크롤 리스트
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        children: [
                          _buildShelterItem(
                            icon: Icons.eco,
                            title: "경부선 졸음쉼터",
                            distance: "2.1km",
                            time: "4분",
                            tagColor: const Color(0xFFDFF6DD),
                            tagTextColor: const Color(0xFF58A766),
                          ),
                          _buildShelterItem(
                            icon: Icons.local_hospital,
                            title: "안성 휴게소",
                            distance: "5.8km",
                            time: "8분",
                            tagColor: const Color(0xFFE8F1FF),
                            tagTextColor: const Color(0xFF4C7BD9),
                          ),
                          _buildShelterItem(
                            icon: Icons.map,
                            title: "서을방향 쉼터",
                            distance: "3.4km",
                            time: "5분",
                            tagColor: const Color(0xFFDFF6DD),
                            tagTextColor: const Color(0xFF58A766),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ----------------------------------------
  // 쉼터 카드 위젯
  // ----------------------------------------
  Widget _buildShelterItem({
    required IconData icon,
    required String title,
    required String distance,
    required String time,
    required Color tagColor,
    required Color tagTextColor,
  }) {
    return Builder(
      builder: (context) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // 아이콘
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: tagColor.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, size: 28, color: tagTextColor),
              ),
              const SizedBox(width: 14),

              // 텍스트
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "$distance · 약 $time",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              // 이동 버튼
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, '/main');
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 6,
                    horizontal: 14,
                  ),
                  decoration: BoxDecoration(
                    color: tagColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    "이동 →",
                    style: TextStyle(
                      color: tagTextColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
