import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:honey/data/models/analysis_result.dart';
import 'package:honey/data/repositories/analysis_repository.dart';
import 'package:honey/data/repositories/impl/supabase_analysis_repository.dart';

final analysisRepositoryProvider = Provider<AnalysisRepository>((ref) {
  return SupabaseAnalysisRepository();
});

// 기존 분석 결과 조회 (meal_record_id 기준)
final analysisProvider = FutureProvider.autoDispose
  .family<AnalysisResult?, String>((ref, mealRecordId) async {
    final repo = ref.watch(analysisRepositoryProvider);
    return repo.getAnalysis(mealRecordId);
  }
);

// TODO: 특정 아이의 날짜 범위 내 분석 목록
// final analysisListProvider = FutureProvider.autoDispose
//   .family<List<AnalysisResult>, AnalysisListParam>((ref, param) async {
//     final repo = ref.watch(analysisRepositoryProvider);
//     return repo.getAnalysisListByChild(
//       childId: param.childId,
//       from: param.from,
//       to: param.to
//     );
//   }
// );

// 분석 목록 쿼리 파라미터
class AnalysisListParam {
  final String childId;
  final DateTime from;
  final DateTime to;

  const AnalysisListParam({
    required this.childId,
    required this.from,
    required this.to
  });

  // 분석 목록 쿼리 파라미터 비교
  @override
  bool operator ==(Object other) =>
    other is AnalysisListParam &&
    other.childId == childId &&
    other.from == from &&
    other.to == to;

  // 분석 목록 쿼리 파라미터 해시 코드
  @override
  int get hashCode => Object.hash(childId, from, to);
}