import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:honey/data/models/child_profile.dart';
import 'package:honey/data/repositories/child_profile_repository.dart';
import 'package:honey/data/repositories/impl/supabase_child_profile_repository.dart';
import 'package:honey/main.dart';

final childProfileRepositoryProvider = Provider<ChildProfileRepository>((ref) {
  return SupabaseChildProfileRepository(supabase);
});

// 현재 로그인 사용자의 전체 아이 프로필 목록
final childProfilesProvider = FutureProvider<List<ChildProfile>>((ref) async {
  final userId = supabase.auth.currentUser?.id;
  if (userId == null) return [];
  return ref.read(childProfileRepositoryProvider).getProfiles(userId);
});

// 현재 선택된 아이
final selectedChildProvider = StateProvider<ChildProfile?>((ref) => null);

// 현재 접속한 아이디
final currentUserIdProvider = Provider<String?>((ref) => supabase.auth.currentUser?.id);