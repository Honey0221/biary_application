import 'package:honey/core/utils/nutrient_calculator.dart';
import 'package:honey/data/models/meal_item.dart';
import 'package:honey/main.dart';

class AnalysisResponse {
  final Map<String, double> nutrients;
  final Map<String, double> achievement;
  final String aiComment;
  final String? todayComment;
  final String? trendComment;
  final List<String> aiEstimatedFoods;
  final List<Map<String, dynamic>> suggestions;

  const AnalysisResponse({
    required this.nutrients,
    required this.achievement,
    required this.aiComment,
    this.todayComment,
    this.trendComment,
    this.aiEstimatedFoods = const [],
    this.suggestions = const []
  });

  factory AnalysisResponse.fromJson(Map<String, dynamic> json) {
    return AnalysisResponse(
      nutrients: (json['nutrients'] as Map<String, dynamic>? ?? {})
        .map((k, v) => MapEntry(k, (v as num).toDouble())),
      achievement: (json['achievement'] as Map<String, dynamic>? ?? {})
        .map((k, v) => MapEntry(k, (v as num).toDouble())),
      aiComment: json['aiComment'] as String? ?? '',
      todayComment: json['todayComment'] as String?,
      trendComment: json['trendComment'] as String?,
      aiEstimatedFoods: (json['aiEstimatedFoods'] as List<dynamic>?)?.cast<String>() ?? [],
      suggestions: (json['suggestions'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? []
    );
  }
}

// 분석 진행 상태 콜백
typedef ProgressCallback = void Function(double progress, String message);

class AnalysisService {
  AnalysisService._();

  // 회원별 영양 분석 실행
  // - [entries]: S-06 경로 (FoodSearchResult 선택된 음식 → preComputedIntake)
  // - [items]:   S-07 경로 (DB 저장된 MealItem 음식명 → directInputFoods)
  static Future<AnalysisResponse> analyze({
    required bool isSubscriber,
    List<FoodIntakeEntry>? entries,
    List<MealItem>? items,
    required String childId,
    required int childAgeMonths,
    required String childGender,
    ProgressCallback? onProgress
  }) async {
    // STEP 1. 섭취량 계산
    onProgress?.call(0.15, '식단 정보 확인 중...');

    final Map<String, double> preComputedIntake ; // API 선택 음식
    final List<Map<String, dynamic>> directInputFoods; // 직접 입력 음식

    if (entries != null && entries.isNotEmpty) {
      // 선택된 음식의 영양소를 미리 게산
      preComputedIntake = NutrientCalculator.calcIntake(entries);
      directInputFoods = [];
    } else {
      // 음식명만 전달, Edge Function이 식품처 API로 조회
      preComputedIntake = {};
      directInputFoods = (items ?? [])
        .where((i) => i.customFoodName.isNotEmpty)
        .map((i) => {
          'name': i.customFoodName,
          'intakeAmountG': i.intakeAmountG ?? 100.0
        })
        .toList();
    }

    // STEP 2. DRI 데이터 조회
    onProgress?.call(0.40, '영양소 기준 데이터 검색 중...');
    await Future.delayed(const Duration(milliseconds: 100));

    // STEP 3. Edge Function 호출
    onProgress?.call(0.55, 'AI 식단 분석 중...');
    final functionName = isSubscriber ? 'analyze-full' : 'analyze-basic';
    final response = await supabase.functions.invoke(
      functionName,
      body: {
        'preComputedIntake': preComputedIntake,
        'directInputFoods': directInputFoods,
        'childId': childId,
        'childAgeMonths': childAgeMonths,
        'childGender': childGender
      }
    );

    if (response.status != 200) {
      throw Exception('분석 요청 실패 (${response.status}): ${response.data}');
    }

    // STEP 4. 결과 파싱
    onProgress?.call(0.95, '결과 내용 정리 중...');
    return AnalysisResponse.fromJson(response.data as Map<String, dynamic>);
  }
}