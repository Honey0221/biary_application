import 'package:honey/data/models/meal_record.dart';

abstract interface class MealRecordRepository {
  Future<List<MealRecord>> getRecords({
    required String childId,
    DateTime? from,
    DateTime? to
  });
  Future<MealRecord> getRecord(String id);
  Future<MealRecord> createRecord({
    required MealRecord record,
    required List<String> localPhotoPaths
  });
  Future<MealRecord> updateRecord({
    required MealRecord record,
    required List<String> localPhotosPaths
  });
  Future<void> deleteRecord(String id);
  Future<void> deletePhoto(String photoId);
}