import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_demo/service/matching_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:kakao_map_sdk/kakao_map_sdk.dart' as kakao;

class MapOverviewScreen extends StatefulWidget {
  final List<RestArea> drowsyShelters;
  final List<RestArea> restAreas;
  final Position myPosition;

  const MapOverviewScreen({
    super.key,
    required this.drowsyShelters,
    required this.restAreas,
    required this.myPosition,
  });

  @override
  State<MapOverviewScreen> createState() => MapOverviewScreenState();
}

class MapOverviewScreenState extends State<MapOverviewScreen> {
  kakao.KakaoMapController? _controller;

  // ✅ 현재 표시 중인 경로(있으면 삭제 가능) - Flutter Route랑 충돌 방지
  kakao.Route? _routeOverlay;

  @override
  Widget build(BuildContext context) {
    final myLat = widget.myPosition.latitude;
    final myLng = widget.myPosition.longitude;

    // ✅ 시작 카메라 위치를 미리 계산해서 처음부터 올바른 위치로 시작
    final allAreas = [...widget.drowsyShelters, ...widget.restAreas];
    final startCamera = _calcCamera(myLat, myLng, allAreas);

    return kakao.KakaoMap(
      option: kakao.KakaoMapOption(
        position: kakao.LatLng(startCamera.centerLat, startCamera.centerLng),
        zoomLevel: startCamera.zoom,
        mapType: kakao.MapType.normal,
      ),
      onMapReady: (controller) async {
        _controller = controller;
        await Future.delayed(const Duration(milliseconds: 200));
        await _addMarkers();
      },
    );
  }

  Future<void> _addMarkers() async {
    final controller = _controller;
    if (controller == null) return;

    final myLat = widget.myPosition.latitude;
    final myLng = widget.myPosition.longitude;

    // 내 위치 마커
    await controller.labelLayer.addPoi(
      kakao.LatLng(myLat, myLng),
      style: kakao.PoiStyle(
        icon: kakao.KImage.fromAsset('assets/marker/my_location.png', 40, 40),
      ),
    );

    // 졸음쉼터 마커
    for (final area in widget.drowsyShelters) {
      await controller.labelLayer.addPoi(
        kakao.LatLng(area.latitude, area.longitude),
        style: kakao.PoiStyle(
          icon: kakao.KImage.fromAsset('assets/marker/drowsy.png', 30, 42),
        ),
      );
    }

    // 휴게소 마커
    for (final area in widget.restAreas) {
      await controller.labelLayer.addPoi(
        kakao.LatLng(area.latitude, area.longitude),
        style: kakao.PoiStyle(
          icon: kakao.KImage.fromAsset('assets/marker/rest_area.png', 30, 42),
        ),
      );
    }
  }

  /// ✅ 외부(MatchingScreen)에서 호출: "실제 도로 경로"를 지도에 그리기
  Future<void> drawRouteTo(double destLat, double destLng) async {
    final controller = _controller;
    if (controller == null) return;

    final points = await _fetchRoadRoutePoints(
      startLat: widget.myPosition.latitude,
      startLng: widget.myPosition.longitude,
      endLat: destLat,
      endLng: destLng,
      angle: _safeAngle(widget.myPosition.heading),
    );

    if (points.length < 2) return;

    // 기존 경로 삭제
    if (_routeOverlay != null) {
      try {
        await _routeOverlay!.remove();
      } catch (_) {}
      _routeOverlay = null;
    }

    // 새 경로 그리기
    // RouteStyle(색/굵기) - 버전에 따라 stroke 옵션이 없을 수도 있어
    final routeStyle = kakao.RouteStyle(
      Colors.blue,
      10,
      strokeWidth: 4,
      strokeColor: Colors.white,
    );

    _routeOverlay = await controller.routeLayer.addRoute(points, routeStyle);

    // 카메라 이동(경로 중간)
    final mid = points[points.length ~/ 2];
    controller.moveCamera(
      kakao.CameraUpdate.newCenterPosition(
        mid,
        zoomLevel: await _suggestZoom(points),
      ),
      animation: const kakao.CameraAnimation(500),
    );
  }

  /// ✅ 경로 지우기
  Future<void> clearRoute() async {
    if (_routeOverlay == null) return;
    try {
      await _routeOverlay!.remove();
    } catch (_) {}
    _routeOverlay = null;
  }

