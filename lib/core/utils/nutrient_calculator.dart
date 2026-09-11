import 'package:honey/core/constants/nutrient_codes.dart';
import 'package:honey/data/models/dri_reference.dart';
import 'package:honey/data/models/food_search_result.dart';

class FoodIntakeEntry {
  final FoodSearchResult food;
  final double intakeAmountG;

  const FoodIntakeEntry({
    required this.food,
    required this.intakeAmountG
  });
}

class NutrientCalculator {
  // 식단 기록의 총 영양소 섭취량 계산
  static Map<String, double> calcIntake(List<FoodIntakeEntry> entries) {
    final totals = <String, double>{};

    for (final entry in entries) {
      final food = entry.food;
      final baseAmount = (food.servingSize != null && food.servingSize! > 0) ?
        food.servingSize! : 100.0;
      final ratio = entry.intakeAmountG / baseAmount;

      for (final code in NutrientCodes.displayOrder) {
        final raw = food.nutrients[code];
        if (raw == null || raw <= 0) continue;
        totals[code] = (totals[code] ?? 0.0) + raw * ratio;
      }
    }

    return totals;
  }

  // 당류 에너지 비율 계산 (3세 이상, 목표 20%)
  static double? calcSugarEnergyRatio(Map<String, double> intake) {
    final energy = intake[NutrientCodes.energy];
    final sugar = intake[NutrientCodes.sugar];
    if (energy == null || energy <= 0 || sugar == null) return null;
    return (sugar * 4) / energy * 100;
  }

  // DRI 달성률 계산
  static Map<String, double> calcAchievement({
    required Map<String, double> intake,
    required DriMap driMap,
    required int ageMonths
  }) {
    final achievement = <String, double>{};

    for (final code in NutrientCodes.displayOrder) {
      final consumed = intake[code];
      if (consumed == null) continue;

      // 당류: 3세(36개월) 이상은 에너지 비율 기반
      if (code == NutrientCodes.sugar && ageMonths >= 36) {
        final ratio = calcSugarEnergyRatio(intake);
        if (ratio != null) {
          achievement[code] = (ratio / 20.0 * 100).clamp(0.0, 999.9);
        }
        continue;
      }

      final recommended = driMap[code]?.recommendedAmount;
      if (recommended == null || recommended <= 0) continue;
      achievement[code] = (consumed / recommended * 100).clamp(0.0, 999.9);
    }

    return achievement;
  }

  // 게스트용 간이 게산 (열량, 탄단지 4가지만)
  static Map<String, double> calcGuestAchievement({
    required List<FoodIntakeEntry> entries,
    required DriMap driMap
  }) {
    final intake = calcIntake(entries);
    const guestCodes = [
      NutrientCodes.energy,
      NutrientCodes.carbs,
      NutrientCodes.protein,
      NutrientCodes.fat
    ];

    final achievement = <String, double>{};
    for (final code in guestCodes) {
      final consumed = intake[code];
      final recommended = driMap[code]?.recommendedAmount;
      if (consumed == null || recommended == null || recommended <= 0) continue;
      achievement[code] = (consumed / recommended * 100).clamp(0.0, 999.9);
    }
    return achievement;
  }

  // 달성률별 상태 판정
  static NutrientStatus statusFromRate(double rate) {
    if (rate < 50)    return NutrientStatus.deficient;
    if (rate < 70)    return NutrientStatus.slightlyLow;
    if (rate <= 120)  return NutrientStatus.adequate;
    if (rate <= 150)  return NutrientStatus.slightlyHigh;
    return                   NutrientStatus.excess;
  }

  // 바 표시용 달성률 대략 계산
  static double rateFromStatus(String? status) {
    return switch (status) {
      'deficient' => 35.0,
      'slightlyLow' => 60.0,
      'adequate' => 90.0,
      'slightlyHigh' => 130.0,
      'excess' => 160.0,
      _ => 0.0
    };
  }

  // 전체 상태 요약 맵 생성 (Supabase JSONB 저장용)
  static Map<String, String> buildStatusSummary(Map<String, double> achievement) {
    return achievement.map(
      (code, rate) => MapEntry(code, statusFromRate(rate).name)
    );
  }
}

enum NutrientStatus {
  deficient,      // < 50% 빨강
  slightlyLow,    // 50 ~ 70% 주황
  adequate,       // 70 ~ 120% 초록
  slightlyHigh,   // 120 ~ 150% 노랑
  excess,         // > 150% 진빨강
  noStandard      // DRI 없음 회색
}