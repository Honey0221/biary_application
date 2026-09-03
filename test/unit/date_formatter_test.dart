import 'package:flutter_test/flutter_test.dart';
import 'package:honey/core/utils/date_formatter.dart';

void main() {
  group('DateFormatter.toDateLabel', () {
    test('월, 일이 한 자리일 때 앞에 0을 붙여 yyyy.MM.dd 형식으로 변환한다', () {
      expect(DateFormatter.toDateLabel(DateTime(2026, 9, 3)), '2026.09.03');
    });

    test('연말 날짜를 정상 변환한다', () {
      expect(DateFormatter.toDateLabel(DateTime(2025, 12, 31)), '2025.12.31');
    });
  });

  group('DateFormatter.toKoreanDate', () {
    test('9월 2일 변환', () {
      expect(DateFormatter.toKoreanDate(DateTime(2026, 9, 2)), '2026년 9월 2일 (수)');
    });
  });

  group('DateFormatter.toTimeLabel', () {
    test('방금 전 출력 테스트', () {
      final date = DateTime.now().subtract(const Duration(seconds: 30));
      expect(DateFormatter.toTimeLabel(date), '방금 전');
    });

    test('30분 전 출력 테스트', () {
      final date = DateTime.now().subtract(const Duration(minutes: 30));
      expect(DateFormatter.toTimeLabel(date), '30분 전');
    });

    test('5시간 전 출력 테스트', () {
      final date = DateTime.now().subtract(const Duration(hours: 5));
      expect(DateFormatter.toTimeLabel(date), '5시간 전');
    });

    test('30일 이상 출력 테스트', () {
      final date = DateTime(2026, 1, 1);
      expect(DateFormatter.toTimeLabel(date), DateFormatter.toDateLabel(date));
    });
  });
}