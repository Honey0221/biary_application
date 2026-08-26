import 'package:flutter/material.dart';
import 'package:honey/core/constants/app_colors.dart';

// 폼 섹션 위젯
class BiaryFormSection extends StatelessWidget {
  const BiaryFormSection({
    super.key,
    required this.title,
    required this.child,
    this.padding = const EdgeInsets.symmetric(vertical: 16)
  });

  final String title;
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textMedium,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4
            ),
          ),
          const SizedBox(height: 8),
          const Divider(color: AppColors.divider, thickness: 1, height: 1),
          const SizedBox(height: 16),
          child
        ]
      )
    );
  }
}