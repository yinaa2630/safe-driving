import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_demo/screens/drive_complete_screen.dart';
import 'package:flutter_demo/screens/drowsiness_screen.dart';
import 'package:flutter_demo/screens/login_screen.dart';
import 'package:flutter_demo/screens/main_screen.dart';
import 'package:flutter_demo/screens/matching_screen.dart';
import 'package:flutter_demo/screens/signup_screen.dart';
import 'package:flutter_demo/theme/colors.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_demo/screens/profile_screen.dart';

late List<CameraDescription> cameras;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();


  // 1. 카메라 초기화
  try {
    cameras = await availableCameras();
  } catch (e) {
    print('카메라 초기화 에러: $e');
    cameras = [];
  }

  // 2. 보안 저장소 객체 생성
  const storage = FlutterSecureStorage();

  // 3. 암호화된 토큰 읽기
  // .read()는 비동기 함수이며, 해당 키가 없으면 null을 반환합니다.
  final String? token = await storage.read(key: 'user_token');

  // 4. 토큰 존재 여부에 따라 초기 경로 설정
  runApp(MyApp(initialRoute: (token != null) ? '/main' : '/'));
}

class MyApp extends StatelessWidget {
  final String initialRoute;

  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    // 전면 카메라 선택 로직
    final selectedCamera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      ),
    );

    return MaterialApp(
      title: 'Secure Drowsiness App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: mainGreen,
        ).copyWith(onSurface: textPrimary, onPrimary: bgWhite),
        fontFamily: 'WantedSans',
        scaffoldBackgroundColor: pageBg,
        appBarTheme: AppBarTheme(
          backgroundColor: pageBg,
          foregroundColor: textPrimary,
          elevation: 0,
        ),
      ),
      initialRoute: initialRoute,
      routes: {
        '/': (context) => LoginScreen(),
        '/signup': (context) => SignUpScreen(),
        '/main': (context) => MainScreen(),
        '/drowsiness': (context) => DrowsinessScreen(camera: selectedCamera),
        '/matching': (context) => MatchingScreen(),
        '/complete': (context) => DriveCompleteScreen(),
        '/profile': (context) => const ProfileScreen(),
      },
    );
  }
}
