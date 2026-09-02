import 'package:honey/data/models/child_profile.dart';
import 'package:honey/data/repositories/child_profile_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseChildProfileRepository implements ChildProfileRepository {
  const SupabaseChildProfileRepository(this._client);
  final SupabaseClient _client;

  static const int maxFreeProfiles = 10; // 미구독 프로필 최대 개수

  @override
  Future<List<ChildProfile>> getProfiles(String userId) async {
    final res = await _client
      .from('child_profiles')
      .select()
      .eq('user_id', userId)
      .order('created_at');
    return (res as List).map((e) => ChildProfile.fromJson(e)).toList();
  }

  @override
  Future<ChildProfile> createProfile(ChildProfile profile) async {
    final count = await getProfileCount(profile.userId);
    if (count >= maxFreeProfiles) {
      throw Exception('미구독 회원은 최대 $maxFreeProfiles명까지 등록 가능합니다.');
    }
    final res = await _client
      .from('child_profiles')
      .insert(profile.toJson())
      .select()
      .single();
    return ChildProfile.fromJson(res);
  }

  @override
  Future<ChildProfile> updateProfile(ChildProfile profile) async {
    final res = await _client
      .from('child_profiles')
      .update(profile.toJson())
      .eq('id', profile.id)
      .select()
      .single();
    return ChildProfile.fromJson(res);
  }

  @override
  Future<void> deleteProfile(String profileId) async {
    await _client.from('child_profiles').delete().eq('id', profileId);
  }

  @override
  Future<int> getProfileCount(String userId) async {
    final res = await _client
      .from('child_profiles')
      .select('id')
      .eq('user_id', userId);
    return (res as List).length;
  }
}