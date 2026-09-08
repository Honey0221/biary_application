import 'package:honey/data/models/meal_record.dart';

abstract interface class MealRecordRepository {
  // 식사 기록 조회
  Future<List<MealRecord>> getRecords({
    required String childId,
    DateTime? from,
    DateTime? to
  });

  // 식사 기록 상세 조회
  Future<MealRecord> getRecord(String id);

  // 식사 기록 생성
  Future<MealRecord> createRecord({
    required MealRecord record,
    required List<String> localPhotoPaths
  });

  // 식사 기록 수정
  Future<MealRecord> updateRecord({
    required MealRecord record,
    required List<String> localPhotosPaths
  });

  // 식사 기록 삭제
  Future<void> deleteRecord(String id);

  // 식사 기록 사진 삭제
  Future<void> deletePhoto(String photoId);
}