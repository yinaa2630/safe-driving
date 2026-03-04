import 'package:flutter/material.dart';
import 'package:flutter_demo/service/matching_service.dart';
import 'package:flutter_demo/theme/colors.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kakao_map_sdk/kakao_map_sdk.dart';

class MatchingScreen extends StatefulWidget {
  const MatchingScreen({super.key});

  @override
  State<MatchingScreen> createState() => _MatchingScreenState();
}

class _MatchingScreenState extends State<MatchingScreen> {
  final matchingService = MatchingService();
  KakaoMapController? _mapController;

  Position? _myPosition;
  List<RestArea> _restAreas = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final pos = await matchingService.getCurrentLocation();
      setState(() => _myPosition = pos);

      final response = await matchingService.getRestAreas(
        pos.latitude,
        pos.longitude,
      );

      _restAreas = response.map((e) => RestArea.fromJson(e)).toList();
      setState(() {});

      if (_mapController != null) {
        await _updateMap();
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

Future<void> _updateMap() async {
  if (_mapController == null || _myPosition == null) return;

  final myLatLng = LatLng(_myPosition!.latitude, _myPosition!.longitude);

  // 내 위치 마커 - 파란 원
  await _mapController!.labelLayer.addPoi(
    myLatLng,
    style: PoiStyle(
      icon: KImage.fromAsset('assets/marker/my_location.png', 40, 40),
    ),
  );

  // 휴게소/졸음쉼터 마커
  for (final area in _restAreas) {
    await _mapController!.labelLayer.addPoi(
      LatLng(area.latitude, area.longitude),
      style: PoiStyle(
        icon: KImage.fromAsset(
          area.isDrowsyShelter
              ? 'assets/marker/drowsy.png'
              : 'assets/marker/rest_area.png',
          30, 42,
        ),
      ),
    );
  }

  // 중심점으로 카메라 이동
  if (_restAreas.isNotEmpty) {
    final allLats = [_myPosition!.latitude, ..._restAreas.map((a) => a.latitude)];
    final allLngs = [_myPosition!.longitude, ..._restAreas.map((a) => a.longitude)];
    final centerLat = (allLats.reduce((a, b) => a < b ? a : b) + allLats.reduce((a, b) => a > b ? a : b)) / 2;
    final centerLng = (allLngs.reduce((a, b) => a < b ? a : b) + allLngs.reduce((a, b) => a > b ? a : b)) / 2;

    await _mapController!.moveCamera(
      CameraUpdate.newCenterPosition(LatLng(centerLat, centerLng)),
      animation: const CameraAnimation(800),
    );
  } else {
    await _mapController!.moveCamera(
      CameraUpdate.newCenterPosition(myLatLng),
      animation: const CameraAnimation(500),
    );
  }
}

  Future<void> _onMoveTap(RestArea area) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('길안내 시작'),
          ],
        ),
        content: Text(
          '카카오맵으로 이동하면\n졸음 감지가 잠시 중단됩니다.\n\n${area.name}(으)로 안내를 시작할까요?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3F51B5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('이동', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok == true) await matchingService.navigateKakao(area);
  }

  void _moveToArea(RestArea area) {
    _mapController?.moveCamera(
      CameraUpdate.newCenterPosition(
        LatLng(area.latitude, area.longitude),
      ),
      animation: const CameraAnimation(500),
    );
  }

  @override
  Widget build(BuildContext context) {
    final initLat = _myPosition?.latitude ?? 37.5;
    final initLng = _myPosition?.longitude ?? 127.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Stack(
        children: [
          // ── 상단 지도 영역 ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.55,
            child: Stack(
              children: [
                // 카카오맵
                KakaoMap(
                  option: KakaoMapOption(
                    position: LatLng(initLat, initLng),
                    zoomLevel: 13,
                    mapType: MapType.normal,
                  ),
                  onMapReady: (controller) async {
                    print('🗺️ 지도 준비 완료!');
                    _mapController = controller;
                    if (_myPosition != null) {
                      await _updateMap();
                    }
                  },
                ),

                // 상단 헤더 그라디언트 오버레이
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFF1A237E).withOpacity(0.85),
                          const Color(0xFF1A237E).withOpacity(0.0),
                        ],
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('졸음이 감지되었습니다',
                                    style: TextStyle(
                                        color: Colors.white70, fontSize: 13)),
                                SizedBox(height: 2),
                                Text(
                                  '가까운 쉼터를 찾았어요',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            GestureDetector(
                              onTap: _load,
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.refresh,
                                    color: Colors.white, size: 22),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // 내 위치로 돌아가기 버튼
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: GestureDetector(
                    onTap: () {
                      if (_myPosition != null) {
                        _mapController?.moveCamera(
                          CameraUpdate.newCenterPosition(
                            LatLng(_myPosition!.latitude, _myPosition!.longitude),
                          ),
                          animation: const CameraAnimation(500),
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.gps_fixed,
                          color: Color(0xFF3F51B5), size: 22),
                    ),
                  ),
                ),

                // GPS 좌표 표시
                Positioned(
                  bottom: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: _myPosition != null ? mainGreen : warnYellow,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _myPosition != null
                              ? '${_myPosition!.latitude.toStringAsFixed(4)}°N  ${_myPosition!.longitude.toStringAsFixed(4)}°E'
                              : 'GPS 수신 중...',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── 하단 리스트 시트 ──
          DraggableScrollableSheet(
            initialChildSize: 0.47,
            minChildSize: 0.47,
            maxChildSize: 0.95,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(30)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 10,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 45,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "가까운 쉼터",
                            style: TextStyle(
                                fontSize: 17, fontWeight: FontWeight.w700),
                          ),
                          if (!_isLoading && _restAreas.isNotEmpty)
                            Text(
                              '${_restAreas.length}곳',
                              style: TextStyle(
                                  fontSize: 13, color: Colors.grey.shade500),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _error != null
                              ? Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.error_outline,
                                          color: Colors.red, size: 40),
                                      const SizedBox(height: 8),
                                      Text(
                                        _error!,
                                        textAlign: TextAlign.center,
                                        style:
                                            const TextStyle(color: Colors.red),
                                      ),
                                      const SizedBox(height: 12),
                                      ElevatedButton(
                                        onPressed: _load,
                                        child: const Text('다시 시도'),
                                      ),
                                    ],
                                  ),
                                )
                              : _restAreas.isEmpty
                                  ? const Center(
                                      child: Text('근처 휴게소/쉼터가 없어요'))
                                  : ListView.builder(
                                      controller: scrollController,
                                      itemCount: _restAreas.length,
                                      itemBuilder: (_, i) => _ShelterItem(
                                        area: _restAreas[i],
                                        onMoveTap: () =>
                                            _onMoveTap(_restAreas[i]),
                                        onCardTap: () =>
                                            _moveToArea(_restAreas[i]),
                                      ),
                                    ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ShelterItem extends StatelessWidget {
  final RestArea area;
  final VoidCallback onMoveTap;
  final VoidCallback onCardTap;

  const _ShelterItem({
    required this.area,
    required this.onMoveTap,
    required this.onCardTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDrowsy = area.isDrowsyShelter;
    final tagColor =
        isDrowsy ? mainGreen.withAlpha(4) : infoLightBlue.withAlpha(4);
    final tagTextColor = isDrowsy ? mainGreen : infoLightBlue;
    final icon = isDrowsy ? Icons.eco : Icons.local_parking;
    final displayName =
        isDrowsy ? '${area.name} 졸음쉼터' : '${area.name} 휴게소';

    return GestureDetector(
      onTap: onCardTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: inkBlack.withAlpha(4),
              blurRadius: 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: tagColor.withAlpha(40),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, size: 28, color: tagTextColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(displayName,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(
                    '${area.distance.toStringAsFixed(1)}km · ${area.roadName} ${area.direction}',
                    style: TextStyle(fontSize: 13, color: textMedium),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (area.hasToilet)
                        _MiniChip(label: '화장실', color: tagTextColor),
                      if (area.gasStation)
                        _MiniChip(label: '주유', color: tagTextColor),
                      if (area.evStation)
                        _MiniChip(label: 'EV', color: tagTextColor),
                    ],
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: onMoveTap,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 6, horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  "이동 →",
                  style: TextStyle(
                    color: infoBlue,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String label;
  final Color color;

  const _MiniChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(10),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: TextStyle(fontSize: 10, color: color)),
    );
  }
}