String formatPhoneNumber(String input) {
  // 숫자만 남기기
  final numbers = input.replaceAll(RegExp(r'[^0-9]'), '');

  if (numbers.length == 11) {
    return '${numbers.substring(0, 3)}-'
        '${numbers.substring(3, 7)}-'
        '${numbers.substring(7)}';
  } else if (numbers.length == 10) {
    // 011, 016 같은 구형 번호
    return '${numbers.substring(0, 3)}-'
        '${numbers.substring(3, 6)}-'
        '${numbers.substring(6)}';
  }

  return input; // 형식 안 맞으면 원본 반환
}
