class MealRecordPhoto {
  final String id;
  final String mealRecordId;
  final String photoUrl;
  final DateTime? createdAt;

  const MealRecordPhoto({
    required this.id,
    required this.mealRecordId,
    required this.photoUrl,
    this.createdAt
  });

  factory MealRecordPhoto.fromJson(Map<String, dynamic> json) => MealRecordPhoto(
    id: json['id'] as String,
    mealRecordId: json['meal_record_id'] as String,
    photoUrl: json['photo_url'] as String,
    createdAt: json['created_at'] != null ?
      DateTime.parse(json['created_at'] as String) : null
  );

  Map<String, dynamic> toJson() => {
    'meal_record_id': mealRecordId,
    'photo_url': photoUrl
  };
}