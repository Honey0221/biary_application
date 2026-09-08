class DriReference {
  final String ageGroupCode;
  final String nutrientCode;
  final double? recommendedAmount;
  final double? upperLimitAmount;
  final String? unit;

  const DriReference({
    required this.ageGroupCode,
    required this.nutrientCode,
    this.recommendedAmount,
    this.upperLimitAmount,
    this.unit
  });

  factory DriReference.fromJson(Map<String, dynamic> json) => DriReference(
    ageGroupCode: json['age_group_code'] as String,
    nutrientCode: json['nutrient_code'] as String,
    recommendedAmount: (json['recommended_amount'] as num?)?.toDouble(),
    upperLimitAmount: (json['upper_limit_amount'] as num?)?.toDouble(),
    unit: json['unit'] as String?
  );

  static String resolveAgeGroupCode(int ageMonths, String gender) {
    if (ageMonths < 6) return '0_5m';
    if (ageMonths < 12) return '6_11m';
    if (ageMonths < 36) return '1_2y';
    if (ageMonths < 72) return '3_5y';
    return '6_8y_$gender';
  }
}

// 연령대 전체 DRI Map
typedef DriMap = Map<String, DriReference>;