import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  final String baseUrl = "http://192.168.0.22:3000";

  // 🔥 회원가입 개선 버전
  Future<String?> register(
      String email, String password, String name) async {
    try {
      final response = await http
          .post(
            Uri.parse("$baseUrl/auth/register"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "email": email,
              "password": password,
              "username": name,
            }),
          )
          .timeout(const Duration(seconds: 5));

      print("REGISTER STATUS: ${response.statusCode}");
      print("REGISTER BODY: ${response.body}");

      if (response.statusCode == 201) {
        return null; // 성공
      }

      // 🔥 에러 메시지 반환
      final data = jsonDecode(response.body);
      return data["message"] ?? "회원가입 실패";

    } catch (e) {
      print("Register Network error: $e");
      return "서버 연결 실패";
    }
  }

  // 🔒 로그인 (그대로 유지)
  Future<String?> login(String email, String password) async {
    try {
      final response = await http
          .post(
            Uri.parse("$baseUrl/auth/login"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "email": email,
              "password": password,
            }),
          )
          .timeout(const Duration(seconds: 5));

      print("STATUS: ${response.statusCode}");
      print("BODY: ${response.body}");

      if (response.statusCode == 200 ||
          response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data["accessToken"];
      } else {
        return null;
      }
    } catch (e) {
      print("Network error: $e");
      return null;
    }
  }
}