import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  final String baseUrl = "http://192.168.0.22:3000";
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  // 회원가입
  Future<String?> register(String email, String password, String name) async {
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

      if (response.statusCode == 201) {
        return null; // 성공
      }

      final data = jsonDecode(response.body);
      return data["message"] ?? "회원가입 실패";
    } catch (e) {
      print("Register Network error: $e");
      return "서버 연결 실패";
    }
  }

  // 로그인
  Future<String?> login(String email, String password) async {
    try {
      final response = await http
          .post(
            Uri.parse("$baseUrl/auth/login"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({"email": email, "password": password}),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final token = data["accessToken"];

        // 토큰 저장
        await storage.write(key: 'user_token', value: token);

        return token;
      } else {
        return null;
      }
    } catch (e) {
      print("Network error: $e");
      return null;
    }
  }

  // 토큰 가져오기
  Future<String?> getToken() async {
    return await storage.read(key: 'user_token');
  }

  // 로그아웃
  Future<void> logout() async {
    await storage.delete(key: 'user_token');
  }

  // 내 정보 조회
  Future<Map<String, dynamic>?> getMe() async {
    final token = await getToken();
    if (token == null) return null;

    final response = await http.get(
      Uri.parse("$baseUrl/auth/me"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    return null;
  }
}
