import 'package:honey/data/models/child_profile.dart';

abstract class ChildProfileRepository {
  // 아이 프로필 조회
  Future<List<ChildProfile>> getProfiles(String userId);

  // 아이 프로필 생성
  Future<ChildProfile> createProfile(ChildProfile profile);

  // 아이 프로필 수정
  Future<ChildProfile> updateProfile(ChildProfile profile);

  // 아이 프로필 삭제
  Future<void> deleteProfile(String profileId);

  // 회원별 아이 프로필 개수 조회
  Future<int> getProfileCount(String userId);
}