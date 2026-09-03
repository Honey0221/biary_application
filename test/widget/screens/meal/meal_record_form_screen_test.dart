import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:honey/core/constants/nutrient_codes.dart';
import 'package:honey/data/models/child_profile.dart';
import 'package:honey/data/models/food_search_result.dart';
import 'package:honey/data/models/meal_item.dart';
import 'package:honey/data/models/meal_record.dart';
import 'package:honey/data/repositories/food_api_repository.dart';
import 'package:honey/data/repositories/meal_record_repository.dart';
import 'package:honey/presentation/screens/meal/meal_record_form_screen.dart';
import 'package:honey/providers/child_profile_provider.dart';
import 'package:honey/providers/food_search_provider.dart';
import 'package:honey/providers/meal_record_provider.dart';
import 'package:mocktail/mocktail.dart';

class MockMealRecordRepository extends Mock implements MealRecordRepository {}
class MockFoodApiRepository extends Mock implements FoodApiRepository {}

// 테스트 픽스처
final _testChild = ChildProfile(
  id: 'child-1',
  userId: 'user-1',
  name: '지우',
  birthDate: DateTime(2023, 5, 15),
  gender: 'female',
  createdAt: DateTime.now()
);

final _testRecord = MealRecord(
  id: 'record-1',
  childId: 'child-1',
  mealDate: DateTime(2026, 9, 3),
  mealType: 'lunch',
  items: [
    MealItem(customFoodName: '밥', intakeAmountG: 200, reactionType: 'good'),
    MealItem(customFoodName: '된장국', intakeAmountG: 150)
  ],
  memo: '잘 먹었어요'
);

final _testFoodResult = FoodSearchResult(
  foodCode: 'FOOD001',
  foodName: '흰쌀밥',
  makerName: '테스트푸드',
  servingSize: 210,
  nutrients: {
    NutrientCodes.energy: 313.0,
    NutrientCodes.carbs: 68.1,
    NutrientCodes.protein: 5.5,
    NutrientCodes.fat: 0.5
  }
);

