import 'package:honey/data/models/analysis_result.dart';
import 'package:honey/data/models/dri_reference.dart';
import 'package:honey/data/repositories/analysis_repository.dart';

class SupabaseAnalysisRepository implements AnalysisRepository {
  @override
  Future<AnalysisResult?> getAnalysis(String mealRecordId) {
    // TODO: implement getAnalysis
    throw UnimplementedError();
  }

  @override
  Future<AnalysisResult> saveAnalysis(AnalysisResult result) {
    // TODO: implement saveAnalysis
    throw UnimplementedError();
  }

  @override
  Future<DriMap> fetchDri(int ageMonths, String gender) {
    // TODO: implement fetchDri
    throw UnimplementedError();
  }
}