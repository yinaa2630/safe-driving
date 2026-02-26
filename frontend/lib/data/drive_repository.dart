import 'dart:convert';
import 'package:http/http.dart' as http;

class DriveRepository {
  final String baseUrl = "http://192.168.0.22:3000";

  Future<int?> startDrive(int userId) async {
    final response = await http.post(
      Uri.parse("$baseUrl/drive-record"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "user_id": userId,
        "drive_date": DateTime.now().toIso8601String(),
        "start_time": DateTime.now().toIso8601String(),
      }),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return data["id"];
    }

    return null;
  }

  Future<void> endDrive(int driveId) async {
    await http.patch(
      Uri.parse("$baseUrl/drive-record/$driveId"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "end_time": DateTime.now().toIso8601String(),
      }),
    );
  }
}