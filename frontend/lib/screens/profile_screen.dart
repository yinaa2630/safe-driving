import 'package:flutter/material.dart';
import 'package:flutter_demo/providers/me_data_notifier.dart';
import 'package:flutter_demo/theme/colors.dart';
import 'package:flutter_demo/utils/format_phone_number.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../service/auth_service.dart';
import 'drive_history_detail_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final AuthService authService = AuthService();

  @override
  void initState() {
    super.initState();
  }

  Future<void> logout() async {
    await authService.logout();
    ref.read(meDataProvider.notifier).clear();
    Navigator.pushReplacementNamed(context, '/');
  }

  @override
  Widget build(BuildContext context) {
    final meData = ref.watch(meDataProvider);
    if (meData == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: const Text("내 정보")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const CircleAvatar(
              backgroundColor: bgWhite,
              radius: 45,
              child: Icon(Icons.person, size: 45, color: mainGreen),
            ),
            const SizedBox(height: 24),
            Text(
              meData.username,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              meData.email,
              style: const TextStyle(fontSize: 14, color: textMedium),
            ),
            const SizedBox(height: 10),
            Text(
              '☎비상 연락처',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: textMedium,
              ),
            ),
            Text(
              formatPhoneNumber(meData.emergencyCall),
              style: const TextStyle(fontSize: 14, color: textMedium),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const DriveHistoryDetailScreen(),
                    ),
                  );
                },
                child: const Text(
                  "상세 주행 기록 보기",
                  style: TextStyle(
                    color: textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: dangerRed),
                ),
                onPressed: logout,
                child: const Text(
                  "로그아웃",
                  style: TextStyle(
                    color: dangerRed,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
