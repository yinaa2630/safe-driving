import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';

class RestArea {
  final String type;
  final String name;
  final double latitude;
  final double longitude;
  final String direction;
  final String roadName;
  final int parkingCount;
  final bool hasToilet;
  final bool gasStation;
  final bool evStation;
  final String phone;
  final double distance;

  RestArea.fromJson(Map<String, dynamic> j)
    : type = j['type'] ?? '',
      name = j['name'] ?? '',
      latitude = double.tryParse(j['latitude'].toString()) ?? 0.0,
      longitude = double.tryParse(j['longitude'].toString()) ?? 0.0,
      direction = j['direction'] ?? '',
      roadName = j['road_name'] ?? '',
      parkingCount = int.tryParse(j['parking_count'].toString()) ?? 0,
      hasToilet = j['has_toilet'] ?? false,
      gasStation = j['gas_station'] ?? false,
      evStation = j['ev_station'] ?? false,
      phone = j['phone']?.toString() ?? '',
      distance = (j['distance'] as num).toDouble();

  bool get isDrowsyShelter => type == 'DROWSY_AREA';
}

class MatchingService {
  final String baseUrl = "http://192.168.0.22:3000";

  Future<Position> getCurrentLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw Exception('위치 서비스가 꺼져 있어요.');
    }
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      throw Exception('위치 권한이 필요해요.');
    }
    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  // 가까운 지역 가져오기
  Future<List<dynamic>> getRestAreas(double lat, double lng) async {
    try {
      final response = await http
          .get(
            Uri.parse(
              "$baseUrl/rest-area/nearest?lat=$lat&lng=$lng&bearing=0&limit=3",
            ),
            headers: {"Content-Type": "application/json"},
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      } else {
        throw Exception('데이터 오류 (${response.statusCode})');
      }
    } catch (e) {
      print("getRestAreas error: $e");
      if (e is TimeoutException) {
        throw Exception('서버 응답 시간이 초과되었습니다.');
      } else if (e is SocketException) {
        throw Exception('인터넷 연결을 확인해주세요.');
      }
      throw Exception('휴게소 데이터를 불러오지 못했습니다.');
    }
  }

  // 카카오 네비게이션
  Future<void> navigateKakao(RestArea area) async {
    final appUri = Uri.parse(
      'kakaomap://route?ep=${area.latitude},${area.longitude}&by=CAR',
    );
    final webUri = Uri.parse(
      'https://map.kakao.com/link/to/${Uri.encodeComponent(area.name)},${area.latitude},${area.longitude}',
    );
    if (await canLaunchUrl(appUri)) {
      await launchUrl(appUri);
    } else {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    }
  }
}
