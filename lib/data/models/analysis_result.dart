class AnalysisResult {
  final String? id;
  final String mealRecordId;
  final String childId;
  final DateTime targetDate;
  final String mealType;

  // 영양소별 실제 섭취량
  final Map<String, double> nutrients;

  // 영양소별 달성 상태
  final Map<String, String> statusSummary;

  final String? aiComment;

  // AI가 추정한 음식 목록 (직접 입력한 음식)
  final List<String> aiEstimatedFoods;

  final DateTime? calculatedAt;
  final DateTime? createdAt;

  const AnalysisResult({
    this.id,
    required this.mealRecordId,
    required this.childId,
    required this.targetDate,
    required this.mealType,
    required this.nutrients,
    required this.statusSummary,
    this.aiComment,
    this.aiEstimatedFoods = const [],
    this.calculatedAt,
    this.createdAt
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> json) => AnalysisResult(
    id: json['id'] as String?,
    mealRecordId: json['meal_record_id'] as String,
    childId: json['child_id'] as String,
    targetDate: DateTime.parse(json['target_date'] as String),
    mealType: json['meal_type'] as String,
    nutrients: Map<String, double>.from(
      (json['nutrients'] as Map<String, dynamic>? ?? {})
        .map((k, v) => MapEntry(k, (v as num).toDouble()))
    ),
    statusSummary: Map<String, String>.from(
      json['status_summary'] as Map<String, dynamic>? ?? {}
    ),
    aiComment: json['ai_comment'] as String?,
    aiEstimatedFoods: List<String>.from(
      json['ai_estimated_foods'] as List<dynamic>? ?? []
    ),
    calculatedAt: json['calculated_at'] != null ?
      DateTime.parse(json['calculated_at'] as String) : null,
    createdAt: json['created_at'] != null ?
      DateTime.parse(json['created_at'] as String) : null
  );

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'meal_record_id': mealRecordId,
    'child_id': childId,
    'target_date': '${targetDate.year}-'
      '${targetDate.month.toString().padLeft(2, '0')}-'
      '${targetDate.day.toString().padLeft(2, '0')}',
    'meal_type': mealType,
    'nutrients': nutrients,
    'status_summary': statusSummary,
    if (aiComment != null) 'ai_comment': aiComment,
    'ai_estimated_foods': aiEstimatedFoods
  };
}