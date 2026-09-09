import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honey/core/constants/nutrient_codes.dart';
import 'package:honey/core/utils/nutrient_calculator.dart';
import 'package:honey/data/models/child_profile.dart';
import 'package:honey/data/models/food_search_result.dart';
import 'package:honey/data/models/meal_item.dart';
import 'package:honey/data/models/meal_record.dart';
import 'package:honey/data/repositories/impl/supabase_child_profile_repository.dart';
import 'package:honey/data/repositories/impl/supabase_meal_record_repository.dart';
import 'package:honey/data/services/analysis_service.dart';
import 'package:honey/data/services/food_api_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../helpers/test_supabase_setup.dart';

void main() {
  late SupabaseClient client;
  late SupabaseChildProfileRepository childRepo;
  late SupabaseMealRecordRepository mealRepo;
  late FoodApiService foodService;

  // 테스트 중 생성된 데이터 추적
  String? _userId;
  String? _childId;
  String? _recordId;
  FoodSearchResult? _chickenFood;
  FoodSearchResult? _riceFood;

  // 타임스탭프 기반 고유 테스트 계정
  final _testEmail = 'test_${DateTime.now().millisecondsSinceEpoch}@biary.dev';
  const _testPassword = 'TestPass1234!';

  // 회원가입 + 로그인
  setUpAll(() async {
    client = await setupSupabase();

    childRepo = SupabaseChildProfileRepository(client);
    mealRepo = SupabaseMealRecordRepository(client);
    foodService = FoodApiService();

    final signUpRes = await client.auth.signUp(
      email: _testEmail,
      password: _testPassword,
      data: {'display_name': '통합테스트유저'}
    );
    assert(signUpRes.user != null, '회원가입 실패');
    _userId = signUpRes.user!.id;
    print('\n[setUpAll] 회원가입 완료\n- email: $_testEmail\n- uid: $_userId');

    // 회원가입 직후 로그인
    final signInRes = await client.auth.signInWithPassword(
      email: _testEmail,
      password: _testPassword
    );
    assert(signInRes.user != null, '로그인 실패');
    print('[setUpAll] 로그인 완료\n');
  });

  // 생성된 모든 데이터 역순 정리
  tearDownAll(() async {
    print('\n[tearDownAll] 데이터 정리 시작...');

    // 1. 식단 기록 삭제
    if (_recordId != null) {
      try {
        await mealRepo.deleteRecord(_recordId!);
        print('[tearDownAll] 식단 기록 삭제: $_recordId');
      } catch (e) {
        print('[tearDownAll] 식단 기록 삭제 실패: $e');
      }
    }

    // 2. 아이 프로필 삭제
    if (_childId != null) {
      try {
        await childRepo.deleteProfile(_childId!);
        print('[tearDownAll] 아이 프로필 삭제: $_childId');
      } catch (e) {
        print('[tearDownAll] 아이 프로필 삭제 실패: $e');
      }
    }

    // 3. 테스트 계정 삭제
    if (_userId != null) {
      try {
        final adminClient = SupabaseClient(
          dotenv.env['SUPABASE_URL']!,
          dotenv.env['SUPABASE_SERVICE_ROLE_KEY']!
        );
        await adminClient.auth.admin.deleteUser(_userId!);
        print('[tearDownAll] 테스트 계정 삭제: $_userId');
      } catch (e) {
        print('[tearDownAll] 테스트 계정 삭제 실패: $e');
      }
    }

    await client.auth.signOut();
    print('[tearDownAll] 로그아웃 완료\n');
  });

  group('회원 전체 플로우', () {
    test('STEP 1a. 식품처 DB 검색 - 닭가슴살', () async {
      final results = await foodService.searchFoods('닭가슴살');
      
      expect(results, isNotEmpty, reason: '식품처 DB에서 닭가슴살이 검색되어야 합니다');
      _chickenFood = results.first;

      print('[STEP 1a] 닭가슴살 검색 완료');
      print('          foodName: ${_chickenFood!.foodName}');
      print('          energy: ${_chickenFood!.calories}kcal'
            ' / protein: ${_chickenFood!.protein}g'
            ' / fat: ${_chickenFood!.fat}g');

      expect(_chickenFood!.calories, isNotNull);
      expect(_chickenFood!.protein, isNotNull);
    });

    test('STEP 1b. 식품처 DB 검색 - 쌀밥', () async {
      final results = await foodService.searchFoods('쌀밥');

      expect(results, isNotEmpty, reason: '식품처 DB에서 쌀밥이 검색되어야 합니다');
      _riceFood = results.first;

      print('[STEP 1b] 쌀밥 검색 완료');
      print('          foodName: ${_riceFood!.foodName}');
      print('          energy: ${_riceFood!.calories}kcal'
          ' / carbs: ${_riceFood!.carbs}g'
          ' / protein: ${_riceFood!.protein}g');

      expect(_riceFood!.calories, isNotNull);
      expect(_riceFood!.carbs, isNotNull);
    });

    test('STEP 2. 아이 프로필 등록', () async {
      final userId = client.auth.currentUser!.id;
      final created = await childRepo.createProfile(ChildProfile(
        id: '',
        userId: userId,
        name: '분석테스트아이',
        birthDate: DateTime(2000, 6, 1),
        gender: 'male',
        createdAt: DateTime.now()
      ));
      _childId = created.id;

      print('STEP 2] 아이 프로필 생성 - id: $_childId');
      expect(_childId, isNotEmpty);
      expect(created.name, '분석테스트아이');
      expect(created.gender, 'male');
    });

    test('STEP 3. 식단 기록 저장 (점심)', () async {
      expect(_childId, isNotNull, reason: 'STEP 2가 먼저 완료되어야 합니다');
      expect(_chickenFood, isNotNull, reason: 'STEP 1a가 먼저 완료되어야 합니다');
      expect(_riceFood, isNotNull, reason: 'STEP 1b가 먼저 완료되어야 합니다');

      final saved = await mealRepo.createRecord(
        record: MealRecord(
          childId: _childId!,
          mealDate: DateTime.now(),
          mealType: 'lunch',
          items: [
            MealItem(customFoodName: _chickenFood!.foodName, intakeAmountG: 150),
            MealItem(customFoodName: _riceFood!.foodName, intakeAmountG: 210)
          ]
        ),
        localPhotoPaths: []
      );
      _recordId = saved.id;

      print('[STEP 3] 식단 기록 저장 - id: $_recordId');
      print('         items: ${saved.items.map((i) =>
        '${i.customFoodName}(${i.intakeAmountG}g)').toList()})');

      expect(_recordId, isNotNull);
      expect(saved.items.length, 2);
      expect(saved.mealType, 'lunch');
    });

    test('STEP 4. 저장된 식단 기록 단건 조회', () async {
      expect(_recordId, isNotNull, reason: 'STEP 3이 먼저 완료되어야 합니다');

      final record = await mealRepo.getRecord(_recordId!);

      print('[STEP 4] 기록 조회 - mealType: ${record.mealType}'
            ', items: ${record.items.length}개');

      expect(record.id, _recordId);
      expect(record.childId, _childId);
      expect(record.mealType, 'lunch');
      expect(record.items.length, 2);
      expect(
        record.items.any((i) => i.customFoodName == _chickenFood!.foodName),
        isTrue
      );
    });

    test('STEP 5. 영양 분석 - analyze-basic', () async {
      expect(_childId, isNotNull, reason: 'STEP 2가 먼저 완료되어야 합니다');
      expect(_chickenFood, isNotNull, reason: 'STEP 1a가 먼저 완료되어야 합니다');
      expect(_riceFood, isNotNull, reason: 'STEP 1b가 먼저 완료되어야 합니다');

      final entries = [
        FoodIntakeEntry(food: _chickenFood!, intakeAmountG: 150),
        FoodIntakeEntry(food: _riceFood!, intakeAmountG: 210)
      ];

      final res = await AnalysisService.analyzeBasic(
        entries: entries, childId: _childId!, childAgeMonths: 48, childGender: 'm'
      );

      print('\n[STEP 5] 영양 분석 결과');
      print('  [섭취량]');
      res.nutrients.forEach((k, v) =>
        print('    ${NutrientCodes.labelKr[k] ?? k}: ${v.toStringAsFixed(2)}'));
      print('  [DRI 달성률]');
      res.achievement.forEach((k, v) =>
        print('    ${NutrientCodes.labelKr[k] ?? k}: ${v.toStringAsFixed(1)}%'));
      print('  [AI 코멘트]');
      print('     ${res.aiComment}');

      expect(res.nutrients, isNotEmpty);
      expect(res.achievement, isNotEmpty);
      expect(res.aiComment.trim(), isNotEmpty);

      expect(res.achievement.containsKey(NutrientCodes.energy), isTrue);
      expect(res.achievement.containsKey(NutrientCodes.protein), isTrue);

      for (final v in res.achievement.values) {
        expect(v, inInclusiveRange(0.0, 999.9));
      }

      expect(res.aiComment.contains(RegExp(r'[\uAC00-\uD7A3]')), isTrue);
    }, timeout: const Timeout(Duration(minutes: 2)));
  });
}