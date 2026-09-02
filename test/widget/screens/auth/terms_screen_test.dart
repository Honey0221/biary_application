import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:honey/presentation/screens/policy/terms_screen.dart';

GoRouter _buildRouter({bool readOnly = false}) => GoRouter(
  routes: [
    GoRoute(path: '/', builder: (_, _) => TermsScreen(readOnly: readOnly)),
    GoRoute(path: '/signup', builder: (_, _) => const Scaffold(body: Text('signup')))
  ]
);

void main() {
  group('TermsScreen - 초기 렌더링', () {
    testWidgets('동의합니다 버튼이 비활성화된 상태로 렌더링된다', (tester) async {
      await tester.pumpWidget(MaterialApp.router(routerConfig: _buildRouter()));

      expect(find.text('동의합니다'), findsOneWidget);
      expect(find.text('스크롤을 내려 내용을 확인해 주세요'), findsOneWidget);

      final btn = tester.widget<ElevatedButton>(find.byType(ElevatedButton).first);
      expect(btn.onPressed, isNull);
    });

    testWidgets('readOnly 모드에서는 동의합니다 버튼이 표시되지 않는다', (tester) async {
      await tester.pumpWidget(
          MaterialApp.router(routerConfig: _buildRouter(readOnly: true))
      );

      expect(find.text('동의합니다'), findsNothing);
      expect(find.text('스크롤을 내려 내용을 확인해 주세요'), findsNothing);
    });
  });

  group('TermsScreen - 스크롤 동작', () {
    testWidgets('콘텐츠를 끝까지 스크롤하면 동의합니다 버튼이 활성화된다', (tester) async {
      await tester.pumpWidget(MaterialApp.router(routerConfig: _buildRouter()));

      final btnBefore = tester.widget<ElevatedButton>(find.byType(ElevatedButton).first);
      expect(btnBefore.onPressed, isNull);

      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -10000));
      await tester.pumpAndSettle();

      final btnAfter = tester.widget<ElevatedButton>(find.byType(ElevatedButton).first);
      expect(btnAfter.onPressed, isNotNull);
    });

    testWidgets('스크롤 완료 후 안내 문구가 사라진다', (tester) async {
      await tester.pumpWidget(MaterialApp.router(routerConfig: _buildRouter()));

      expect(find.text('스크롤을 내려 내용을 확인해 주세요'), findsOneWidget);

      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -10000));
      await tester.pumpAndSettle();

      expect(find.text('스크롤을 내려 내용을 확인해 주세요'), findsNothing);
    });
  });
}