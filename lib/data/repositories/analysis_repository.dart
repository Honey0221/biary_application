import 'package:honey/data/models/analysis_result.dart';
import 'package:honey/data/models/dri_reference.dart';

abstract interface class AnalysisRepository {
  // 분석 결과 단건 조회
  Future<AnalysisResult?> getAnalysis(String mealRecordId);

  // 분석 결과 저장
  Future<AnalysisResult> saveAnalysis(AnalysisResult result);

  // 분석 결과 목록 조회
  Future<List<AnalysisResult>> getAnalysisListByChild(
    String childId, DateTime from, DateTime to);

  // 연령 및 성별 기준 DRI 전체 조회(DriMap 반환)
  Future<DriMap> fetchDri(int ageMonths, String gender);
}