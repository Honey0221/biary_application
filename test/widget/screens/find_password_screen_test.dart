import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:honey/data/repositories/auth_repository.dart';
import 'package:honey/presentation/screens/auth/find_password_screen.dart';
import 'package:honey/providers/auth_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

      await tester.enterText(find
          .byType(TextField)
          .first, 'test@test.com');
      await tester.tap(find.text('인증번호 발송'));
      await tester.pumpAndSettle();

      expect(find.text('확인'), findsOneWidget); // 2단계 버튼
      verify(() => mockRepo.sendOtp('test@test.com')).called(1);
    });
  });

  // OTP 단계까지 이동하는 헬퍼 함수
  Future<void> reachOtpStep(
    WidgetTester tester, MockAuthRepository mockRepo
  ) async {
    when(() => mockRepo.sendOtp(any())).thenAnswer((_) async {});
    await tester.pumpWidget(buildTestApp(mockRepo));

    await tester.enterText(find.byType(TextField).first, 'test@test.com');
    await tester.tap(find.text('인증번호 발송'));
    await tester.pumpAndSettle();
  }

  // OTP 단계부터 비밀번호 재설정 단계까지 이동하는 헬퍼 함수
  Future<void> reachNewPasswordStep(
    WidgetTester tester, MockAuthRepository mockRepo
  ) async {
    when(() => mockRepo.sendOtp(any())).thenAnswer((_) async {});
    when(() => mockRepo.verifyOtp(any(), any())).thenAnswer((_) async {});
    await tester.pumpWidget(buildTestApp(mockRepo));

    await tester.enterText(find.byType(TextField).first, 'test@test.com');
    await tester.tap(find.text('인증번호 발송'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '123456');
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
  }

  group('FindPasswordScreen - OTP 단계', () {
    testWidgets('6자리 미만 입력 시 에러 메시지가 표시된다', (tester) async {
      final mockRepo = MockAuthRepository();
      await reachOtpStep(tester, mockRepo);

      await tester.enterText(find.byType(TextField).first, '123');
      await tester.tap(find.text('확인'));
      await tester.pump();

      expect(find.textContaining('6자리'), findsOneWidget);
    });

    testWidgets('OTP 인증 실패 시 에러 메시지가 표시된다', (tester) async {
      final mockRepo = MockAuthRepository();
      when(() => mockRepo.verifyOtp(any(), any()))
        .thenThrow(AuthException('유효하지 않은 인증번호입니다.'));

      await reachOtpStep(tester, mockRepo);

      await tester.enterText(find.byType(TextField).first, '000000');
      await tester.tap(find.text('확인'));
      await tester.pump();
      await tester.pump();

      expect(find.textContaining('유효하지 않은 인증번호'), findsOneWidget);
    });

    testWidgets('재발송 버튼 탭 시 sendOtp가 재호출된다', (tester) async {
      final mockRepo = MockAuthRepository();
      await reachOtpStep(tester, mockRepo);

      await tester.tap(find.text('재발송'));
      await tester.pumpAndSettle();

      verify(() => mockRepo.sendOtp('test@test.com')).called(2);
    });
  });

  group('FindPasswordScreen - 비밀번호 재설정 단계', () {
    testWidgets('비밀번호 미입력 시 에러 메시지가 표시된다', (tester) async {
      final mockRepo = MockAuthRepository();
      await reachNewPasswordStep(tester, mockRepo);

      await tester.tap(find.text('비밀번호 재설정'));
      await tester.pump();

      expect(find.text('비밀번호를 입력해주세요.'), findsOneWidget);
    });

    testWidgets('비밀번호 8자 미만 입력 시 에러 메시지가 표시된다', (tester) async {
      final mockRepo = MockAuthRepository();
      await reachNewPasswordStep(tester, mockRepo);

      await tester.enterText(find.byType(TextField).at(0), 'abc12');
      await tester.tap(find.text('비밀번호 재설정'));
      await tester.pump();

      expect(find.text('비밀번호는 8자 이상이어야 합니다.'), findsOneWidget);
    });

    testWidgets('비밀번호 확인 불일치 시 에러 메시지가 표시된다', (tester) async {
      final mockRepo = MockAuthRepository();
      await reachNewPasswordStep(tester, mockRepo);

      await tester.enterText(find.byType(TextField).at(0), 'password12');
      await tester.enterText(find.byType(TextField).at(1), 'password13');
      await tester.tap(find.text('비밀번호 재설정'));
      await tester.pump();

      expect(find.textContaining('비밀번호가 일치하지 않습니다.'), findsOneWidget);
    });

    testWidgets('성공 시 완료 화면이 표시된다', (tester) async {
      final mockRepo = MockAuthRepository();
      when(() => mockRepo.updatePassword(any())).thenAnswer((_) async {});
      await reachNewPasswordStep(tester, mockRepo);

      await tester.enterText(find.byType(TextField).at(0), 'password12');
      await tester.enterText(find.byType(TextField).at(1), 'password12');
      await tester.tap(find.text('비밀번호 재설정'));
      await tester.pump();
      await tester.pump();

      expect(find.textContaining('비밀번호가 재설정 완료!'), findsOneWidget);
    });
  });
}