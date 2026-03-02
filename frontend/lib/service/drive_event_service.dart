import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DriveEventService {
  final String baseUrl = "http://192.168.0.22:3000";
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  Future<void> saveEvent({
    required int driveRecordId,
    required String eventType,
    required double score,
    required double lat,
    required double lng,
  }) async {
    final token = await storage.read(key: 'user_token');
    if (token == null) {
      print("❌ 이벤트 저장 실패 - 토큰 없음");
      return;
    }

    final response = await http.post(
      Uri.parse("$baseUrl/drive-events"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "drive_record_id": driveRecordId,
        "event_type": eventType,
        "event_time": DateTime.now().toUtc().toIso8601String(),
        "lat": lat,
        "lng": lng,
        "score": score,
      }),
    );

    print("Event STATUS: ${response.statusCode}");
    print("Event BODY: ${response.body}");
  }
}