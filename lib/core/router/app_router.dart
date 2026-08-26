import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
    // Phase 2~13 진행하면서 아래에 라우트 추가
  ],
);