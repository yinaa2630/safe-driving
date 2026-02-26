import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
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

  try {
    cameras = await availableCameras();
  } catch (e) {
    print('카메라 초기화 에러: $e');
    cameras = [];
  }

  const storage = FlutterSecureStorage();
  final String? token = await storage.read(key: 'user_token');

  runApp(MyApp(initialRoute: (token != null) ? '/main' : '/'));
}

class MyApp extends StatelessWidget {
  final String initialRoute;

  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    final selectedCamera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    return MaterialApp(
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
        '/main': (context) => MainScreen(camera: selectedCamera),
        '/matching': (context) => MatchingScreen(),
        '/profile': (context) => const ProfileScreen(),
      },
    );
  }
}