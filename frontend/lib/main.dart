import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_demo/screens/drive_complete_screen.dart';
import 'package:flutter_demo/screens/login_screen.dart';
import 'package:flutter_demo/screens/main_screen.dart';
import 'package:flutter_demo/screens/matching_screen.dart';
import 'package:flutter_demo/screens/signup_screen.dart';
import 'package:flutter_demo/theme/colors.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_demo/screens/profile_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kakao_map_sdk/kakao_map_sdk.dart';
import 'package:flutter_demo/screens/map_overview_screen.dart';

late List<CameraDescription> cameras;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Kakao 네이티브 앱 키는 dart-define으로 주입 (깃에 키 노출 방지)
  const kakaoNativeAppKey = String.fromEnvironment('KAKAO_NATIVE_APP_KEY');

  if (kakaoNativeAppKey.isEmpty) {
    debugPrint('❌ KAKAO_NATIVE_APP_KEY 가 비어있어요. --dart-define으로 주입하세요.');
  } else {
    await KakaoMapSdk.instance.initialize(kakaoNativeAppKey);

    final hashKey = await KakaoMapSdk.instance.hashKey();
    debugPrint('🔑 키 해시: $hashKey');
  }

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
    ProviderScope(
      child: MyApp(initialRoute: token != null ? '/main' : '/'),
    ),
  );
}

/// ✅ MapOverviewScreen으로 넘길 arguments 타입
class MapOverviewArgs {
  final List<LatLng> drowsyShelters;
  final List<LatLng> restAreas;

  const MapOverviewArgs({
    required this.drowsyShelters,
    required this.restAreas,
  });
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
      title: 'Secure Drowsiness App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: mainGreen)
            .copyWith(onSurface: textPrimary, onPrimary: bgWhite),
        fontFamily: 'WantedSans',
        scaffoldBackgroundColor: pageBg,
      ),
      initialRoute: initialRoute,

      /// ✅ 기본 routes (데이터 필요 없는 화면만)
      routes: {
        '/': (context) => LoginScreen(),
        '/signup': (context) => SignUpScreen(),
        '/main': (context) => selectedCamera != null
            ? MainScreen(camera: selectedCamera)
            : const Scaffold(
                body: Center(child: Text('카메라를 찾을 수 없어요.')),
              ),
        '/matching': (context) => MatchingScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/complete': (context) => const DriveCompleteScreen(),
      },

      /// ✅ 데이터 필요한 라우트는 여기서 처리
      onGenerateRoute: (settings) {
        if (settings.name == '/map_overview') {
          final args = settings.arguments;

          if (args is MapOverviewArgs) {
            return MaterialPageRoute(
              builder: (_) => MapOverviewScreen(
                drowsyShelters: args.drowsyShelters,
                restAreas: args.restAreas,
              ),
              settings: settings,
            );
          }

          // args가 없거나 타입이 틀리면 안내 화면
          return MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: Center(
                child: Text('지도 화면에 필요한 데이터(arguments)가 없어요.'),
              ),
            ),
            settings: settings,
          );
        }

        return null;
      },
    );
  }
}