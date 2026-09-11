import 'package:honey/data/models/analysis_result.dart';
import 'package:honey/data/models/dri_reference.dart';
import 'package:honey/data/repositories/analysis_repository.dart';
import 'package:honey/main.dart';

class SupabaseAnalysisRepository implements AnalysisRepository {
  @override
  Future<AnalysisResult?> getAnalysis(String mealRecordId) async {
    final data = await supabase
      .from('analysis_results')
      .select()
      .eq('meal_record_id', mealRecordId)
      .maybeSingle();
    return data == null ? null : AnalysisResult.fromJson(data);
  }

  @override
  Future<AnalysisResult> saveAnalysis(AnalysisResult result) async {
    final data = await supabase
        .from('analysis_results')
        .upsert(result.toJson(), onConflict: 'meal_record_id')
        .select()
        .single();
    return AnalysisResult.fromJson(data);
  }

  @override
  Future<List<AnalysisResult>> getAnalysisListByChild(
    String childId, DateTime from, DateTime to
  ) async {
    final fromStr = '${from.year}-'
      '${from.month.toString().padLeft(2, '0')}-'
      '${from.day.toString().padLeft(2, '0')}';
    final toStr = '${to.year}-'
      '${to.month.toString().padLeft(2, '0')}-'
      '${to.day.toString().padLeft(2, '0')}';

    final data = await supabase
      .from('analysis_results')
      .select()
      .eq('child_id', childId)
      .gte('target_date', fromStr)
      .lte('target_date', toStr)
      .order('target_date', ascending: false);
    return (data as List).map((e) => AnalysisResult.fromJson(e)).toList();
  }

  @override
  Future<DriMap> fetchDri(int ageMonths, String gender) async {
    final ageGroupCode = DriReference.resolveAgeGroupCode(ageMonths, gender);

    final data = await supabase
      .from('nutrient_reference_by_age')
      .select()
      .eq('age_group_code', ageGroupCode);

    final map = <String, DriReference>{};
    for (final row in data as List) {
      final dri = DriReference.fromJson(row);
      map[dri.nutrientCode] = dri;
    }
    return map;
  }
}