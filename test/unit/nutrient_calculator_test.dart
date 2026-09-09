import 'package:flutter_test/flutter_test.dart';
import 'package:honey/core/constants/nutrient_codes.dart';
import 'package:honey/core/utils/nutrient_calculator.dart';
import 'package:honey/data/models/dri_reference.dart';
import 'package:honey/data/models/food_search_result.dart';

// 음식 픽스처
FoodSearchResult _makeChicken({double servingSize = 100}) => FoodSearchResult(
  foodCode: 'TEST001', foodName: '닭가슴살', servingSize: servingSize,
  nutrients: {
    NutrientCodes.energy: 165.0, NutrientCodes.carbs: 0.0,
    NutrientCodes.protein: 31.0, NutrientCodes.fat: 3.6,
    NutrientCodes.sugar: 0.0, NutrientCodes.fiber: 0.0,
    NutrientCodes.sodium: 74.0, NutrientCodes.calcium: 15.0,
    NutrientCodes.iron: 1.0, NutrientCodes.zinc: 1.0,
    NutrientCodes.vitaminA: 0.0, NutrientCodes.vitaminC: 0.0,
    NutrientCodes.vitaminD: 0.0
  }
);

final _apple = FoodSearchResult(
  foodCode: 'TEST002', foodName: '사과', servingSize: 100,
  nutrients: {
    NutrientCodes.energy: 52.0, NutrientCodes.carbs: 14.0,
    NutrientCodes.protein: 0.3, NutrientCodes.fat: 0.2,
    NutrientCodes.sugar: 10.0, NutrientCodes.fiber: 2.4,
    NutrientCodes.sodium: 1.0, NutrientCodes.calcium: 6.0,
    NutrientCodes.iron: 0.1, NutrientCodes.zinc: 0.04,
    NutrientCodes.vitaminA: 3.0, NutrientCodes.vitaminC: 4.6,
    NutrientCodes.vitaminD: 0.0
  }
);

DriMap _makeDri({double? sugarRni}) => {
  NutrientCodes.energy:   DriReference(
    ageGroupCode: '3_5y', nutrientCode: NutrientCodes.energy, recommendedAmount: 1400.0),
  NutrientCodes.carbs:    DriReference(
    ageGroupCode: '3_5y', nutrientCode: NutrientCodes.carbs, recommendedAmount: 210.0),
  NutrientCodes.protein:  DriReference(
    ageGroupCode: '3_5y', nutrientCode: NutrientCodes.protein, recommendedAmount: 20.0),
  NutrientCodes.fat:      DriReference(
    ageGroupCode: '3_5y', nutrientCode: NutrientCodes.fat, recommendedAmount: 40.0),
  NutrientCodes.sugar:    DriReference(
    ageGroupCode: '3_5y', nutrientCode: NutrientCodes.sugar, recommendedAmount: sugarRni),
  NutrientCodes.fiber:    DriReference(
    ageGroupCode: '3_5y', nutrientCode: NutrientCodes.fiber, recommendedAmount: 15.0),
  NutrientCodes.sodium:   DriReference(
    ageGroupCode: '3_5y', nutrientCode: NutrientCodes.sodium, recommendedAmount: 1000.0),
  NutrientCodes.calcium:  DriReference(
    ageGroupCode: '3_5y', nutrientCode: NutrientCodes.calcium, recommendedAmount: 600.0),
  NutrientCodes.iron:     DriReference(
    ageGroupCode: '3_5y', nutrientCode: NutrientCodes.iron, recommendedAmount: 7.0),
  NutrientCodes.zinc:     DriReference(
    ageGroupCode: '3_5y', nutrientCode: NutrientCodes.zinc, recommendedAmount: 4.0),
  NutrientCodes.vitaminA: DriReference(
    ageGroupCode: '3_5y', nutrientCode: NutrientCodes.vitaminA, recommendedAmount: 250.0),
  NutrientCodes.vitaminC: DriReference(
    ageGroupCode: '3_5y', nutrientCode: NutrientCodes.vitaminC, recommendedAmount: 40.0),
  NutrientCodes.vitaminD: DriReference(
    ageGroupCode: '3_5y', nutrientCode: NutrientCodes.vitaminD, recommendedAmount: 10.0),
};

