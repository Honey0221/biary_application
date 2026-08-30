import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:honey/providers/auth_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:honey/data/repositories/auth_repository.dart';
import 'package:honey/presentation/screens/auth/login_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

GoRouter _buildRouter() => GoRouter(routes: [
  GoRoute(path: '/', builder: (_, _) => const LoginScreen()),
  GoRoute(path: '/signup', builder: (_, _) => const Scaffold(body: Text('signup'))),
  GoRoute(
    path: '/find-password',
    builder: (_, _) => const Scaffold(body: Text('find-password'))
  ),
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
  group('LoginScreen - 렌더링', () {
    testWidgets('주요 UI 요소가 모두 렌더링된다', (tester) async {
      await tester.pumpWidget(MaterialApp.router(routerConfig: _buildRouter()));

      expect(find.text('로그인'), findsWidgets);
      expect(find.text('회원가입'), findsOneWidget);
      expect(find.text('비밀번호 찾기'), findsOneWidget);
      expect(find.text('Google로 로그인'), findsOneWidget);
      expect(find.text('게스트로 입장하기'), findsOneWidget);
    });
  });

  group('LoginScreen - 비밀번호 표시/숨김', () {
    testWidgets('초기 상태에서 비밀번호가 마스킹된다', (tester) async {
      await tester.pumpWidget(MaterialApp.router(routerConfig: _buildRouter()));
      
      final fields = tester.widgetList<TextField>(find.byType(TextField)).toList();
      expect(fields.last.obscureText, isTrue);
    });

    testWidgets('아이콘 버튼 탭 시 비밀번호가 표시된다', (tester) async {
      await tester.pumpWidget(MaterialApp.router(routerConfig: _buildRouter()));

      await tester.tap(find.byType(IconButton));
      await tester.pump();

      final fields = tester.widgetList<TextField>(find.byType(TextField)).toList();
      expect(fields.last.obscureText, isFalse);
    });
  });

  group('LoginScreen - 유효성', () {
    testWidgets('이메일, 비밀번호 미입력 시 스낵바가 표시된다', (tester) async {
      await tester.pumpWidget(MaterialApp.router(routerConfig: _buildRouter()));

      await tester.tap(find.text('로그인').first);
      await tester.pump();

      expect(find.text('이메일과 비밀번호를 입력해주세요.'), findsOneWidget);
    });
  });

  group('LoginScreen - 로그인 시도', () {
    testWidgets('이메일, 비밀번호 입력 후 로그인 성공 시 /home으로 이동한다', (tester) async {
      final mockRepo = MockAuthRepository();
      when(() => mockRepo.signInWithEmail(any(), any()))
        .thenAnswer((_) async {});

      await tester.pumpWidget(buildTestApp(mockRepo));

      await tester.enterText(find.byType(TextField).first, 'test@test.com');
      await tester.enterText(find.byType(TextField).last, 'password123');
      await tester.tap(find.text('로그인').first);
      await tester.pumpAndSettle();

      expect(find.text('home'), findsOneWidget);
      verify(() => mockRepo.signInWithEmail('test@test.com', 'password123')).called(1);
    });

    testWidgets('로그인 실패 시 스낵바가 표시된다', (tester) async {
      final mockRepo = MockAuthRepository();
      when(() => mockRepo.signInWithEmail(any(), any()))
        .thenThrow(const AuthException('이메일 또는 비밀번호가 올바르지 않습니다.'));

      await tester.pumpWidget(buildTestApp(mockRepo));

      await tester.enterText(find.byType(TextField).first, 'test@test.com');
      await tester.enterText(find.byType(TextField).last, 'password123');
      await tester.tap(find.text('로그인').first);
      await tester.pump();

      expect(find.text('이메일 또는 비밀번호가 올바르지 않습니다.'), findsOneWidget);
    });
  });

  group('LoginScreen - 화면 이동', () {
    testWidgets('회원가입 버튼 탭 시 /signup으로 이동한다', (tester) async {
      await tester.pumpWidget(MaterialApp.router(routerConfig: _buildRouter()));

      await tester.tap(find.text('회원가입'));
      await tester.pumpAndSettle();

      expect(find.text('signup'), findsOneWidget);
    });

    testWidgets('비밀번호 찾기 탭 시 /find-password로 이동한다', (tester) async {
      await tester.pumpWidget(MaterialApp.router(routerConfig: _buildRouter()));

      await tester.tap(find.text('비밀번호 찾기'));
      await tester.pumpAndSettle();

      expect(find.text('find-password'), findsOneWidget);
    });
  });
}