void main() {
  late MockMealRecordRepository mockRepo;

  setUp(() {
    mockRepo = MockMealRecordRepository();
    registerFallbackValue(
      MealRecord(
        childId: 'child-1',
        mealDate: DateTime(2026, 1, 1),
        mealType: 'breakfast',
        items: []
      )
    );
  });

  Widget buildApp({
    MealRecord? initialRecord,
    bool withChild = true,
    MockFoodApiRepository? mockFoodRepo
  }) {
    final router = GoRouter(
      initialLocation: '/record/new',
      routes: [
        GoRoute(
          path: '/record/new',
          builder: (_, _) => MealRecordFormScreen(initialRecord: initialRecord)
        ),
        GoRoute(
          path: '/home',
          builder: (_, _) => const Text('home')
        )
      ]
    );

    return ProviderScope(
      overrides: [
        mealRecordRepositoryProvider.overrideWithValue(mockRepo),
        selectedChildProvider.overrideWith((ref) => withChild ? _testChild : null),
        currentUserIdProvider.overrideWith((ref) => 'user-1'),
        if (mockFoodRepo != null)
          foodApiRepositoryProvider.overrideWithValue(mockFoodRepo)
      ],
      child: MaterialApp.router(routerConfig: router)
    );
  }

  group('작성 모드', () {
    testWidgets('주요 UI 요소가 렌더링된다', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('식단 기록 작성'), findsOneWidget);
      expect(find.text('아이 선택'), findsOneWidget);
      expect(find.text('날짜'), findsOneWidget);
      expect(find.text('식사 구분'), findsOneWidget);
      expect(find.text('음식 목록'), findsOneWidget);
      expect(find.text('음식 추가'), findsOneWidget);
      expect(find.text('저장'), findsOneWidget);
    });

    testWidgets('선택된 아이 이름이 표시된다', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('지우'), findsOneWidget);
    });

    testWidgets('아이 미선택 시 저장 -> 스낵바 표시', (tester) async {
      await tester.pumpWidget(buildApp(withChild: false));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('저장'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('저장'));
      await tester.pumpAndSettle();

      expect(find.text('아이를 선택해주세요'), findsNWidgets(2));
      verifyNever(() => mockRepo.createRecord(
        record: any(named: 'record'),
        localPhotoPaths: any(named: 'localPhotoPaths'))
      );
    });

    testWidgets('음식 미입력 시 저장 -> 에러 텍스트 표시', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('저장'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('저장'));
      await tester.pump();

      expect(find.text('음식을 최소 1개 입력해주세요'), findsOneWidget);
    });

    testWidgets('음식 추가 버튼 탭 -> 새 입력 필드 추가', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('음식명 검색 또는 직접 입력'), findsOneWidget);

      await tester.tap(find.text('음식 추가'));
      await tester.pump();

      expect(find.text('음식명 검색 또는 직접 입력'), findsNWidgets(2));
    });

    testWidgets('음식 2개 이상 시 삭제 버튼이 표시된다', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.byTooltip('삭제'), findsNothing);

      await tester.tap(find.text('음식 추가'));
      await tester.pump();

      expect(find.byType(GestureDetector), findsAtLeastNWidgets(2));
    });

    testWidgets('닫기 버튼 - 내용 있으면 확인 다이얼로그 표시', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, '밥');
      await tester.pump();

      await tester.tap(find.byType(IconButton).first);
      await tester.pumpAndSettle();

      expect(find.text('작성 중인 내용이 있어요'), findsOneWidget);
    });

    testWidgets('저장 성공 -> createRecord 호출된다', (tester) async {
      when(() => mockRepo.createRecord(
        record: any(named: 'record'),
        localPhotoPaths: any(named: 'localPhotoPaths')
      )).thenAnswer((_) async => _testRecord);

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, '밥');
      await tester.pump();

      await tester.ensureVisible(find.text('저장'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('저장'));
      await tester.pump();

      verify(() => mockRepo.createRecord(
        record: any(named: 'record'),
        localPhotoPaths: any(named: 'localPhotoPaths')
      )).called(1);
    });

    testWidgets('저장 실패 -> 에러 스낵바 표시', (tester) async {
      when(() => mockRepo.createRecord(
          record: any(named: 'record'),
          localPhotoPaths: any(named: 'localPhotoPaths')
      )).thenThrow(Exception('서버 오류'));

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, '밥');
      await tester.pump();

      await tester.ensureVisible(find.text('저장'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('저장'));
      await tester.pump();

      expect(find.textContaining('저장 중 오류가 발생했습니다'), findsOneWidget);
    });
  });

  group('수정 모드', () {
    testWidgets('기존 데이터가 pre-fill 된다', (tester) async {
      await tester.pumpWidget(buildApp(initialRecord: _testRecord));
      await tester.pumpAndSettle();

      expect(find.text('식단 기록 수정'), findsOneWidget);
      expect(find.text('밥'), findsOneWidget);
      expect(find.text('된장국'), findsOneWidget);
      expect(find.text('잘 먹었어요'), findsOneWidget);
    });

    testWidgets('수정 완료 버튼이 표시된다', (tester) async {
      await tester.pumpWidget(buildApp(initialRecord: _testRecord));
      await tester.pumpAndSettle();

      expect(find.text('수정'), findsOneWidget);
    });
  });

  group('음식 검색 자동완성', () {
    late MockFoodApiRepository mockFoodRepo;

    setUp(() {
      mockFoodRepo = MockFoodApiRepository();
    });

    testWidgets('1글자 입력 시 searchFoods가 호출되지 않는다', (tester) async {
      await tester.pumpWidget(buildApp(mockFoodRepo: mockFoodRepo));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, '밥');
      await tester.pumpAndSettle();

      verifyNever(() => mockFoodRepo.searchFoods(any()));
    });

    testWidgets('2글자 입력 시 API가 호출되고 드롭다운에 결과가 표시된다', (tester) async {
      when(() => mockFoodRepo.searchFoods(any()))
        .thenAnswer((_) async => [_testFoodResult]);

      await tester.pumpWidget(buildApp(mockFoodRepo: mockFoodRepo));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, '흰쌀');
      await tester.pumpAndSettle();

      verify(() => mockFoodRepo.searchFoods('흰쌀')).called(1);
      expect(find.text('흰쌀밥'), findsOneWidget);
      expect(find.text('313 kcal'), findsOneWidget);
    });

    testWidgets('드롭다운 항목 선택 시 TextField에 음식명이 반영된다', (tester) async {
      when(() => mockFoodRepo.searchFoods(any()))
        .thenAnswer((_) async => [_testFoodResult]);

      await tester.pumpWidget(buildApp(mockFoodRepo: mockFoodRepo));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, '흰쌀');
      await tester.pumpAndSettle();

      await tester.tap(find.text('흰쌀밥'));
      await tester.pumpAndSettle();

      expect(find.text('흰쌀밥'), findsOneWidget);
    });

    testWidgets('API 오류 시 드롭다운이 표시되지 않는다', (tester) async {
      when(() => mockFoodRepo.searchFoods(any()))
        .thenThrow(Exception('API 오류'));

      await tester.pumpWidget(buildApp(mockFoodRepo: mockFoodRepo));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, '흰쌀');
      await tester.pumpAndSettle();

      expect(find.text('흰쌀밥'), findsNothing);
    });

    testWidgets('직접 입력(드롭다운 미선택)으로도 저장이 가능하다', (tester) async {
      when(() => mockFoodRepo.searchFoods(any()))
        .thenAnswer((_) async => []);
      when(() => mockRepo.createRecord(
        record: any(named: 'record'),
        localPhotoPaths: any(named: 'localPhotoPaths')
      )).thenAnswer((_) async => _testRecord);

      await tester.pumpWidget(buildApp(mockFoodRepo: mockFoodRepo));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, '직접입력음식');
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('저장'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('저장'));
      await tester.pump();

      verify(() => mockRepo.createRecord(
        record: any(named: 'record'),
        localPhotoPaths: any(named: 'localPhotoPaths')
      )).called(1);
    });
  });
}