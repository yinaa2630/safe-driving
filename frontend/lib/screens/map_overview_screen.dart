import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kakao_map_sdk/kakao_map_sdk.dart';

class MapOverviewScreen extends StatefulWidget {
  /// 졸음쉼터 좌표들
  final List<LatLng> drowsyShelters;

  /// 휴게소 좌표들
  final List<LatLng> restAreas;

  const MapOverviewScreen({
    super.key,
    required this.drowsyShelters,
    required this.restAreas,
  });

  @override
  State<MapOverviewScreen> createState() => _MapOverviewScreenState();
}

class _MapOverviewScreenState extends State<MapOverviewScreen> {
  KakaoMapController? _controller;

  LatLng? _myPos;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _error = '위치 서비스(GPS)가 꺼져있어요.';
          _loading = false;
        });
        return;
      }

      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        setState(() {
          _error = '위치 권한이 필요해요.';
          _loading = false;
        });
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );

      setState(() {
        _myPos = LatLng(pos.latitude, pos.longitude);
        _loading = false;
      });

      if (_controller != null) {
        await _applyAllMarkersAndCamera();
      }
    } catch (e) {
      setState(() {
        _error = '내 위치를 불러오지 못했어요: $e';
        _loading = false;
      });
    }
  }

  /// ✅ 내 위치 + (졸음쉼터/휴게소) 전부 마커로 찍고, 한 화면에 최대한 같이 보이게 카메라 이동
  Future<void> _applyAllMarkersAndCamera() async {
    final controller = _controller;
    final myPos = _myPos;
    if (controller == null || myPos == null) return;

    // ✅ 1) 마커 아이콘 경로: 너 프로젝트 구조(assets/marker/*)에 맞춤
    final myStyle = PoiStyle(
      icon: KImage.fromAsset("assets/marker/my_location.png", 48, 48),
    );
    final shelterStyle = PoiStyle(
      icon: KImage.fromAsset("assets/marker/drowsy.png", 48, 48),
    );
    final restAreaStyle = PoiStyle(
      icon: KImage.fromAsset("assets/marker/rest_area.png", 48, 48),
    );

    // ✅ 2) 전부 찍을 좌표들 모으기 (내 위치 포함)
    final points = <LatLng>[
      myPos,
      ...widget.drowsyShelters,
      ...widget.restAreas,
    ];

    // ✅ 3) 마커 찍기
    await controller.labelLayer.addPoi(myPos, style: myStyle);

    for (final p in widget.drowsyShelters) {
      await controller.labelLayer.addPoi(p, style: shelterStyle);
    }

    for (final p in widget.restAreas) {
      await controller.labelLayer.addPoi(p, style: restAreaStyle);
    }

    // ✅ 4) "한 화면에 다 보이게" -> bounds API 대신 직접 center/zoom 계산해서 이동
    final camera = _calcCameraToFit(points);

    await controller.moveCamera(
      CameraUpdate.newCenterPosition(camera.center, zoomLevel: camera.zoomLevel),
      animation: const CameraAnimation(700),
    );
  }

  void _onMapReady(KakaoMapController controller) async {
    _controller = controller;
    if (_myPos != null) {
      await _applyAllMarkersAndCamera();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('지도')),
        body: Center(child: Text(_error!)),
      );
    }

    final startPos = _myPos ?? const LatLng(37.5665, 126.9780);

    return Scaffold(
      appBar: AppBar(
        title: const Text('내 위치 + 졸음쉼터 + 휴게소'),
        actions: [
          IconButton(
            tooltip: '다시 불러오기',
            onPressed: () async {
              setState(() {
                _loading = true;
                _error = null;
              });
              await _initLocation();
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Stack(
        children: [
          KakaoMap(
            onMapReady: _onMapReady,
            option: KakaoMapOption(
              position: startPos,
              zoomLevel: 16,
              mapType: MapType.normal,
            ),
          ),

          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.92),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: const [
                  _LegendDot(color: Colors.blue, label: "내 위치"),
                  _LegendDot(color: Colors.orange, label: "졸음쉼터"),
                  _LegendDot(color: Colors.green, label: "휴게소"),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }
}

/// =======================
/// ✅ 카메라 자동 맞춤 계산 로직 (SDK 버전 상관없이 동작)
/// =======================

class _CameraFitResult {
  final LatLng center;
  final int zoomLevel; // 카카오 줌레벨은 int로 많이 씀
  const _CameraFitResult({required this.center, required this.zoomLevel});
}

_CameraFitResult _calcCameraToFit(List<LatLng> points) {
  // 데이터가 거의 없으면 기본 줌
  if (points.isEmpty) {
    return const _CameraFitResult(center: LatLng(37.5665, 126.9780), zoomLevel: 16);
  }
  if (points.length == 1) {
    return _CameraFitResult(center: points.first, zoomLevel: 16);
  }

  double minLat = points.first.latitude;
  double maxLat = points.first.latitude;
  double minLng = points.first.longitude;
  double maxLng = points.first.longitude;

  for (final p in points) {
    minLat = math.min(minLat, p.latitude);
    maxLat = math.max(maxLat, p.latitude);
    minLng = math.min(minLng, p.longitude);
    maxLng = math.max(maxLng, p.longitude);
  }

  final center = LatLng((minLat + maxLat) / 2.0, (minLng + maxLng) / 2.0);

  // 범위(스프레드)가 클수록 줌을 낮춰야(더 멀리) 다 보임
  final latSpan = (maxLat - minLat).abs();
  final lngSpan = (maxLng - minLng).abs();
  final span = math.max(latSpan, lngSpan);

  // 대충 맞추는 휴리스틱(실사용에 충분히 쓸만함)
  // span은 위경도 차이(도 단위). 값이 커질수록 zoomLevel을 낮춤(더 멀리 보기)
  int zoom;
  if (span < 0.002) {
    zoom = 17;
  } else if (span < 0.005) {
    zoom = 16;
  } else if (span < 0.01) {
    zoom = 15;
  } else if (span < 0.02) {
    zoom = 14;
  } else if (span < 0.05) {
    zoom = 13;
  } else if (span < 0.1) {
    zoom = 12;
  } else if (span < 0.2) {
    zoom = 11;
  } else {
    zoom = 10;
  }

  // 안전 범위: 너무 과도하게 확대/축소하지 않게
  zoom = zoom.clamp(3, 18);

  return _CameraFitResult(center: center, zoomLevel: zoom);
}