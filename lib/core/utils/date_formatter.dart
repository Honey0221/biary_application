class DateFormatter {
  DateFormatter._();

  // yyyy.mm.dd
  static String toDateLabel(DateTime date) {
    return '${date.year}.'
      '${date.month.toString().padLeft(2, '0')}.'
      '${date.day.toString().padLeft(2, '0')}';
  }

  // yyyy년 m월 d일 (일~토)
  static String toKoreanDate(DateTime date) {
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final wd = weekdays[date.weekday - 1];
    return '${date.year}년 ${date.month}월 ${date.day}일 ($wd)';
  }

  // 방금 전 / N분 전 / N시간 전 / N일 전
  static String toTimeLabel(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return '방금 전';
    if (diff.inHours < 1) return '${diff.inMinutes}분 전';
    if (diff.inDays < 1) return '${diff.inHours}시간 전';
    if (diff.inDays < 30) return '${diff.inDays}일 전';
    return toDateLabel(date);
  }
}