import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:honey/data/repositories/auth_repository.dart';
import 'package:honey/presentation/screens/auth/signup_screen.dart';
import 'package:honey/providers/auth_provider.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

GoRouter _buildRouter() => GoRouter(routes: [
  GoRoute(path: '/', builder: (_, _) => const SignupScreen()),
  GoRoute(path: '/login', builder: (_, _) => const Scaffold(body: Text('login'))),
  GoRoute(path: '/terms', builder: (_, _) => const Scaffold(body: Text('terms'))),
  GoRoute(path: '/home', builder: (_, _) => const Scaffold(body: Text('home')))
]);

Widget buildTestApp(MockAuthRepository mockRepo) {
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(mockRepo)
    ],
    child: MaterialApp.router(routerConfig: _buildRouter())
  );
}

void main() {
  group('SignupScreen - 렌더링', () {
    testWidgets('주요 입력 필드가 렌더링된다', (tester) async {
      await tester.pumpWidget(MaterialApp.router(routerConfig: _buildRouter()));

      expect(find.text('이메일'), findsOneWidget);
      expect(find.text('비밀번호 (영문+숫자 8자 이상)'), findsOneWidget);
      expect(find.text('비밀번호 확인'), findsOneWidget);
      expect(find.text('가입하기'), findsOneWidget);
    });
  });

  group('SignupScreen - 가입 버튼 활성화 조건', () {
    testWidgets('초기 상태에서 가입 버튼이 비활성화된다', (tester) async {
      await tester.pumpWidget(MaterialApp.router(routerConfig: _buildRouter()));

      final btn = tester.widget<ElevatedButton>(find.byType(ElevatedButton).first);
      expect(btn.onPressed, isNull);
    });

    testWidgets('닉네임 중복 미확인 상태에서 약관 동의해도 버튼이 비활성화된다', (tester) async {
      await tester.pumpWidget(MaterialApp.router(routerConfig: _buildRouter()));

      await tester.tap(find.byType(Checkbox).first);
      await tester.pump();

      final btn = tester.widget<ElevatedButton>(find.byType(ElevatedButton).first);
      expect(btn.onPressed, isNull);
    });

    // TODO: 실제 회원가입 성공/실패
  });

  group('SignupScreen — 닉네임 중복 확인', () {
    testWidgets('닉네임이 사용 가능하면 확인 완료 표시가 된다', (tester) async {
      final mockRepo = MockAuthRepository();
      when(() => mockRepo.isNicknameTaken(any())).thenAnswer((_) async => false);

      await tester.pumpWidget(buildTestApp(mockRepo));

      await tester.enterText(find.byType(TextField).at(3), '새닉네임');
      await tester.tap(find.text('중복확인'));
      await tester.pump();

      expect(find.text('사용 가능한 닉네임입니다.'), findsOneWidget);
    });

    testWidgets('닉네임이 중복이면 에러 메시지가 표시된다', (tester) async {
      final mockRepo = MockAuthRepository();
      when(() => mockRepo.isNicknameTaken(any())).thenAnswer((_) async => true);

      await tester.pumpWidget(buildTestApp(mockRepo));

      await tester.enterText(find.byType(TextField).at(3), '중복닉네임');
      await tester.tap(find.text('중복확인'));
      await tester.pump();

      expect(find.text('이미 사용 중인 닉네임입니다.'), findsOneWidget);
    });
  });

  group('SignupScreen - 유효성', () {
    testWidgets('닉네임 입력 변경 시 확인 상태가 초기화된다', (tester) async {
      await tester.pumpWidget(MaterialApp.router(routerConfig: _buildRouter()));

      final nicknameFields = find.byType(TextField);
      await tester.enterText(nicknameFields.at(3), '테스트닉네임');
      await tester.pump();

      final btn = tester.widget<ElevatedButton>(find.byType(ElevatedButton).first);
      expect(btn.onPressed, isNull);
    });
  });

  group('SignupScreen - 회원가입 처리', () {
    testWidgets('약관 미동의 상태에서 가입 시도 시 안내 메시지가 표시된다', (tester) async {
      final mockRepo = MockAuthRepository();
      when(() => mockRepo.isNicknameTaken(any())).thenAnswer((_) async => false);

      await tester.pumpWidget(buildTestApp(mockRepo));

      await tester.enterText(find.byType(TextField).at(0), 'test@test.com');
      await tester.enterText(find.byType(TextField).at(1), 'pass1234');
      await tester.enterText(find.byType(TextField).at(2), 'pass1234');
      await tester.enterText(find.byType(TextField).at(3), '닉네임테스트');

      // 닉네임 확인은 하되, 약관 동의 체크박스는 탭하지 않음
      await tester.tap(find.text('중복확인'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('가입하기'));
      await tester.pump();

      expect(find.text('개인정보처리방침에 동의해주세요.'), findsOneWidget);
    });

    testWidgets('모든 조건 충족 시 회원가입 완료 다이얼로그가 표시된다', (tester) async {
      final mockRepo = MockAuthRepository();
      when(() => mockRepo.isNicknameTaken(any())).thenAnswer((_) async => false);
      when(() => mockRepo.signUp(any(), any(), any())).thenAnswer((_) async {});

      await tester.pumpWidget(buildTestApp(mockRepo));

      await tester.enterText(find.byType(TextField).at(0), 'test@test.com');
      await tester.enterText(find.byType(TextField).at(1), 'pass1234');
      await tester.enterText(find.byType(TextField).at(2), 'pass1234');
      await tester.enterText(find.byType(TextField).at(3), '닉네임테스트');

      await tester.tap(find.text('중복확인'));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Checkbox));
      await tester.pump();

      await tester.tap(find.text('가입하기'));
      await tester.pump();
      await tester.pump();

      expect(find.text('회원가입 완료'), findsOneWidget);
      await tester.tap(find.text('다음에'));
      await tester.pumpAndSettle();

      expect(find.text('home'), findsOneWidget);
      verify(() => mockRepo.signUp('test@test.com', 'pass1234', '닉네임테스트')).called(1);
    });

    testWidgets('signUp 실패 시 스낵바가 표시된다', (tester) async {
      final mockRepo = MockAuthRepository();
      when(() => mockRepo.isNicknameTaken(any())).thenAnswer((_) async => false);
      when(() => mockRepo.signUp(any(), any(), any()))
          .thenThrow(Exception('이미 사용 중인 이메일입니다.'));

      await tester.pumpWidget(buildTestApp(mockRepo));

      await tester.enterText(find.byType(TextField).at(0), 'test@test.com');
      await tester.enterText(find.byType(TextField).at(1), 'pass1234');
      await tester.enterText(find.byType(TextField).at(2), 'pass1234');
      await tester.enterText(find.byType(TextField).at(3), '닉네임테스트');

      await tester.tap(find.text('중복확인'));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Checkbox));
      await tester.pump();

      await tester.tap(find.text('가입하기'));
      await tester.pump();

      expect(find.byType(SnackBar), findsOneWidget);
    });
  });
}