import 'package:hive/hive.dart';

part 'local_child_profile.g.dart';

@HiveType(typeId: 1)
class LocalChildProfile extends HiveObject {
  @HiveField(0)
  late String id; // 로컬 UUID

  @HiveField(1)
  late String name;

  @HiveField(2)
  late String birthDate;

  @HiveField(3)
  late String gender;

  @HiveField(4)
  String? allergyNotes;
}