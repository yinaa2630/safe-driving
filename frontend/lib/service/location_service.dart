import 'package:geolocator/geolocator.dart';

class LocationService {
  Position? _currentPosition;

  Position? get currentPosition => _currentPosition;

  Future<bool> requestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;  // GPS 자체가 꺼져있으면 false

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  Future<void> startTracking() async {  // async 추가
    // 스트림 시작 전에 현재 위치 한 번 바로 가져오기
    try {
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      print('초기 위치 가져오기 실패: $e');
    }

    // 이후 스트림으로 계속 업데이트
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) {
      _currentPosition = position;
    });
  }

  double? get latitude => _currentPosition?.latitude;
  double? get longitude => _currentPosition?.longitude;

  double? get heading {
    if (_currentPosition == null) return null;
    if (_currentPosition!.speed < 0.5) return null;
    return _currentPosition!.heading;
  }
}