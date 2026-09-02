import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:honey/data/models/child_profile.dart';
import 'package:honey/data/repositories/child_profile_repository.dart';
import 'package:honey/presentation/screens/child/child_form_screen.dart';
import 'package:honey/providers/child_profile_provider.dart';
import 'package:mocktail/mocktail.dart';

class MockChildProfileRepository extends Mock implements ChildProfileRepository {}

// 테스트용 아이 프로필
final _testProfile = ChildProfile(
  id: 'child-1',
  userId: 'test-user-id',
  name: '지우',
  birthDate: DateTime(2023, 5, 10),
  gender: 'male',
  allergyNotes: '땅콩',
  createdAt: DateTime(2024, 1, 1)
);

GoRouter _buildRouter({ChildProfile? initialProfile}) => GoRouter(routes: [
  GoRoute(
    path: '/',
    builder: (_, _) => ChildFormScreen(initialProfile: initialProfile)
  ),
  GoRoute(path: '/home', builder: (_, _) => const Scaffold(body: Text('home')))
]);

Widget _buildApp(MockChildProfileRepository mockRepo, {
  ChildProfile? initialProfile
}) {
  return ProviderScope(
    overrides: [
      childProfileRepositoryProvider.overrideWithValue(mockRepo),
      currentUserIdProvider.overrideWithValue('test-user-id')
    ],
    child: MaterialApp.router(
      routerConfig: _buildRouter(initialProfile: initialProfile)
    )
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(ChildProfile(
      id: '',
      userId: 'test-user-id',
      name: '',
      birthDate: DateTime(2023, 1, 1),
      gender: 'unspecified',
      createdAt: DateTime(2024, 1, 1)
    ));
  });

  group('ChildFormScreen - 등록 모드 렌더링', () {
    testWidgets('주요 UI 요소가 모두 표시된다', (tester) async {
      final mockRepo = MockChildProfileRepository();
      await tester.pumpWidget(_buildApp(mockRepo));
      await tester.pumpAndSettle();

      expect(find.text('아이 프로필 등록'), findsOneWidget);
      expect(find.text('아이 이름'), findsOneWidget);
      expect(find.text('생년월일'), findsOneWidget);
      expect(find.text('성별'), findsOneWidget);
      expect(find.text('남아'), findsOneWidget);
      expect(find.text('여아'), findsOneWidget);
      expect(find.text('저장'), findsOneWidget);
      expect(find.text('건너뛰기'), findsOneWidget);
    });

    testWidgets('등록 모드에서는 삭제 버튼이 없다', (tester) async {
      final mockRepo = MockChildProfileRepository();
      await tester.pumpWidget(_buildApp(mockRepo));
      await tester.pumpAndSettle();

      expect(find.text('삭제'), findsNothing);
    });
  });

  group('ChildFormScreen - 수정 모드 렌더링', () {
    testWidgets('기존 데이터가 pre-fill 된다', (tester) async {
      final mockRepo = MockChildProfileRepository();
      await tester.pumpWidget(_buildApp(mockRepo, initialProfile: _testProfile));
      await tester.pumpAndSettle();

      expect(find.text('아이 프로필 수정'), findsOneWidget);
      expect(find.text('수정'), findsOneWidget);
      expect(find.text('삭제'), findsOneWidget);

      final nameCtrl = tester
        .widget<TextField>(find.byType(TextField).first).controller;
      expect(nameCtrl?.text, '지우');
    });

    testWidgets('알레르기 메모가 pre-fill 된다', (tester) async {
      final mockRepo = MockChildProfileRepository();
      await tester.pumpWidget(_buildApp(mockRepo, initialProfile: _testProfile));
      await tester.pumpAndSettle();

      final allergyCtrl = tester
        .widget<TextField>(find.byType(TextField).last)
        .controller;
      expect(allergyCtrl?.text, '땅콩');
    });
  });

  group('ChildFormScreen - 유효성 검증', () {
    testWidgets('이름 미입력 시 스낵바가 표시된다', (tester) async {
      final mockRepo = MockChildProfileRepository();
      await tester.pumpWidget(_buildApp(mockRepo));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('저장'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('저장'));
      await tester.pump();

      expect(find.text('아이 이름을 입력해주세요.'), findsOneWidget);
    });

    testWidgets('이름 입력 후 생년월일 미선택 시 스낵바가 표시된다', (tester) async {
      final mockRepo = MockChildProfileRepository();
      await tester.pumpWidget(_buildApp(mockRepo));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, '하늘이');
      await tester.ensureVisible(find.text('저장'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('저장'));
      await tester.pump();

      expect(find.text('생년월일을 선택해주세요.'), findsOneWidget);
    });
  });

  group('ChildFormScreen - 수정 성공/실패', () {
    testWidgets('수정 성공 시 홈 화면으로 이동한다', (tester) async {
      final mockRepo = MockChildProfileRepository();
      when(() => mockRepo.updateProfile(any()))
        .thenAnswer((_) async => _testProfile);

      await tester.pumpWidget(_buildApp(mockRepo, initialProfile: _testProfile));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('수정'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('수정'));
      await tester.pumpAndSettle();

      expect(find.text('home'), findsOneWidget);
      verify(() => mockRepo.updateProfile(any())).called(1);
    });

    testWidgets('수정 실패 시 에러 스낵바가 표시된다', (tester) async {
      final mockRepo = MockChildProfileRepository();
      when(() => mockRepo.updateProfile(any()))
        .thenThrow(Exception('서버 오류가 발생했습니다.'));

      await tester.pumpWidget(_buildApp(mockRepo, initialProfile: _testProfile));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('수정'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('수정'));
      await tester.pump();

      expect(find.text('서버 오류가 발생했습니다.'), findsOneWidget);
    });
  });

  group('ChildFormScreen - 삭제', () {
    testWidgets('삭제 버튼 탭 시 확인 다이얼로그가 표시된다', (tester) async {
      final mockRepo = MockChildProfileRepository();
      await tester.pumpWidget(_buildApp(mockRepo, initialProfile: _testProfile));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('삭제'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('삭제'));
      await tester.pumpAndSettle();

      expect(find.text('프로필 삭제'), findsOneWidget);
      expect(find.text('취소'), findsOneWidget);
    });

    testWidgets('삭제 확인 시 홈 화면으로 이동한다', (tester) async {
      final mockRepo = MockChildProfileRepository();
      when(() => mockRepo.deleteProfile(any())).thenAnswer((_) async {});

      await tester.pumpWidget(_buildApp(mockRepo, initialProfile: _testProfile));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('삭제'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('삭제'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('삭제').last);
      await tester.pumpAndSettle();

      expect(find.text('home'), findsOneWidget);
      verify(() => mockRepo.deleteProfile('child-1')).called(1);
    });

    testWidgets('취소 탭 시 다이얼로그가 닫히고 화면에 머문다', (tester) async {
      final mockRepo = MockChildProfileRepository();
      await tester.pumpWidget(_buildApp(mockRepo, initialProfile: _testProfile));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('삭제'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('삭제'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();

      expect(find.text('아이 프로필 수정'), findsOneWidget);
      expect(find.text('home'), findsNothing);
    });
  });
}