import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:honey/presentation/screens/auth/find_password_screen.dart';
import 'package:honey/presentation/screens/auth/signup_screen.dart';
import 'package:honey/presentation/screens/home/home_screen.dart';
import 'package:honey/presentation/screens/policy/terms_screen.dart';
import 'package:honey/presentation/screens/splash/splash_screen.dart';
import 'package:honey/presentation/screens/auth/login_screen.dart';

// 페이드 전환 헬퍼 함수
CustomTransitionPage<void> _fadePage({
  required LocalKey pageKey,
  required Widget child,
  Duration duration = const Duration(milliseconds: 800),
}) {
  return CustomTransitionPage<void>(
    key: pageKey,
    child: child,
    transitionDuration: duration,
    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
      FadeTransition(opacity: animation, child: child),
  );
}

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      pageBuilder: (context, state) => _fadePage(
        pageKey: state.pageKey,
        child: const SplashScreen(),
      ),
    ),
    GoRoute(
      path: '/login',
      pageBuilder: (context, state) => _fadePage(
        pageKey: state.pageKey,
        child: const LoginScreen(),
      ),
    ),
    GoRoute(
      path: '/signup',
      pageBuilder: (context, state) => _fadePage(
        pageKey: state.pageKey,
        child: const SignupScreen()
      )
    ),
    GoRoute(
      path: '/find-password',
      pageBuilder: (context, state) => _fadePage(
        pageKey: state.pageKey,
        child: const FindPasswordScreen()
      )
    ),
    GoRoute(
      path: '/terms',
      pageBuilder: (context, state) => _fadePage(
        pageKey: state.pageKey,
        child: TermsScreen(
          readOnly: state.extra as bool? ?? false,
        )
      )
    ),
    GoRoute(
      path: '/home',
      pageBuilder: (context, state) => _fadePage(
        pageKey: state.pageKey,
        child: const HomeScreen()
      )
    ),
    // 개발 진행하면서 여기에 라우트 추가
  ],
);