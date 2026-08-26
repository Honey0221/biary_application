import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:honey/core/constants/app_colors.dart';

// 구독 배너 위젯
class SubscriptionBanner extends StatelessWidget {
  const SubscriptionBanner({
    super.key,
    required this.onTap
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primaryMuted, width: 1)
        ),
        child: Row(
          children: [
            const Icon(
              LucideIcons.crown,
              color: AppColors.primaryBrown,
              size: 20
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '구독하고 더 많은 기능을 사용해보세요',
                    style: TextStyle(
                      color: AppColors.darkGray,
                      fontSize: 13,
                      fontWeight: FontWeight.w600
                    )
                  ),
                  SizedBox(height: 2),
                  Text(
                    '기록 열람 - 영양 그래프 - 월간 리포트 등',
                    style: TextStyle(
                      color: AppColors.textMedium,
                      fontSize: 12
                    )
                  )
                ]
              )
            ),
            const Icon(
              LucideIcons.chevronRight,
              color: AppColors.primaryMuted,
              size: 18
            )
          ]
        )
      )
    );
  }
}