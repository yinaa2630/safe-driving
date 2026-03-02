import 'package:flutter_riverpod/flutter_riverpod.dart';

class DrivingIdNotifier extends Notifier<String?> {
  @override
  String? build() {
    return null; // 초기값
  }

  void setId(String id) {
    state = id;
  }

  void clear() {
    state = null;
  }
}

final drivingIdProvider = NotifierProvider<DrivingIdNotifier, String?>(
  DrivingIdNotifier.new,
);
