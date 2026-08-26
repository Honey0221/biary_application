import 'package:hive/hive.dart';

part 'guest_session.g.dart';

@HiveType(typeId: 0)
class GuestSession extends HiveObject {
  @HiveField(0)
  String? lastAnalysisJson; // 마지막 게스트 분석

  @HiveField(1)
  DateTime? analyzedAt; // 분석 시각
}