import 'package:flutter/material.dart';
import 'package:honey/core/constants/app_colors.dart';

// 인라인 텍스트 링크 위젯
class BiaryTextLink extends StatelessWidget {
  const BiaryTextLink({
    super.key,
    required this.label,
    required this.onTap,
    this.underline = false,
    this.fontSize = 13
  });

  final String label;
  final VoidCallback onTap;
  final bool underline;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: TextStyle(
          color: AppColors.linkText,
          fontSize: fontSize,
          decoration: underline ? TextDecoration.underline : TextDecoration.none,
          decorationColor: AppColors.linkText
        ),
      ),
    );
  }
}