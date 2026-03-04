import 'package:flutter/material.dart';
import 'package:flutter_demo/providers/driving_id_notifier.dart';
import 'package:flutter_demo/providers/me_data_notifier.dart';
import 'package:flutter_demo/service/auth_service.dart';
import 'package:flutter_demo/theme/colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'widgets/monthly_calendar_widget.dart';
import 'drowsiness_screen.dart';
import 'package:camera/camera.dart';
import 'package:flutter_demo/service/matching_service.dart';
import 'package:flutter_demo/service/drive_record_service.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key, required this.camera});
  final CameraDescription camera;

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  bool _isStarting = false;

  List<dynamic> records = [];

  @override
  void initState() {
    super.initState();
    _loadMe();
    _loadDriveRecords();  
  }

  Future<void> _loadMe() async {
    final AuthService authService = AuthService();
    final meJson = await authService.getMe();

    if (!mounted) return;

    if (meJson != null) {
      final me = MeData.fromJson(meJson);
      ref.read(meDataProvider.notifier).setData(me);
    }
  }

  Future<void> _loadDriveRecords() async {
    final data = await DriveRecordService().getDriveRecords();

    if (!mounted) return;

    setState(() {
      records = data.take(3).toList(); // 메인스크린에선 최근 3개만, 백엔드에선 10개 넘겨줌(이건 상세페이지)
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),

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

                    _buildStartCard(context, ref),

                    const SizedBox(height: 32),

                    const Text(
                      "최근 주행 기록",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),

                    const SizedBox(height: 16),

                    Column(
                      children: records.map((record) {
                        final date = DateTime.parse(
                          record["driveDate"] ?? DateTime.now().toIso8601String(),
                        );

                        final int duration = record["duration"] ?? 0;
                        final double score =
                            ((record["avgDrowsiness"] ?? 0.0) as num).toDouble() * 100;

                        String status;
                        if (score >= 80) {
                          status = "안전";
                        } else if (score >= 60) {
                          status = "주의";
                        } else {
                          status = "위험";
                        }

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _driveHistoryItem(
                            date: "${date.year}.${date.month}.${date.day}",
                            duration: "${duration ~/ 60}분",
                            status: status,
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 32),

                    const Text(
                      "이번 달 주행 상태",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),

                    const SizedBox(height: 16),

                    const MonthlyCalendarWidget(),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),

            _buildBottomNav(context),
            const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildStartCard(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgWhite,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "주행 보조 시작",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
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
              onPressed: _isStarting
                  ? null
                  : () async {
                      setState(() {
                        _isStarting = true;
                      });
                      final startTime = DateTime.now();
                      final driveService = DriveRecordService();
                      final matchingService = MatchingService();

                      try {
                        // 현재 위치 가져오기
                        final pos = await matchingService.getCurrentLocation();

                        final driveId = await driveService.startDrive(
                          driveDate: startTime.toIso8601String(),
                          startTime: startTime,
                          startLat: pos.latitude,
                          startLng: pos.longitude,
                        );

                        if (!mounted) return;

                        if (driveId != null) {
                          ref
                              .read(drivingIdProvider.notifier)
                              .setId(driveId.toString());

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  DrowsinessScreen(camera: widget.camera),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("주행 시작에 실패했습니다.")),
                          );
                        }
                      } catch (e) {
                        if (!mounted) return;

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("위치를 가져올 수 없습니다.")),
                        );
                      } finally {
                        if (mounted) {
                          setState(() {
                            _isStarting = false;
                          });
                        }
                      }
                    },

              child: _isStarting
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
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
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: bgWhite,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          const Icon(Icons.home_filled, color: mainGreen, size: 30),
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, '/matching');
            },
            icon: const Icon(Icons.map, color: textMedium, size: 28),
          ),
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, '/profile');
            },
            icon: const Icon(Icons.person, color: textMedium, size: 28),
          ),
        ],
      ),
    );
  }

  Widget _driveHistoryItem({
    required String date,
    required String duration,
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
          Text(
            status,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: mainGreen,
            ),
          ),
        ],
      ),
    );
  }
}
