import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:honey/data/models/meal_item.dart';
import 'package:honey/data/models/meal_record.dart';
import 'package:honey/data/repositories/meal_record_repository.dart';
import 'package:honey/presentation/screens/meal/meal_record_detail_screen.dart';
import 'package:honey/providers/meal_record_provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mocktail/mocktail.dart';

class MockMealRecordRepository extends Mock implements MealRecordRepository {}

// 테스트 픽스처
final _testRecord = MealRecord(
  id: 'record-1',
  childId: 'child-1',
  mealDate: DateTime.now(),
  mealType: 'lunch',
  items: [
    MealItem(customFoodName: '밥', intakeAmountG: 200, reactionType: 'good'),
    MealItem(customFoodName: '된장국', intakeAmountG: 150)
  ],
  memo: '잘 먹었어요'
);

final _recordNoMemo = MealRecord(
  id: 'record-2',
  childId: 'child-1',
  mealDate: DateTime.now(),
  mealType: 'breakfast',
  items: [MealItem(customFoodName: '시리얼')]
);

void main() {
  late MockMealRecordRepository mockRepo;

  setUp(() {
    mockRepo = MockMealRecordRepository();
  });

  Widget buildApp({
    String recordId = 'record-1',
    MealRecord? recordData,
    bool loading = false,
    bool hasError = false
  }) {
    final router = GoRouter(
      initialLocation: '/record/$recordId',
      routes: [
        GoRoute(
          path: '/record/:id',
          builder: (_, state) => MealRecordDetailScreen(
            recordId: state.pathParameters['id']!
          )
        ),
        GoRoute(
          path: '/record/:id/edit',
          builder: (_, _) => const Text('edit-screen')
        )
      ]
    );

    return ProviderScope(
      overrides: [
        mealRecordRepositoryProvider.overrideWithValue(mockRepo),
        mealRecordProvider(recordId).overrideWith((ref) async {
          if (hasError) throw Exception('로드 실패');
          if (loading) return Completer<MealRecord>().future;
          return recordData ?? _testRecord;
        })
      ],
      child: MaterialApp.router(routerConfig: router)
    );
  }

  group('기본 렌더링', () {
    testWidgets('날짜, 식사구분, 음식 목록이 표시된다', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('2026.09.03'), findsOneWidget);
      expect(find.text('점심'), findsOneWidget);
      expect(find.text('밥'), findsOneWidget);
      expect(find.text('된장국'), findsOneWidget);
    });

    testWidgets('섭취량이 표시된다', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('200g'), findsOneWidget);
    });

    testWidgets('메모가 있으면 표시된다', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('메모'), findsOneWidget);
      expect(find.text('잘 먹었어요'), findsOneWidget);
    });

    testWidgets('메모가 없으면 메모 섹션이 표시되지 않는다', (tester) async {
      await tester.pumpWidget(buildApp(recordId: 'record-2', recordData: _recordNoMemo));
      await tester.pumpAndSettle();

      expect(find.text('메모'), findsNothing);
    });

    testWidgets('로딩 중에는 이것이 표시된다', (tester) async {
      await tester.pumpWidget(buildApp(loading: true));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('에러 시 에러 메시지가 표시된다', (tester) async {
      await tester.pumpWidget(buildApp(hasError: true));
      await tester.pumpAndSettle();

      expect(find.textContaining('불러오기 실패'), findsOneWidget);
    });
  });

  group('수정 버튼', () {
    testWidgets('수정 버튼 탭 -> 수정 화면으로 이동한다', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(LucideIcons.pencil));
      await tester.pumpAndSettle();

      expect(find.text('edit-screen'), findsOneWidget);
    });
  });

  group('삭제 버튼', () {
    testWidgets('삭제 버튼 탭 -> 확인 다이얼로그 표시', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(LucideIcons.trash2));
      await tester.pumpAndSettle();

      expect(find.text('기록 삭제'), findsOneWidget);
      expect(find.text('삭제'), findsOneWidget);
      expect(find.text('취소'), findsOneWidget);
    });

    testWidgets('삭제 확인 -> deleteRecord가 호출된다', (tester) async {
      when(() => mockRepo.deleteRecord(any()))
        .thenAnswer((_) async {});

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(LucideIcons.trash2));
      await tester.pumpAndSettle();

      await tester.tap(find.text('삭제').last);
      await tester.pumpAndSettle();

      verify(() => mockRepo.deleteRecord('record-1')).called(1);
    });

    testWidgets('삭제 취소 -> deleteRecord가 호출 안된다', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(LucideIcons.trash2));
      await tester.pumpAndSettle();

      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();

      verifyNever(() => mockRepo.deleteRecord(any()));
    });
  });
}