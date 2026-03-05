import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_demo/screens/drive_complete_screen.dart';
import 'package:flutter_demo/screens/login_screen.dart';
import 'package:flutter_demo/screens/main_screen.dart';
import 'package:flutter_demo/screens/matching_screen.dart';
import 'package:flutter_demo/screens/severe_warning_screen.dart';
import 'package:flutter_demo/screens/signup_screen.dart';
import 'package:flutter_demo/theme/colors.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_demo/screens/profile_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kakao_map_sdk/kakao_map_sdk.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

late List<CameraDescription> cameras;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ .env 로드 → 카카오 키 주입
  await dotenv.load(fileName: '.env');
  final kakaoKey = dotenv.env['KAKAO_NATIVE_APP_KEY'] ?? '';
  await KakaoMapSdk.instance.initialize(kakaoKey);

  final hashKey = await KakaoMapSdk.instance.hashKey();
  debugPrint('🔑 키 해시: $hashKey');

  // ✅ 카메라 초기화
  try {
    cameras = await availableCameras();
  } catch (e) {
    debugPrint('카메라 초기화 에러: $e');
    cameras = [];
  }

  // ✅ 토큰 확인 → 초기 라우트 결정
  const storage = FlutterSecureStorage();
  final String? token = await storage.read(key: 'user_token');

  runApp(
    ProviderScope(child: MyApp(initialRoute: token != null ? '/main' : '/')),
  );
}

class MyApp extends StatelessWidget {
  final String initialRoute;

  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    final selectedCamera = cameras.isNotEmpty
        ? cameras.firstWhere(
            (c) => c.lensDirection == CameraLensDirection.front,
            orElse: () => cameras.first,
          )
        : null;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Secure Drowsiness App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: mainGreen,
        ).copyWith(onSurface: textPrimary, onPrimary: bgWhite),
        fontFamily: 'WantedSans',
        scaffoldBackgroundColor: pageBg,
      ),
      initialRoute: initialRoute,
      routes: {
        '/': (context) => LoginScreen(),
        '/signup': (context) => SignUpScreen(),
        '/main': (context) => selectedCamera != null
            ? MainScreen(camera: selectedCamera)
            : const Scaffold(body: Center(child: Text('카메라를 찾을 수 없어요.'))),
        '/matching': (context) => MatchingScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/complete': (context) => const DriveCompleteScreen(),
        '/warning': (context) => const SevereWarningScreen(),
      },
    );
  }
}
