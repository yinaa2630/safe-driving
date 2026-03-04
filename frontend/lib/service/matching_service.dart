import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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
  String get _tmapKey => dotenv.env['TMAP_API_KEY'] ?? '';

  Position? _prevPosition;

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

  double calcBearing(Position current) {
    if (current.heading >= 0 && current.heading <= 360) {
      _prevPosition = current;
      return current.heading;
    }
    if (_prevPosition != null) {
      final bearing = Geolocator.bearingBetween(
        _prevPosition!.latitude,
        _prevPosition!.longitude,
        current.latitude,
        current.longitude,
      );
      _prevPosition = current;
      return (bearing + 360) % 360;
    }
    _prevPosition = current;
    return -1;
  }

  Future<List<dynamic>> getRestAreas(
    double lat,
    double lng,
    double bearing,
  ) async {
    try {
      final response = await http
          .get(
            Uri.parse(
              "$baseUrl/rest-area/nearest?lat=$lat&lng=$lng&bearing=$bearing&limit=3",
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
      if (e is TimeoutException) throw Exception('서버 응답 시간이 초과되었습니다.');
      if (e is SocketException) throw Exception('인터넷 연결을 확인해주세요.');
      throw Exception('휴게소 데이터를 불러오지 못했습니다.');
    }
  }

  /// ✅ 티맵 REST API로 경로 좌표 리스트 반환
  Future<List<List<double>>> getRoute({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(
          'https://apis.openapi.sk.com/tmap/routes?version=1&format=json',
        ),
        headers: {
          'Content-Type': 'application/json',
          'appKey': _tmapKey,
        },
        body: jsonEncode({
          'startX': startLng.toString(),
          'startY': startLat.toString(),
          'endX': endLng.toString(),
          'endY': endLat.toString(),
          'reqCoordType': 'WGS84GEO',
          'resCoordType': 'WGS84GEO',
          'searchOption': '0', // 최적경로
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final features = data['features'] as List<dynamic>;

        final List<List<double>> coords = [];

        for (final feature in features) {
          final geometry = feature['geometry'];
          final type = geometry['type'];

          if (type == 'LineString') {
            final points = geometry['coordinates'] as List<dynamic>;
            for (final point in points) {
              // 티맵은 [경도, 위도] 순서
              coords.add([
                (point[1] as num).toDouble(), // 위도
                (point[0] as num).toDouble(), // 경도
              ]);
            }
          } else if (type == 'Point') {
            final point = geometry['coordinates'] as List<dynamic>;
            coords.add([
              (point[1] as num).toDouble(),
              (point[0] as num).toDouble(),
            ]);
          }
        }

        return coords;
      } else {
        throw Exception('경로 오류 (${response.statusCode})');
      }
    } catch (e) {
      if (e is TimeoutException) throw Exception('경로 요청 시간이 초과되었습니다.');
      throw Exception('경로를 불러오지 못했습니다: $e');
    }
  }

  /// ✅ 티맵 앱으로 길안내 (인앱 네비)
  Future<void> navigateTmap(RestArea area) async {
    final encodedName = Uri.encodeComponent(area.name);

    // 안드로이드 티맵 URL Scheme
    final appUri = Uri.parse(
      'tmap://route?referrer=com.skt.Tmap'
      '&goalx=${area.longitude}'
      '&goaly=${area.latitude}'
      '&goalname=$encodedName',
    );

    // 티맵 미설치 시 플레이스토어로
    final storeUri = Uri.parse(
      'https://play.google.com/store/apps/details?id=com.skt.tmap.ku',
    );

    if (await canLaunchUrl(appUri)) {
      await launchUrl(appUri);
    } else {
      await launchUrl(storeUri, mode: LaunchMode.externalApplication);
    }
  }

  // 기존 카카오맵 네비 (필요시 사용)
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
