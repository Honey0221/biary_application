import 'package:honey/core/constants/nutrient_codes.dart';

class FoodSearchResult {
  final String foodCode;      // FOOD_CD
  final String foodName;      // FOOD_NM_KR
  final String? makerName;    // MAKER_NM
  final double? servingSize;  // SERVING_SIZE (g) - null이면 100g 기준

  // NutrientCodes에 정의된 13개 영양소만 파싱
  final Map<String, double?> nutrients;

  const FoodSearchResult({
    required this.foodCode,
    required this.foodName,
    this.makerName,
    this.servingSize,
    required this.nutrients
  });

  // 편의 getter (NutrientCodes 기준)
  double? get calories  => nutrients[NutrientCodes.energy];
  double? get carbs     => nutrients[NutrientCodes.carbs];
  double? get protein   => nutrients[NutrientCodes.protein];
  double? get fat       => nutrients[NutrientCodes.fat];
  double? get sugar     => nutrients[NutrientCodes.sugar];
  double? get fiber     => nutrients[NutrientCodes.fiber];
  double? get sodium    => nutrients[NutrientCodes.sodium];
  double? get calcium   => nutrients[NutrientCodes.calcium];
  double? get iron      => nutrients[NutrientCodes.iron];
  double? get zinc      => nutrients[NutrientCodes.zinc];
  double? get vitaminA  => nutrients[NutrientCodes.vitaminA];
  double? get vitaminC  => nutrients[NutrientCodes.vitaminC];
  double? get vitaminD  => nutrients[NutrientCodes.vitaminD];

  // 식품처 DB -> NutrientCodes 매핑 테이블
  static const Map<String, String> _amtNumToCode = {
    'AMT_NUM1': NutrientCodes.energy,
    'AMT_NUM3': NutrientCodes.protein,
    'AMT_NUM4': NutrientCodes.fat,
    'AMT_NUM6': NutrientCodes.carbs,
    'AMT_NUM7': NutrientCodes.sugar,
    'AMT_NUM8': NutrientCodes.fiber,
    'AMT_NUM9': NutrientCodes.calcium,
    'AMT_NUM10': NutrientCodes.iron,
    'AMT_NUM13': NutrientCodes.sodium,
    'AMT_NUM14': NutrientCodes.vitaminA,
    'AMT_NUM21': NutrientCodes.vitaminC,
    'AMT_NUM22': NutrientCodes.vitaminD,
    'AMT_NUM116': NutrientCodes.zinc,
  };

  factory FoodSearchResult.fromJson(Map<String, dynamic> json) {
    final nutrients = <String, double?>{};

    _amtNumToCode.forEach((amtKey, nutrientCode) {
      nutrients[nutrientCode] = double.tryParse(
        json[amtKey]?.toString() ?? ''
      );
    });

    return FoodSearchResult(
      foodCode:     json['FOOD_CD'] as String,
      foodName:     json['FOOD_NM_KR'] as String,
      makerName:    json['MAKER_NM'] as String?,
      servingSize:  double.tryParse(json['SERVING_SIZE']?.toString() ?? ''),
      nutrients:    nutrients
    );
  }
}