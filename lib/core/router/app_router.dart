import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:honey/data/models/child_profile.dart';
import 'package:honey/data/models/meal_record.dart';
import 'package:honey/presentation/screens/auth/find_password_screen.dart';
import 'package:honey/presentation/screens/auth/guest_entry_screen.dart';
import 'package:honey/presentation/screens/auth/signup_screen.dart';
import 'package:honey/presentation/screens/child/child_form_screen.dart';
import 'package:honey/presentation/screens/home/guest_home_screen.dart';
import 'package:honey/presentation/screens/home/home_screen.dart';
import 'package:honey/presentation/screens/meal/meal_record_detail_screen.dart';
import 'package:honey/presentation/screens/meal/meal_record_form_screen.dart';
import 'package:honey/presentation/screens/policy/terms_screen.dart';
import 'package:honey/presentation/screens/splash/splash_screen.dart';
import 'package:honey/presentation/screens/auth/login_screen.dart';

// 페이드 전환 헬퍼 함수(루트 / 탭 전환)
CustomTransitionPage<void> _fadePage({
  required LocalKey pageKey,
  required Widget child
}) {
  return CustomTransitionPage<void>(
    key: pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 800),
    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
      FadeTransition(opacity: animation, child: child),
  );
}

// 푸시 전환 헬퍼 함수(목록 -> 상세)
CustomTransitionPage<void> _pushPage({
  required LocalKey pageKey,
  required Widget child
}) {
  return CustomTransitionPage<void>(
    key: pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final tween = Tween(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero
      ).chain(CurveTween(curve: Curves.easeOut));
      return SlideTransition(
        position: animation.drive(tween),
        child: child
      );
    }
  );
}

// 모달 전환 헬퍼 함수(상세 -> 편집/추가)
CustomTransitionPage<void> _modalPage({
  required LocalKey pageKey,
  required Widget child
}) {
  return CustomTransitionPage<void>(
      key: pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 350),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final tween = Tween(
            begin: const Offset(0.0, 1.0),
            end: Offset.zero
        ).chain(CurveTween(curve: Curves.easeOut));
        return SlideTransition(
            position: animation.drive(tween),
            child: child
        );
      }
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
    GoRoute(
      path: '/guest-entry',
      pageBuilder: (context, state) => _modalPage(
        pageKey: state.pageKey,
        child: const GuestEntryScreen()
      )
    ),
    GoRoute(
      path: '/guest-home',
      pageBuilder: (context, state) => _fadePage(
        pageKey: state.pageKey,
        child: const GuestHomeScreen()
      )
    ),
    GoRoute(
      path: '/child/new',
      pageBuilder: (context, state) => _modalPage(
        pageKey: state.pageKey,
        child: const ChildFormScreen()
      )
    ),
    GoRoute(
      path: '/child/:id/edit',
      pageBuilder: (context, state) => _modalPage(
        pageKey: state.pageKey,
        child: ChildFormScreen(initialProfile: state.extra as ChildProfile)
      )
    ),
    GoRoute(
      path: '/record/new',
      pageBuilder: (context, state) => _modalPage(
        pageKey: state.pageKey,
          child: const MealRecordFormScreen()
      )
    ),
    GoRoute(
      path: '/record/:id/edit',
      pageBuilder: (context, state) => _modalPage(
        pageKey: state.pageKey,
        child: MealRecordFormScreen(
          initialRecord: state.extra as MealRecord
        )
      )
    ),
    GoRoute(
      path: '/record/:id',
      pageBuilder: (context, state) => _pushPage(
        pageKey: state.pageKey,
        child: MealRecordDetailScreen(
          recordId: state.pathParameters['id']!
        )
      )
    ),
    // 개발 진행하면서 여기에 라우트 추가
  ]
);