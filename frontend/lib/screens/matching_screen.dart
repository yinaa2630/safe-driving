import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

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
      latitude = (j['latitude'] as num).toDouble(),
      longitude = (j['longitude'] as num).toDouble(),
      direction = j['direction'] ?? '',
      roadName = j['road_name'] ?? '',
      parkingCount = j['parking_count'] ?? 0,
      hasToilet = j['has_toilet'] ?? false,
      gasStation = j['gas_station'] ?? false,
      evStation = j['ev_station'] ?? false,
      phone = j['phone'] ?? '',
      distance = (j['distance'] as num).toDouble();

  bool get isDrowsyShelter => type == 'DROWSY_SHELTER';
}

class MatchingScreen extends StatefulWidget {
  const MatchingScreen({super.key});

  @override
  State<MatchingScreen> createState() => _MatchingScreenState();
}

class _MatchingScreenState extends State<MatchingScreen> {
  static const String _baseUrl = 'http://192.168.0.22:3000';

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
      final pos = await _getLocation();
      setState(() => _myPosition = pos);
      await _fetchRestAreas(pos.latitude, pos.longitude);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<Position> _getLocation() async {
    if (!await Geolocator.isLocationServiceEnabled())
      throw Exception('위치 서비스가 꺼져 있어요.');
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied)
      perm = await Geolocator.requestPermission();
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever)
      throw Exception('위치 권한이 필요해요.');
    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  Future<void> _fetchRestAreas(double lat, double lng) async {
    final uri = Uri.parse(
      '$_baseUrl/rest-area/nearest?lat=$lat&lng=$lng&bearing=0&limit=3',
    );
    final res = await http.get(uri).timeout(const Duration(seconds: 10));
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List;
      setState(() {
        _restAreas = list.map((e) => RestArea.fromJson(e)).toList();
      });
    } else {
      throw Exception('데이터 오류 (${res.statusCode})');
    }
  }

  Future<void> _navigateTo(RestArea area) async {
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
    if (ok == true) await _navigateTo(area);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Stack(
        children: [
          Positioned.fill(
            child: _TopLocationPanel(
              position: _myPosition,
              isLoading: _isLoading,
              onRefresh: _load,
            ),
          ),
          DraggableScrollableSheet(
            initialChildSize: 0.45,
            minChildSize: 0.45,
            maxChildSize: 0.95,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
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
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (!_isLoading && _restAreas.isNotEmpty)
                            Text(
                              '${_restAreas.length}곳',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade500,
                              ),
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
                                  const Icon(
                                    Icons.error_outline,
                                    color: Colors.red,
                                    size: 40,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _error!,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(color: Colors.red),
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
                          ? const Center(child: Text('근처 휴게소/쉼터가 없어요'))
                          : ListView.builder(
                              controller: scrollController,
                              itemCount: _restAreas.length,
                              itemBuilder: (_, i) => _ShelterItem(
                                area: _restAreas[i],
                                onMoveTap: () => _onMoveTap(_restAreas[i]),
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

class _TopLocationPanel extends StatelessWidget {
  final Position? position;
  final bool isLoading;
  final VoidCallback onRefresh;

  const _TopLocationPanel({
    required this.position,
    required this.isLoading,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A237E), Color(0xFF3F51B5)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '졸음이 감지되었습니다',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
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
                    onTap: onRefresh,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.refresh,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.my_location,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: isLoading
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  height: 14,
                                  width: 120,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(7),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  height: 12,
                                  width: 180,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                              ],
                            )
                          : position == null
                          ? const Text(
                              '위치를 가져오는 중...',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '현재 위치',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${position!.latitude.toStringAsFixed(4)}°N, ${position!.longitude.toStringAsFixed(4)}°E',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '정확도 ${position!.accuracy.toStringAsFixed(0)}m',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.6),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: position != null
                            ? const Color(0xFF4CAF50).withOpacity(0.3)
                            : Colors.orange.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: position != null
                                  ? const Color(0xFF4CAF50)
                                  : Colors.orange,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            position != null ? 'GPS' : '...',
                            style: TextStyle(
                              color: position != null
                                  ? const Color(0xFF4CAF50)
                                  : Colors.orange,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShelterItem extends StatelessWidget {
  final RestArea area;
  final VoidCallback onMoveTap;

  const _ShelterItem({required this.area, required this.onMoveTap});

  @override
  Widget build(BuildContext context) {
    final isDrowsy = area.isDrowsyShelter;
    final tagColor = isDrowsy
        ? const Color(0xFFDFF6DD)
        : const Color(0xFFE8F1FF);
    final tagTextColor = isDrowsy
        ? const Color(0xFF58A766)
        : const Color(0xFF4C7BD9);
    final icon = isDrowsy ? Icons.eco : Icons.local_parking;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
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
              color: tagColor.withOpacity(0.4),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, size: 28, color: tagTextColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  area.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${area.distance.toStringAsFixed(1)}km · ${area.roadName} ${area.direction}',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
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
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 14),
              decoration: BoxDecoration(
                color: tagColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                "이동 →",
                style: TextStyle(
                  color: tagTextColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
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
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: TextStyle(fontSize: 10, color: color)),
    );
  }
}
