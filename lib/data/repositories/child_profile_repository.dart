import 'package:honey/data/models/child_profile.dart';

abstract class ChildProfileRepository {
  Future<List<ChildProfile>> getProfiles(String userId);
  Future<ChildProfile> createProfile(ChildProfile profile);
  Future<ChildProfile> updateProfile(ChildProfile profile);
  Future<void> deleteProfile(String profileId);
  Future<int> getProfileCount(String userId);
}