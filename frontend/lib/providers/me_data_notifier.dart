import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 프로필 정보
class MeData {
  final String email; // 이메일
  final String username; // 사용자 이름
  final String emergencyCall; // 비상 연락처

  MeData({
    required this.email,
    required this.username,
    required this.emergencyCall,
  });

  factory MeData.fromJson(Map<String, dynamic> json) {
    return MeData(
      email: json['email'] ?? '',
      username: json['username'] ?? '',
      emergencyCall: json['emergencyCall'] ?? '',
    );
  }
}

/// 프로필 상태 관리 Notifier
class MeDataNotifier extends Notifier<MeData?> {
  @override
  MeData? build() {
    return null; // 초기값은 없음
  }

  void setData(MeData meData) {
    state = meData;
  }

  void clear() {
    state = null;
  }
}

/// Provider
final meDataProvider = NotifierProvider<MeDataNotifier, MeData?>(
  MeDataNotifier.new,
);
