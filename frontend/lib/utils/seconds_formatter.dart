String secondsFormatter(int totalSeconds) {
  final hours = totalSeconds ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;
  final seconds = totalSeconds % 60;

  return '${hours.toString().padLeft(2, '0')}시간 '
      '${minutes.toString().padLeft(2, '0')}분 '
      '${seconds.toString().padLeft(2, '0')}초';
}
