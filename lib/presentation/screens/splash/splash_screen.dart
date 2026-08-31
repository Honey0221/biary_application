import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:honey/core/constants/app_colors.dart';
import 'package:honey/core/utils/version_checker.dart';
import 'package:honey/main.dart';
import 'package:honey/presentation/widgets/biary_dialog.dart';
import 'package:url_launcher/url_launcher.dart';

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
    final current = await VersionChecker.getCurrentVersion();
    if (mounted) setState(() => _version = current);

    final minRequired = await VersionChecker.getMinRequiredVersion();
    if (minRequired != null &&
      VersionChecker.isUpdateRequired(current, minRequired)) {
      if (!mounted) return;
      await BiaryDialog.show(
        context,
        title: '업데이트 필요',
        content: '서비스 이용을 위해 최신 버전으로 업데이트해주세요',
        confirmLabel: '업데이트',
        onConfirm: () async {
          const url = 'https://play.google.com/store/apps/details?id=com.biary.app';
          final uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        }
      );
      return;
    }

    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final session = supabase.auth.currentSession;
    if (session != null) {
      context.go('/home');
    } else {
      context.go('/login');
    }
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