import 'package:flutter/material.dart';
import 'package:flutter_demo/screens/map_overview_screen.dart';
import 'package:flutter_demo/service/matching_service.dart';
import 'package:flutter_demo/theme/colors.dart';
import 'package:geolocator/geolocator.dart';

class MatchingScreen extends StatefulWidget {
  const MatchingScreen({super.key});

  @override
  State<MatchingScreen> createState() => _MatchingScreenState();
}

class _MatchingScreenState extends State<MatchingScreen> {
  final matchingService = MatchingService();
  final _mapKey = GlobalKey<MapOverviewScreenState>();

  Position? _myPosition;
  double _bearing = -1;
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

      // ✅ GPS bearing 계산
      final bearing = matchingService.calcBearing(pos);

      setState(() {
        _myPosition = pos;
        _bearing = bearing;
      });

      debugPrint('📍 위치: ${pos.latitude}, ${pos.longitude}');
      debugPrint('🧭 bearing: $bearing (heading: ${pos.heading})');

      final response = await matchingService.getRestAreas(
        pos.latitude,
        pos.longitude,
        bearing,
      );

      setState(() {
        _restAreas = response.map((e) => RestArea.fromJson(e)).toList();
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
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
    _mapKey.currentState?.moveToLocation(area.latitude, area.longitude);
  }

  @override
  Widget build(BuildContext context) {
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
                // ✅ 로딩 완전히 끝난 후에만 지도 렌더링
                if (_myPosition != null && !_isLoading)
                  MapOverviewScreen(
                    key: _mapKey,
                    myPosition: _myPosition!,
                    drowsyShelters: _restAreas
                        .where((a) => a.isDrowsyShelter)
                        .toList(),
                    restAreas: _restAreas
                        .where((a) => !a.isDrowsyShelter)
                        .toList(),
                  )
                else
                  Container(
                    color: const Color(0xFFE8EAF6),
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            color: Color(0xFF3F51B5),
                          ),
                          SizedBox(height: 12),
                          Text(
                            '위치 및 쉼터 정보를 불러오는 중...',
                            style: TextStyle(
                              color: Color(0xFF3F51B5),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // 상단 헤더 그라디언트
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

                // 버튼들
                if (_myPosition != null && !_isLoading) ...[
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () => _mapKey.currentState?.fitAll(),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            margin: const EdgeInsets.only(bottom: 8),
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
                            child: const Icon(Icons.zoom_out_map,
                                color: Color(0xFF3F51B5), size: 22),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _mapKey.currentState?.moveToLocation(
                            _myPosition!.latitude,
                            _myPosition!.longitude,
                          ),
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
                      ],
                    ),
                  ),

                  // GPS 좌표 + bearing 표시
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
                              color: mainGreen,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${_myPosition!.latitude.toStringAsFixed(4)}°N  ${_myPosition!.longitude.toStringAsFixed(4)}°E'
                            '  🧭${_bearing < 0 ? '-' : '${_bearing.toStringAsFixed(0)}°'}',
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
                                        style: const TextStyle(
                                            color: Colors.red),
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