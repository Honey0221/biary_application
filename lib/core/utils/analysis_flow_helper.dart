import 'package:honey/core/utils/nutrient_calculator.dart';
import 'package:honey/data/models/analysis_result.dart';
import 'package:honey/data/repositories/analysis_repository.dart';
import 'package:honey/data/services/analysis_service.dart';

class AnalysisFlowHelper {
  AnalysisFlowHelper._();

  // 캐시 유효성 검사
  static bool needsNewAnalysis(AnalysisResult? cached, DateTime? recordUpdatedAt) {
    return cached == null ||
      (recordUpdatedAt != null && cached.createdAt != null &&
        recordUpdatedAt.isAfter(cached.createdAt!));
  }

  // AnalysisResponse -> AnalysisResult 변환 + DB 저장
  static Future<AnalysisResult> buildAndSave({
    required AnalysisResponse response,
    required String mealRecordId,
    required String childId,
    required DateTime targetDate,
    required String mealType,
    required AnalysisRepository repo
  }) async {
    final analysisResult = AnalysisResult(
      mealRecordId: mealRecordId,
      childId: childId,
      targetDate: targetDate,
      mealType: mealType,
      nutrients: response.nutrients,
      statusSummary: NutrientCalculator.buildStatusSummary(response.achievement),
      aiComment: response.aiComment.isEmpty ? null : response.aiComment,
      aiEstimatedFoods: response.aiEstimatedFoods
    );
    await repo.saveAnalysis(analysisResult);
    return analysisResult;
  }
}