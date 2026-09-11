import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class ModifiedBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4))
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 16, color: AppColors.warning),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              '식단 기록이 수정되었어요. 최신 내용으로 재분석하려면 아래 버튼을 눌러주세요.',
              style: TextStyle(fontSize: 12, color: AppColors.warning),
            )
          )
        ]
      )
    );
  }
}