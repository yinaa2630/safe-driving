class DriveRecord {
  /// 주행 날짜
  final DateTime date;

  /// 주행 점수 (0~100)
  final double score;

  /// 주행 시간
  final Duration duration;

  /// 경고 횟수 (선택적 - 확장용)
  final int? warningCount;

  /// 평균 점수 (확장용)
  final double? averageScore;

  DriveRecord({
    required this.date,
    required this.score,
    required this.duration,
    this.warningCount,
    this.averageScore,
  });

  /// JSON → 객체 변환 (나중에 서버 연동용)
  factory DriveRecord.fromJson(Map<String, dynamic> json) {
    return DriveRecord(
      date: DateTime.parse(json['date']),
      score: (json['score'] as num).toDouble(),
      duration: Duration(minutes: json['durationMinutes']),
      warningCount: json['warningCount'],
      averageScore: json['averageScore'] != null
          ? (json['averageScore'] as num).toDouble()
          : null,
    );
  }

  /// 객체 → JSON 변환 (API 전송용)
  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'score': score,
      'durationMinutes': duration.inMinutes,
      'warningCount': warningCount,
      'averageScore': averageScore,
    };
  }
}