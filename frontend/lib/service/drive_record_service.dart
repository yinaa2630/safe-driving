import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DriveRecordService {
  final String baseUrl = "http://192.168.0.22:3000";
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  /// !! 주행 시작 !!
  Future<int?> startDrive({
    required String driveDate,
    required DateTime startTime,
    required double startLat,
    required double startLng,
  }) async {
    try {
      final token = await storage.read(key: 'user_token');
      if (token == null) {
        print("❌ 토큰 없음");
        return null;
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
          "start_lat": startLat,
          "start_lng": startLng,
        }),
      );

      print("Start STATUS: ${response.statusCode}");
      print("Start BODY: ${response.body}");

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data["id"]; // id 반환
      }

      return null;
    } catch (e) {
      print("❌ startDrive 예외: $e");
      return null;
    }
  }

  /// !! 주행 종료 !! (summary 업데이트)
  Future<bool> endDrive({
    required int driveId,
    required DateTime endTime,
    required int duration,
    required double avgDrowsiness,
    required int warningCount,
    required int attentionCount,
    required double endLat,
    required double endLng,
  }) async {
    try {
      final token = await storage.read(key: 'user_token');
      if (token == null) {
        print("❌ 토큰 없음");
        return false;
      }

      final response = await http.patch(
        Uri.parse("$baseUrl/drive-record/$driveId"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "end_time": endTime.toUtc().toIso8601String(),
          "duration": duration,
          "avg_drowsiness": avgDrowsiness,
          "warning_count": warningCount,
          "attention_count": attentionCount,
          "end_lat": endLat,
          "end_lng": endLng,
        }),
      );

      print("End STATUS: ${response.statusCode}");
      print("End BODY: ${response.body}");

      return response.statusCode == 200;
    } catch (e) {
      print("❌ endDrive 예외: $e");
      return false;
    }
  }
}