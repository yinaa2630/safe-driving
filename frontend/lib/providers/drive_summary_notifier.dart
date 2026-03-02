import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 주행 요약 데이터 모델
class DriveSummary {
  final int duration;           // 총 주행 시간 (초)
  final double avgDrowsiness;   // 평균 졸음 점수
  final int warningCount;       // WARNING 횟수
  final int attentionCount;     // ATTENTION 횟수

  DriveSummary({
    required this.duration,
    required this.avgDrowsiness,
    required this.warningCount,
    required this.attentionCount,
  });
}

/// 주행 요약 상태 관리 Notifier
class DriveSummaryNotifier extends Notifier<DriveSummary?> {
  @override
  DriveSummary? build() {
    return null; // 초기값은 없음
  }

  void setSummary(DriveSummary summary) {
    state = summary;
  }

  void clear() {
    state = null;
  }
}

/// Provider (여기에는 drivingIdProvider 절대 없음)
final driveSummaryProvider =
    NotifierProvider<DriveSummaryNotifier, DriveSummary?>(
  DriveSummaryNotifier.new,
);