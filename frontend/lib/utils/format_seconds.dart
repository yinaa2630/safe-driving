String formatSeconds(int totalSeconds) {
  final hours = totalSeconds ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;
  final seconds = totalSeconds % 60;

  final buffer = StringBuffer();

  if (hours > 0) {
    buffer.write('${hours.toString().padLeft(2, '0')}시간 ');
  }

  if (minutes > 0) {
    buffer.write('${minutes.toString().padLeft(2, '0')}분 ');
  }

  // 초는 항상 표시 (전체가 0초인 경우 대비)
  if (seconds > 0 || buffer.isEmpty) {
    buffer.write('${seconds.toString().padLeft(2, '0')}초');
  }

  return buffer.toString().trim();
}
