import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:honey/core/constants/app_colors.dart';
import 'package:honey/core/utils/version_checker.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadVersionAndNavigate();
  }

  Future<void> _loadVersionAndNavigate() async {
    final version = await VersionChecker.getCurrentVersion();
    if (mounted) setState(() => _version = version);

    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // TODO : 로그인 상태에 따른 화면 이동 로직 추가 예정
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmCream,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenHeight = constraints.maxHeight;

          return Stack(
            children: [
              // 로고 이미지(화면 32% 지점 중앙)
              Positioned(
                top: screenHeight * 0.32,
                left: 0,
                right: 0,
                child: Center(
                  child: Image.asset(
                    'assets/images/Biary_logo.png',
                    width: 300,
                    height: 300,
                    fit: BoxFit.contain
                  )
                )
              ),
              // 슬로건 텍스트(화면 60% 지점)
              Positioned(
                top: screenHeight * 0.6,
                left: 32,
                right: 32,
                child: const Text(
                  '작은 옹알이부터 큰 꿈을 펼칠 때까지',
                  style: TextStyle(
                    color: AppColors.darkGray,
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.8,
                    height: 1.6
                  ),
                  textAlign: TextAlign.center
                )
              ),
              // 앱 버전 (화면 84% 지점)
              Positioned(
                top: screenHeight * 0.84,
                left: 0,
                right: 0,
                child: Text(
                  'v$_version',
                  style: const TextStyle(
                    color: AppColors.grayCaption,
                    fontSize: 12,
                    letterSpacing: 0.3
                  ),
                  textAlign: TextAlign.center
                )
              ),
              // 카피라이트 (화면 88% 지점)
              Positioned(
                top: screenHeight * 0.88,
                left: 0,
                right: 0,
                child: const Text(
                  'Copyright 2026 © Biary. All rights reserved.',
                  style: TextStyle(
                    color: AppColors.grayCaption,
                    fontSize: 11,
                    letterSpacing: 0.3
                  ),
                  textAlign: TextAlign.center
                )
              )
            ]
          );
        }
      )
    );
  }
}