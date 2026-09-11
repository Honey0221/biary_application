import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/meal_item.dart';

class FoodItemTile extends StatelessWidget {
  final MealItem item;

  const FoodItemTile({super.key, required this.item});

  static const _reactionIcons = {
    'good': LucideIcons.smile,
    'normal': LucideIcons.meh,
    'bad': LucideIcons.frown
  };
  static const _reactionLabels = {
    'good': '좋아요', 'normal': '보통', 'bad': '거부'
  };
  static const _reactionColors = {
    'good': AppColors.success,
    'normal': AppColors.primaryLight,
    'bad': AppColors.error
  };

  @override
  Widget build(BuildContext context) {
    final reaction = item.reactionType;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(10)
      ),
      child: Row(
        children: [
          // 음식명
          Expanded(
              child: Text(
                  item.customFoodName,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.darkGray
                  )
              )
          ),
          // 섭취량
          if (item.intakeAmountG != null) ...[
            Text(
                '${item.intakeAmountG!.toStringAsFixed(0)}g',
                style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textMedium
                )
            ),
            const SizedBox(width: 10)
          ],
          // 반응 칩
          if (reaction != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: (_reactionColors[reaction] ?? AppColors.primaryLight)
                  .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20)
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _reactionIcons[reaction] ?? LucideIcons.meh,
                    size: 13,
                    color: _reactionColors[reaction] ?? AppColors.primaryLight
                  ),
                  const SizedBox(width: 3),
                  Text(
                    _reactionLabels[reaction] ?? '',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: _reactionColors[reaction] ?? AppColors.primaryLight
                    )
                  )
                ]
              )
            )
        ]
      )
    );
  }
}