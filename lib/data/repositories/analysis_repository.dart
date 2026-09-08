import 'package:honey/data/models/analysis_result.dart';
import 'package:honey/data/models/dri_reference.dart';

abstract interface class AnalysisRepository {
  // 기존 분석 결과 조회
  Future<AnalysisResult?> getAnalysis(String mealRecordId);

  // 분석 결과 저장
  Future<AnalysisResult> saveAnalysis(AnalysisResult result);

  // 연령 및 성별 기준 DRI 전체 조회(DriMap 반환)
  Future<DriMap> fetchDri(int ageMonths, String gender);
}