import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';

class BlurLockSection extends StatelessWidget {
  const BlurLockSection({super.key, required this.isGuest});
  final bool isGuest;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(12)
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isGuest ? '나머지 9개 영양소' : '최근 7일 영양 트렌드',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkGray
                  )
                ),
                const SizedBox(height: 12),
                for (int i = 0; i < 3; i++) ...[
                  Container(
                    height: 8,
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryMuted,
                      borderRadius: BorderRadius.circular(4)
                    )
                  )
                ],
                const SizedBox(height: 8),
                Container(
                  height: 12,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(4)
                  )
                )
              ]
            )
          )
        ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.warmCream.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(12)
            )
          )
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Column(
            children: [
              Text(
                isGuest ?
                '회원가입하면 더 많은 영양소 분석과\nAI 맞춤 코멘트를 받을 수 있어요!' :
                '구독하면 7일 트렌드 분석과\n맞춤 음식 추천을 받을 수 있어요!',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.darkGray,
                  height: 1.5
                ),
                textAlign: TextAlign.center
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go(isGuest ? '/signup' : '/subscription'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBrown,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 12
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)
                  )
                ),
                child: Text(
                  isGuest ? '회원가입' : '구독하기',
                  style: const TextStyle(fontSize: 14)
                )
              )
            ]
          )
        )
      ]
    );
  }
}