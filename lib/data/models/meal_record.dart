import 'package:honey/data/models/meal_item.dart';
import 'package:honey/data/models/meal_record_photo.dart';

class MealRecord {
  final String? id;
  final String childId;
  final DateTime mealDate;
  final String mealType;
  final List<MealItem> items;
  final List<MealRecordPhoto> photos;
  final String? memo;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const MealRecord({
    this.id,
    required this.childId,
    required this.mealDate,
    required this.mealType,
    required this.items,
    this.photos = const [],
    this.memo,
    this.createdBy,
    this.createdAt,
    this.updatedAt
  });

  factory MealRecord.fromJson(Map<String, dynamic> json) => MealRecord(
    id: json['id'] as String?,
    childId: json['child_id'] as String,
    mealDate: DateTime.parse(json['meal_date'] as String),
    mealType: json['meal_type'] as String,
    items: (json['meal_record_items'] as List<dynamic>? ?? [])
      .map((e) => MealItem.fromJson(e as Map<String, dynamic>)).toList(),
    photos: (json['meal_record_photos'] as List<dynamic>? ?? [])
      .map((e) => MealRecordPhoto.fromJson(e as Map<String, dynamic>)).toList(),
    memo: json['memo'] as String?,
    createdBy: json['created_by'] as String?,
    createdAt: json['created_at'] != null ?
      DateTime.parse(json['created_at'] as String) : null,
    updatedAt: json['updated_at'] != null ?
      DateTime.parse(json['updated_at'] as String) : null
  );

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'child_id': childId,
    'meal_date': '${mealDate.year}-'
      '${mealDate.month.toString().padLeft(2, '0')}-'
      '${mealDate.day.toString().padLeft(2, '0')}',
    'meal_type': mealType,
    if (memo != null) 'memo': memo,
    if (createdBy != null) 'created_by': createdBy
  };
}