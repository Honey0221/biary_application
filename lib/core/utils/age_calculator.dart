class AgeCalculator {
  AgeCalculator._();

  // 개월수 계산
  static int toMonths(DateTime birthDate) {
    final now = DateTime.now();
    int months = (now.year - birthDate.year) * 12 + (now.month - birthDate.month);
    if (now.day < birthDate.day) months--;
    return months < 0 ? 0 : months;
  }

  // 개월수를 라벨로 변환
  static String toLabel(DateTime birthDate) {
    final months = toMonths(birthDate);
    final years = months ~/ 12;
    final rem = months % 12;
    if (years == 0) return '만 $months개월';
    if (rem == 0) return '만 $years세';
    return '만 $years세 $rem개월';
  }
}