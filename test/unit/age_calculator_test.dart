import 'package:flutter_test/flutter_test.dart';
import 'package:honey/core/utils/age_calculator.dart';

void main() {
  // 테스트 기준일을 고정하기 위해 실제 now() 대신 상대 계산을 활용
  final now = DateTime.now();

  group('AgeCalculator.toMonths()', () {
    test('생일이 오늘이면 0개월', () {
      expect(AgeCalculator.toMonths(now), 0);
    });

    test('정확히 1개월 전이면 1개월', () {
      final oneMonthAgo = DateTime(now.year, now.month - 1, now.day);
      expect(AgeCalculator.toMonths(oneMonthAgo), 1);
    });

    test('정확히 12개월 전이면 12개월', () {
      final oneYearAgo = DateTime(now.year - 1, now.month, now.day);
      expect(AgeCalculator.toMonths(oneYearAgo), 12);
    });

    test('생일이 아직 안 지난 달은 한 달 덜 계산된다', () {
      // 이번 달 day보다 1일 큰 날을 생일로 설정 → 아직 생일 안 지남
      final birthDate = DateTime(now.year - 1, now.month, now.day + 1);
      // 생일이 아직 안 지났으므로 11개월
      expect(AgeCalculator.toMonths(birthDate), 11);
    });

    test('미래 날짜이면 0개월 반환', () {
      final future = DateTime(now.year + 1, now.month, now.day);
      expect(AgeCalculator.toMonths(future), 0);
    });

    test('24개월(만 2세)이면 24개월', () {
      final twoYearsAgo = DateTime(now.year - 2, now.month, now.day);
      expect(AgeCalculator.toMonths(twoYearsAgo), 24);
    });
  });

  group('AgeCalculator.toLabel()', () {
    test('0개월이면 "만 0개월"', () {
      expect(AgeCalculator.toLabel(now), '만 0개월');
    });

    test('6개월이면 "만 6개월"', () {
      final sixMonthsAgo = DateTime(now.year, now.month - 6, now.day);
      expect(AgeCalculator.toLabel(sixMonthsAgo), '만 6개월');
    });

    test('12개월(만 1세 0개월)이면 "만 1세"', () {
      final oneYearAgo = DateTime(now.year - 1, now.month, now.day);
      expect(AgeCalculator.toLabel(oneYearAgo), '만 1세');
    });

    test('14개월이면 "만 1세 2개월"', () {
      // 1년 2개월 전
      final birthDate = DateTime(now.year - 1, now.month - 2, now.day);
      expect(AgeCalculator.toLabel(birthDate), '만 1세 2개월');
    });

    test('24개월이면 "만 2세"', () {
      final twoYearsAgo = DateTime(now.year - 2, now.month, now.day);
      expect(AgeCalculator.toLabel(twoYearsAgo), '만 2세');
    });

    test('36개월이면 "만 3세"', () {
      final threeYearsAgo = DateTime(now.year - 3, now.month, now.day);
      expect(AgeCalculator.toLabel(threeYearsAgo), '만 3세');
    });
  });
}