void main() {
  group('calcIntake', () {
    test('빈 입력 -> 빈 맵 반환', () {
      expect(NutrientCalculator.calcIntake([]), isEmpty);
    });

    test('단일 음식 100g -> 픽스처 값 그대로 반환', () {
      final result = NutrientCalculator.calcIntake([
        FoodIntakeEntry(food: _makeChicken(), intakeAmountG: 100)
      ]);
      expect(result[NutrientCodes.energy], closeTo(165.0, 0.01));
      expect(result[NutrientCodes.protein], closeTo(31.0, 0.01));
    });

    test('섭취량 50g (servingSize 100g) -> 0.5배 적용', () {
      final result = NutrientCalculator.calcIntake([
        FoodIntakeEntry(food: _makeChicken(), intakeAmountG: 50)
      ]);
      expect(result[NutrientCodes.energy], closeTo(82.5, 0.01));
      expect(result[NutrientCodes.protein], closeTo(15.5, 0.01));
    });

    test('servingSize 200g일 때 100g 섭취 -> 0.5배 적용', () {
      final result = NutrientCalculator.calcIntake([
        FoodIntakeEntry(food: _makeChicken(servingSize: 200), intakeAmountG: 100)
      ]);
      expect(result[NutrientCodes.energy], closeTo(82.5, 0.01));
    });

    test('servingSize null -> 100g 기준으로 롤백', () {
      final food = FoodSearchResult(
        foodCode: 'T', foodName: 'T', servingSize: null,
        nutrients: {NutrientCodes.energy: 200.0}
      );
      final result = NutrientCalculator.calcIntake([
        FoodIntakeEntry(food: food, intakeAmountG: 50)
      ]);
      expect(result[NutrientCodes.energy], closeTo(100.0, 0.01));
    });

    test('두 음식 합산', () {
      final result = NutrientCalculator.calcIntake([
        FoodIntakeEntry(food: _makeChicken(), intakeAmountG: 100),
        FoodIntakeEntry(food: _apple, intakeAmountG: 100)
      ]);
      expect(result[NutrientCodes.energy], closeTo(217.0, 0.01));
      expect(result[NutrientCodes.protein], closeTo(31.3, 0.01));
    });
  });

  group('calcSugarEnergyRatio', () {
    test('정상 계산: sugar=10g, energy=200kcal -> 20.0%', () {
      final result = NutrientCalculator.calcSugarEnergyRatio({
        NutrientCodes.energy: 200.0, NutrientCodes.sugar: 10.0
      });
      expect(result, closeTo(20.0, 0.01));
    });

    test('energy가 0이면 null 반환', () {
      expect(NutrientCalculator.calcSugarEnergyRatio({
        NutrientCodes.energy: 0.0, NutrientCodes.sugar: 10.0
      }), isNull);
    });

    test('sugar 키 없으면 null 반환', () {
      expect(NutrientCalculator.calcSugarEnergyRatio({
        NutrientCodes.energy: 200.0
      }), isNull);
    });
  });

  group('calcAchievement', () {
    test('단백질 100% 달성 (31g / DRI 31g)', () {
      final dri = _makeDri();
      dri[NutrientCodes.protein] = DriReference(
        ageGroupCode: '3_5y', nutrientCode: NutrientCodes.protein,
        recommendedAmount: 31.0
      );
      final intake = NutrientCalculator.calcIntake([
        FoodIntakeEntry(food: _makeChicken(), intakeAmountG: 100)
      ]);
      final result = NutrientCalculator.calcAchievement(
        intake: intake, driMap: dri, ageMonths: 48
      );
      expect(result[NutrientCodes.protein], closeTo(100.0, 0.01));
    });

    test('36개월 미만: 당류 DRI 기준으로 계산', () {
      final dri = _makeDri(sugarRni: 20.0);
      final intake = {NutrientCodes.sugar: 10.0, NutrientCodes.energy: 200.0};
      final result = NutrientCalculator.calcAchievement(
        intake: intake, driMap: dri, ageMonths: 24);
      expect(result[NutrientCodes.sugar], closeTo(50.0, 0.01));
    });

    test('36개월 이상: 당류 에너지 비율 기반 (목표 20%)', () {
      final intake = {NutrientCodes.energy: 200.0, NutrientCodes.sugar: 10.0};
      final result = NutrientCalculator.calcAchievement(
        intake: intake, driMap: _makeDri(), ageMonths: 48);
      expect(result[NutrientCodes.sugar], closeTo(100.0, 0.01));
    });

    test('DRI null인 영양소는 achievement에서 제외', () {
      final intake = {NutrientCodes.energy: 100.0};
      final result = NutrientCalculator.calcAchievement(
        intake: intake, driMap: _makeDri(), ageMonths: 48);
      expect(result.containsKey(NutrientCodes.vitaminD), isFalse);
    });

    test('달성률 999.9 초과하지 않음', () {
      final dri = {
        NutrientCodes.energy: DriReference(
          ageGroupCode: '3_5y', nutrientCode: NutrientCodes.energy,
          recommendedAmount: 1.0
        )
      };
      final intake = {NutrientCodes.energy: 10000.0};
      final result = NutrientCalculator.calcAchievement(
        intake: intake, driMap: dri, ageMonths: 48);
      expect(result[NutrientCodes.energy], closeTo(999.9, 0.01));
    });
  });
  
  group('calcGuestAchievement', () {
    test('4가지 영양소만 반환 (energy, carbs, protein, fat)', () {
      final result = NutrientCalculator.calcGuestAchievement(
        entries: [FoodIntakeEntry(food: _apple, intakeAmountG: 100)],
        driMap: _makeDri()
      );
      expect(result.keys.toSet(), equals({
        NutrientCodes.energy, NutrientCodes.carbs,
        NutrientCodes.protein, NutrientCodes.fat
      }));
    });
    
    test('sugar, sodium 등은 포함되지 않음', () {
      final result = NutrientCalculator.calcGuestAchievement(
        entries: [FoodIntakeEntry(food: _apple, intakeAmountG: 100)],
        driMap: _makeDri()
      );
      expect(result.containsKey(NutrientCodes.sugar), isFalse);
      expect(result.containsKey(NutrientCodes.sodium), isFalse);
    });
  });
  
  group('statusFromRate - 경계값', () {
    test('49.9% -> deficient', () => expect(
      NutrientCalculator.statusFromRate(49.9), NutrientStatus.deficient));
    test('50.0% -> slightlyLow', () => expect(
        NutrientCalculator.statusFromRate(50.0), NutrientStatus.slightlyLow));
    test('69.9% -> slightlyLow', () => expect(
        NutrientCalculator.statusFromRate(69.9), NutrientStatus.slightlyLow));
    test('70.0% -> adequate', () => expect(
        NutrientCalculator.statusFromRate(70.0), NutrientStatus.adequate));
    test('120.0% -> adequate', () => expect(
        NutrientCalculator.statusFromRate(120.0), NutrientStatus.adequate));
    test('120.1% -> slightlyHigh', () => expect(
        NutrientCalculator.statusFromRate(120.1), NutrientStatus.slightlyHigh));
    test('150.0% -> slightlyHigh', () => expect(
        NutrientCalculator.statusFromRate(150.0), NutrientStatus.slightlyHigh));
    test('150.1% -> excess', () => expect(
        NutrientCalculator.statusFromRate(150.1), NutrientStatus.excess));
  });

  group('buildStatusSummary', () {
    test('achievement 맵 -> 상태 이름 문자열 맵 변환', () {
      final result = NutrientCalculator.buildStatusSummary({
        NutrientCodes.energy: 110.0,
        NutrientCodes.protein: 40.0,
        NutrientCodes.fat: 130.0
      });
      expect(result[NutrientCodes.energy], 'adequate');
      expect(result[NutrientCodes.protein], 'deficient');
      expect(result[NutrientCodes.fat], 'slightlyHigh');
    });
  });
}