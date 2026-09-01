import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:honey/presentation/screens/auth/guest_entry_screen.dart';

GoRouter _buildRouter() => GoRouter(routes: [
  GoRoute(path: '/', builder: (_, _) => const GuestEntryScreen()),
  GoRoute(
    path: '/guest-home',
    builder: (_, _) => const Scaffold(body: Text('guest-home'))
  ),
  GoRoute(
    path: '/login',
    builder: (_, _) => const Scaffold(body: Text('login'))
  )
]);

void main() {
  group('GuestEntryScreen - 렌더링', () {
    testWidgets('Step 1 요소가 렌더링된다', (tester) async {
      await tester.pumpWidget(MaterialApp.router(routerConfig: _buildRouter()));

      expect(find.text('아이 정보를 입력해주세요'), findsOneWidget);
      expect(find.text('생년월일을 선택해주세요.'), findsOneWidget);
      expect(find.text('남아'), findsOneWidget);
      expect(find.text('여아'), findsOneWidget);
      expect(find.text('다음'), findsOneWidget);
      expect(find.text('건너뛰기'), findsOneWidget);
    });
  });

  group('GuestEntryScreen - 탭 이동', () {
    testWidgets('Step 1에서 다음 버튼 탭 시 Step 2로 이동한다', (tester) async {
      await tester.pumpWidget(MaterialApp.router(routerConfig: _buildRouter()));

      await tester.tap(find.text('다음'));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('오늘 먹인 식단을 알려주세요'), findsOneWidget);
      expect(find.text('분석 결과 보기'), findsOneWidget);
    });

    testWidgets('건너뛰기 버튼 탭 시 /guest-home으로 이동한다', (tester) async {
      await tester.pumpWidget(MaterialApp.router(routerConfig: _buildRouter()));
      await tester.tap(find.text('건너뛰기'));
      await tester.pumpAndSettle();

      expect(find.text('guest-home'), findsOneWidget);
    });

    testWidgets('Step 2에서 이전 버튼 탭 시 Step 1로 이동한다', (tester) async {
      await tester.pumpWidget(MaterialApp.router(routerConfig: _buildRouter()));

      await tester.tap(find.text('다음'));
      await tester.pump(const Duration(milliseconds: 400));

      await tester.tap(find.text('이전'));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('아이 정보를 입력해주세요'), findsOneWidget);
    });

    testWidgets('입력 내용 없을 때 뒤로가기 탭 시 로그인 화면으로 이동한다', (tester) async {
      await tester.pumpWidget(MaterialApp.router(routerConfig: _buildRouter()));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();

      expect(find.text('login'), findsOneWidget);
    });

    testWidgets('입력 내용 있을 때 뒤로가기 탭 시 확인 다이얼로그가 표시된다', (tester) async {
      await tester.pumpWidget(MaterialApp.router(routerConfig: _buildRouter()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('남아'));
      await tester.pump();

      await tester.tap(find.byType(IconButton));
      await tester.pump();
      await tester.pump();

      expect(find.text('작성 중인 내용이 있어요'), findsOneWidget);
    });
  });

  group('GuestEntryScreen - 음식 필드 관리', () {
    Future<void> goToStep2(WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp.router(routerConfig: _buildRouter()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('다음'));
      await tester.pumpAndSettle();
    }

    testWidgets('초기 음식 입력 필드는 1개다', (tester) async {
      await goToStep2(tester);

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('추가 버튼 탭 시 음식 입력 필드가 늘어난다', (tester) async {
      await goToStep2(tester);

      await tester.tap(find.byIcon(Icons.add_circle_outline));
      await tester.pump();

      expect(find.byType(TextField), findsNWidgets(2));
    });

    testWidgets('음식 필드 2개 이상일 때 삭제 버튼이 표시된다', (tester) async {
      await goToStep2(tester);

      await tester.tap(find.byIcon(Icons.add_circle_outline));
      await tester.pump();

      expect(find.byIcon(Icons.close), findsWidgets);
    });

    testWidgets('삭제 버튼 탭 시 해당 필드가 제거된다', (tester) async {
      await goToStep2(tester);

      await tester.tap(find.byIcon(Icons.add_circle_outline));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsNWidgets(2));

      await tester.tap(find.byIcon(Icons.close).first);
      await tester.pump();
      expect(find.byType(TextField), findsOneWidget);
    });
  });

  group('GuestEntryScreen - 분석 유효성', () {
    testWidgets('전체 미입력 시 에러 다이얼로그가 표시된다', (tester) async {
      await tester.pumpWidget(MaterialApp.router(routerConfig: _buildRouter()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('다음'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('분석 결과 보기'));
      await tester.pump();
      await tester.pump();

      expect(find.text('입력하지 않은 항목이 있어요'), findsOneWidget);
    });

    testWidgets('식사 구분 미선택 시 에러 다이얼로그에 식사 구분이 포함된다', (tester) async {
      await tester.pumpWidget(MaterialApp.router(routerConfig: _buildRouter()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('다음'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, '쌀죽');
      await tester.tap(find.text('분석 결과 보기'));
      await tester.pump();
      await tester.pump();

      expect(find.text('입력하지 않은 항목이 있어요'), findsOneWidget);
      expect(find.textContaining('식사 구분'), findsWidgets);
    });

    testWidgets('음식 목록 미입력 시 에러 다이얼로그에 음식 목록이 포함된다', (tester) async {
      await tester.pumpWidget(MaterialApp.router(routerConfig: _buildRouter()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('다음'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('아침'));
      await tester.pump();

      await tester.tap(find.text('분석 결과 보기'));
      await tester.pump();
      await tester.pump();

      expect(find.text('입력하지 않은 항목이 있어요'), findsOneWidget);
      expect(find.textContaining('음식 목록'), findsWidgets);
    });
  });
}