class MealItem {
  final String? id;
  final String? foodId;
  final String customFoodName;
  final double? intakeAmountG;
  final String? reactionType;
  final String? note;

  const MealItem({
    this.id,
    this.foodId,
    required this.customFoodName,
    this.intakeAmountG,
    this.reactionType,
    this.note
  });

  factory MealItem.fromJson(Map<String, dynamic> json) => MealItem(
    id: json['id'] as String?,
    foodId: json['food_id'] as String?,
    customFoodName: json['custom_food_name'] as String? ?? '',
    intakeAmountG: (json['intake_amount_g'] as num?)?.toDouble(),
    reactionType: json['reaction_type'] as String?,
    note: json['note'] as String?
  );

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (foodId != null) 'food_id': foodId,
    'custom_food_name': customFoodName,
    if (intakeAmountG != null) 'intake_amount_g': intakeAmountG,
    if (reactionType != null) 'reaction_type': reactionType,
    if (note != null) 'note': note
  };
}