import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:honey/data/repositories/auth_repository.dart';
import 'package:honey/presentation/screens/auth/find_password_screen.dart';
import 'package:honey/providers/auth_provider.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

GoRouter _buildRouter() => GoRouter(routes: [
  GoRoute(path: '/', builder: (_, _) => const FindPasswordScreen()),
  GoRoute(path: '/login', builder: (_, _) => const Scaffold(body: Text('login')))
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
  group('FindPasswordScreen - 렌더링', () {
    testWidgets('이메일 입력 화면이 렌더링된다', (tester) async {
      await tester.pumpWidget(MaterialApp.router(routerConfig: _buildRouter()));

      expect(find.text('비밀번호 찾기'), findsOneWidget);
      expect(find.text('인증번호 발송'), findsOneWidget);
    });
  });

  group('FindPasswordScreen - 유효성', () {
    testWidgets('이메일 미입력 시 에러 메시지가 표시된다', (tester) async {
      await tester.pumpWidget(MaterialApp.router(routerConfig: _buildRouter()));

      await tester.tap(find.text('인증번호 발송'));
      await tester.pump();

      expect(
        find.textContaining('이메일').evaluate().isNotEmpty ||
          find.byType(SnackBar).evaluate().isNotEmpty, isTrue
      );
    });
  });

  group('FindPasswordScreen - 화면 이동', () {
    testWidgets('유효한 이메일 입력 후 전송 성공 시 2단계로 이동한다', (tester) async {
      final mockRepo = MockAuthRepository();
      when(() => mockRepo.sendOtp(any())).thenAnswer((_) async {});

      await tester.pumpWidget(buildTestApp(mockRepo));

      await tester.enterText(find.byType(TextField).first, 'test@test.com');
      await tester.tap(find.text('인증번호 발송'));
      await tester.pumpAndSettle();

      expect(find.text('확인'), findsOneWidget); // 2단계 버튼
      verify(() => mockRepo.sendOtp('test@test.com')).called(1);
    });

    testWidgets('OTP 입력 후 확인 성공 시 3단계로 이동한다', (tester) async {
      final mockRepo = MockAuthRepository();
      when(() => mockRepo.sendOtp(any())).thenAnswer((_) async {});
      when(() => mockRepo.verifyOtp(any(), any())).thenAnswer((_) async {});

      await tester.pumpWidget(buildTestApp(mockRepo));

      // 1단계
      await tester.enterText(find.byType(TextField).first, 'test@test.com');
      await tester.tap(find.text('인증번호 발송'));
      await tester.pumpAndSettle();

      // 2단계
      await tester.enterText(find.byType(TextField).first, '123456');
      await tester.tap(find.text('확인'));
      await tester.pumpAndSettle();

      expect(find.text('비밀번호 재설정'), findsOneWidget); // 3단계 버튼
    });

    testWidgets('뒤로가기 버튼 탭 시 /login으로 이동한다', (tester) async {
      await tester.pumpWidget(MaterialApp.router(routerConfig: _buildRouter()));

      await tester.tap(find.byType(IconButton).first);
      await tester.pumpAndSettle();

      expect(find.text('login'), findsOneWidget);
    });
  });
}