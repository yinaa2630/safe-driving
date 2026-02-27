import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DriveRecordService {
  final String baseUrl = "http://192.168.0.22:3000";
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  Future<bool> createDriveRecord({
    required String driveDate,
    required DateTime startTime,
    required DateTime endTime,
    required int duration,
    required double avgDrowsiness,
    required int warningCount,
  }) async {
    try {
      final token = await storage.read(key: 'user_token');

      if (token == null) {
        print("❌ 토큰 없음");
        return false;
      }

      final response = await http.post(
        Uri.parse("$baseUrl/drive-record"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "drive_date": driveDate,
          "start_time": startTime.toUtc().toIso8601String(),
          "end_time": endTime.toUtc().toIso8601String(),
          "duration": duration,
          "avg_drowsiness": avgDrowsiness,
          "warning_count": warningCount,
          "userId": 1,
        }),
      );

      print("DriveRecord STATUS: ${response.statusCode}");
      print("DriveRecord BODY: ${response.body}");

      if (response.statusCode == 201 || response.statusCode == 200) {
        print("✅ DB 저장 성공");
        return true;
      } else {
        print("❌ DB 저장 실패");
        return false;
      }
    } catch (e) {
      print("❌ DriveRecord 예외 발생: $e");
      return false;
    }
  }
}
