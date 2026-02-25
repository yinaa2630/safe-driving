import 'package:flutter/material.dart';
import 'package:flutter_demo/theme/colors.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class RestStopScreen extends StatefulWidget {
  final double latitude;
  final double longitude;
  final double bearing;

  const RestStopScreen({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.bearing,
  });

  @override
  State<RestStopScreen> createState() => _RestStopScreenState();
}

class _RestStopScreenState extends State<RestStopScreen> {
  List<dynamic> _restStops = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchNearestRestStops();
  }

  Future<void> _fetchNearestRestStops() async {
    print(
      '서버 요청 시작: lat=${widget.latitude}, lng=${widget.longitude}, bearing=${widget.bearing}',
    );
    try {
      final uri = Uri.parse(
        'http://192.168.0.22:3000/rest-area/nearest'
        '?lat=${widget.latitude}'
        '&lng=${widget.longitude}'
        '&bearing=${widget.bearing}'
        '&limit=5',
      );

      print('요청 URL: $uri');

      final response = await http.get(uri);

      print('응답 코드: ${response.statusCode}');
      print('응답 바디: ${response.body}');

      if (response.statusCode == 200) {
        setState(() {
          _restStops = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = '서버 오류가 발생했습니다.';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('네트워크 에러 상세: $e');
      setState(() {
        _errorMessage = '네트워크 오류가 발생했습니다.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '가까운 휴게소',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.grey),
                  SizedBox(height: 12),
                  Text(_errorMessage!, style: TextStyle(color: Colors.grey)),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isLoading = true;
                        _errorMessage = null;
                      });
                      _fetchNearestRestStops();
                    },
                    child: Text('다시 시도'),
                  ),
                ],
              ),
            )
          : _restStops.isEmpty
          ? Center(
              child: Text(
                '주행 방향에 휴게소가 없습니다.',
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: _restStops.length,
              itemBuilder: (context, index) {
                final place = _restStops[index];
                return _buildRestStopCard(place);
              },
            ),
    );
  }

  Widget _buildRestStopCard(Map<String, dynamic> place) {
    final bool isRestArea = place['type'] == 'REST_AREA';

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상단: 이름 + 타입 뱃지
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                place['name'] ?? '',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isRestArea
                      ? mainGreen.withOpacity(0.1)
                      : Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isRestArea ? '휴게소' : '졸음쉼터',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isRestArea ? mainGreen : Colors.blue,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 8),

          // 도로명 + 방향
          Text(
            '${place['road_name'] ?? ''} · ${place['direction'] ?? ''}',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),

          SizedBox(height: 12),

          // 거리
          Row(
            children: [
              Icon(Icons.location_on, size: 16, color: dangerRed),
              SizedBox(width: 4),
              Text(
                '${place['distance']} km',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: dangerRed,
                ),
              ),
            ],
          ),

          SizedBox(height: 12),

          // 편의시설 아이콘들
          Row(
            children: [
              if (place['has_toilet'] == true) _buildAmenity(Icons.wc, '화장실'),
              if (place['gas_station'] == true)
                _buildAmenity(Icons.local_gas_station, '주유소'),
              if (place['ev_station'] == true)
                _buildAmenity(Icons.ev_station, '전기차'),
              if (place['parking_count'] != null)
                _buildAmenity(
                  Icons.local_parking,
                  '${place['parking_count']}면',
                ),
            ],
          ),

          // 전화번호 (있을 때만)
          if (place['phone'] != null) ...[
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.phone, size: 14, color: Colors.grey),
                SizedBox(width: 4),
                Text(
                  place['phone'],
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAmenity(IconData icon, String label) {
    return Container(
      margin: EdgeInsets.only(right: 8),
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Color(0xFFF8F7F4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Color(0xFFEDEDED)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 13, color: Colors.grey),
          SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}