  /// 카카오모빌리티 자동차 길찾기 API 호출 → roads.vertexes를 LatLng 리스트로 변환
  Future<List<kakao.LatLng>> _fetchRoadRoutePoints({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
    required int angle,
  }) async {
    final restKey = dotenv.env['KAKAO_MOBILITY_REST_KEY'];
    if (restKey == null || restKey.isEmpty) {
      throw Exception('KAKAO_MOBILITY_REST_KEY가 .env에 없습니다.');
    }

    // origin/destination은 X,Y (경도,위도) 순서
    final uri = Uri.parse(
      'https://apis-navi.kakaomobility.com/v1/directions'
      '?origin=$startLng,$startLat,angle=$angle'
      '&destination=$endLng,$endLat'
      '&summary=false',
    );

    final res = await http.get(
      uri,
      headers: {'Authorization': 'KakaoAK $restKey'},
    );

    if (res.statusCode != 200) {
      throw Exception('Directions API 실패: ${res.statusCode} ${res.body}');
    }

    final jsonMap = jsonDecode(res.body) as Map<String, dynamic>;
    final routes = (jsonMap['routes'] as List?) ?? const [];
    if (routes.isEmpty) return const [];

    final sections = (routes[0]['sections'] as List?) ?? const [];

    final pts = <kakao.LatLng>[];
    for (final s in sections) {
      final roads = (s['roads'] as List?) ?? const [];
      for (final r in roads) {
        final vertexes = (r['vertexes'] as List?) ?? const [];
        // vertexes: [x1,y1,x2,y2,...] (x=lng, y=lat)
        for (int i = 0; i + 1 < vertexes.length; i += 2) {
          final x = (vertexes[i] as num).toDouble(); // lng
          final y = (vertexes[i + 1] as num).toDouble(); // lat
          pts.add(kakao.LatLng(y, x));
        }
      }
    }

    // 너무 많으면 성능상 샘플링
    return _downsample(pts, step: 2);
  }

  List<kakao.LatLng> _downsample(List<kakao.LatLng> pts, {int step = 2}) {
    if (pts.length <= 2 || step <= 1) return pts;
    final out = <kakao.LatLng>[];
    for (int i = 0; i < pts.length; i += step) {
      out.add(pts[i]);
    }
    if (out.last != pts.last) out.add(pts.last);
    return out;
  }

  int _safeAngle(double heading) {
    if (heading.isNaN || heading.isInfinite) return 0;
    final h = heading.round();
    if (h < 0) return 0;
    if (h > 360) return 360;
    return h;
  }

  Future<int> _suggestZoom(List<kakao.LatLng> pts) async {
    double minLat = pts.first.latitude, maxLat = pts.first.latitude;
    double minLng = pts.first.longitude, maxLng = pts.first.longitude;

    for (final p in pts) {
      minLat = math.min(minLat, p.latitude);
      maxLat = math.max(maxLat, p.latitude);
      minLng = math.min(minLng, p.longitude);
      maxLng = math.max(maxLng, p.longitude);
    }

    final span = math.max(maxLat - minLat, maxLng - minLng);

    if (span < 0.02) return 14;
    if (span < 0.05) return 13;
    if (span < 0.1) return 12;
    if (span < 0.2) return 11;
    if (span < 0.5) return 10;
    return 9;
  }

  /// 카메라 중심/줌 계산
  _CameraResult _calcCamera(double myLat, double myLng, List<RestArea> areas) {
    if (areas.isEmpty) {
      return _CameraResult(myLat, myLng, 14);
    }

    final allLats = [myLat, ...areas.map((a) => a.latitude)];
    final allLngs = [myLng, ...areas.map((a) => a.longitude)];

    final minLat = allLats.reduce(math.min);
    final maxLat = allLats.reduce(math.max);
    final minLng = allLngs.reduce(math.min);
    final maxLng = allLngs.reduce(math.max);

    // 여백 추가 (패딩)
    const padding = 0.02;
    final centerLat = (minLat + maxLat) / 2;
    final centerLng = (minLng + maxLng) / 2;
    final span = math.max(maxLat - minLat, maxLng - minLng) + padding;

    int zoom;
    if (span < 0.02) zoom = 14;
    else if (span < 0.05) zoom = 13;
    else if (span < 0.1) zoom = 12;
    else if (span < 0.2) zoom = 11;
    else if (span < 0.5) zoom = 10;
    else zoom = 9;

    return _CameraResult(centerLat, centerLng, zoom);
  }

  void moveToLocation(double lat, double lng) {
    _controller?.moveCamera(
      kakao.CameraUpdate.newCenterPosition(kakao.LatLng(lat, lng)),
      animation: const kakao.CameraAnimation(500),
    );
  }

  void fitAll() {
    final controller = _controller;
    if (controller == null) return;

    final myLat = widget.myPosition.latitude;
    final myLng = widget.myPosition.longitude;
    final allAreas = [...widget.drowsyShelters, ...widget.restAreas];
    final cam = _calcCamera(myLat, myLng, allAreas);

    controller.moveCamera(
      kakao.CameraUpdate.newCenterPosition(
        kakao.LatLng(cam.centerLat, cam.centerLng),
        zoomLevel: cam.zoom,
      ),
      animation: const kakao.CameraAnimation(600),
    );
  }
}

class _CameraResult {
  final double centerLat;
  final double centerLng;
  final int zoom;
  _CameraResult(this.centerLat, this.centerLng, this.zoom);
}