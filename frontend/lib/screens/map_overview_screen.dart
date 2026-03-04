import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_demo/service/matching_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kakao_map_sdk/kakao_map_sdk.dart';

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
  KakaoMapController? _controller;

  @override
  Widget build(BuildContext context) {
    final myLat = widget.myPosition.latitude;
    final myLng = widget.myPosition.longitude;

    // ✅ 시작 카메라 위치를 미리 계산해서 처음부터 올바른 위치로 시작
    final allAreas = [...widget.drowsyShelters, ...widget.restAreas];
    final startCamera = _calcCamera(myLat, myLng, allAreas);

    return KakaoMap(
      option: KakaoMapOption(
        position: LatLng(startCamera.centerLat, startCamera.centerLng),
        zoomLevel: startCamera.zoom,
        mapType: MapType.normal,
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
      LatLng(myLat, myLng),
      style: PoiStyle(
        icon: KImage.fromAsset('assets/marker/my_location.png', 40, 40),
      ),
    );

    // 졸음쉼터 마커
    for (final area in widget.drowsyShelters) {
      await controller.labelLayer.addPoi(
        LatLng(area.latitude, area.longitude),
        style: PoiStyle(
          icon: KImage.fromAsset('assets/marker/drowsy.png', 30, 42),
        ),
      );
    }

    // 휴게소 마커
    for (final area in widget.restAreas) {
      await controller.labelLayer.addPoi(
        LatLng(area.latitude, area.longitude),
        style: PoiStyle(
          icon: KImage.fromAsset('assets/marker/rest_area.png', 30, 42),
        ),
      );
    }
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
      CameraUpdate.newCenterPosition(LatLng(lat, lng)),
      animation: const CameraAnimation(500),
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
      CameraUpdate.newCenterPosition(
        LatLng(cam.centerLat, cam.centerLng),
        zoomLevel: cam.zoom,
      ),
      animation: const CameraAnimation(600),
    );
  }
}

class _CameraResult {
  final double centerLat;
  final double centerLng;
  final int zoom;
  _CameraResult(this.centerLat, this.centerLng, this.zoom);
}