import 'dart:io';

import 'package:honey/data/models/meal_record.dart';
import 'package:honey/data/repositories/meal_record_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class SupabaseMealRecordRepository implements MealRecordRepository {
  const SupabaseMealRecordRepository(this._client);
  final SupabaseClient _client;

  @override
  Future<List<MealRecord>> getRecords({
    required String childId,
    DateTime? from, DateTime? to
  }) async {
    var query = _client
      .from('meal_records')
      .select('*, meal_record_items(*), meal_record_photos(*)')
      .eq('child_id', childId);

    if (from != null) {
      query = query.gte('meal_date',
        '${from.year}-${from.month.toString().padLeft(2,'0')}'
          '-${from.day.toString().padLeft(2,'0')}');
    }
    if (to != null) {
      query = query.lte('meal_date',
        '${to.year}-${to.month.toString().padLeft(2,'0')}'
          '-${to.day.toString().padLeft(2,'0')}');
    }

    final data = await query.order('meal_date', ascending: false);
    return data.map((e) => MealRecord.fromJson(e)).toList();
  }

  @override
  Future<MealRecord> getRecord(String id) async {
    final data = await _client
      .from('meal_records')
      .select('*, meal_record_items(*), meal_record_photos(*)')
      .eq('id', id)
      .single();
    return MealRecord.fromJson(data);
  }

  @override
  Future<MealRecord> createRecord({
    required MealRecord record,
    required List<String> localPhotoPaths
  }) async {
    // 1. meal_records 삽입
    final inserted = await _client
      .from('meal_records')
      .insert({
        ...record.toJson(),
        'created_by': _client.auth.currentUser!.id
      })
      .select()
      .single();
    final recordId = inserted['id'] as String;
    // 2. meal_record_items 삽입
    if (record.items.isNotEmpty) {
      await _client.from('meal_record_items').insert(
        record.items.map((item) => {
          ...item.toJson(),
          'meal_record_id': recordId
        }).toList()
      );
    }
    // 3. 사진 업로드
    final photoUrls = await _uploadPhotos(recordId, localPhotoPaths);
    if (photoUrls.isNotEmpty) {
      await _client.from('meal_record_photos').insert(
        photoUrls.map((url) => {
          'meal_record_id': recordId,
          'photo_url': url
        }).toList()
      );
    }

    return getRecord(recordId);
  }

  @override
  Future<MealRecord> updateRecord({
    required MealRecord record,
    required List<String> localPhotosPaths
  }) async {
    await _client
      .from('meal_records')
      .update(record.toJson())
      .eq('id', record.id!);

    // 기존 items 삭제 후 재삽입
    await _client
      .from('meal_record_items')
      .delete()
      .eq('meal_record_id', record.id!);

    if (record.items.isNotEmpty) {
      await _client.from('meal_record_items').insert(
        record.items.map((item) => {
          ...item.toJson(),
          'meal_record_id': record.id
        }).toList()
      );
    }

    // 신규 사진 추가 업로드(기존 사진은 개별 삭제)
    if (localPhotosPaths.isNotEmpty) {
      final photoUrls = await _uploadPhotos(record.id!, localPhotosPaths);
      await _client.from('meal_record_photos').insert(
        photoUrls.map((url) => {
          'meal_record_id': record.id,
          'photo_url': url
        }).toList()
      );
    }

    return getRecord(record.id!);
  }

  @override
  Future<void> deleteRecord(String id) async {
    await _client.from('meal_records').delete().eq('id', id);
  }

  @override
  Future<void> deletePhoto(String photoId) async {
    await _client
      .from('meal_record_photos')
      .delete()
      .eq('id', photoId);
    // TODO: Storage에서도 파일 삭제 필요 (photo_url 파싱 후 storage.remove())
  }

  // Storage 사진 업로드 헬퍼 함수
  Future<List<String>> _uploadPhotos(
    String recordId, List<String> localPaths
  ) async {
    final urls = <String>[];
    for (final path in localPaths) {
      final file = File(path);
      final ext = path.split('.').last;
      final fileName = '${const Uuid().v4()}.$ext';
      final storagePath = 'meal-photos/$recordId/$fileName';

      await _client.storage.from('meal-photos').upload(storagePath, file);
      final url = await _client.storage
        .from('meal-photos')
        .createSignedUrl(storagePath, 3600);
      urls.add(url);
    }
    return urls;
  }
}