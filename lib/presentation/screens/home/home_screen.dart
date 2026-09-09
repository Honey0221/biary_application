import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:honey/main.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('홈 대시보드 (구현 예정)'),
            const SizedBox(height: 24),
            // TODO: 개발 테스트용 임시 로그아웃 버튼 - 홈 화면 구현 시 제거
            OutlinedButton.icon(
              onPressed: () async {
                await supabase.auth.signOut();
                if (context.mounted) context.go('/login');
              },
              icon: const Icon(Icons.logout),
              label: const Text('로그아웃')
            )
          ]
        )
      )
    );
  }
}