import 'package:flutter/material.dart';
import 'package:honey/core/constants/app_colors.dart';

// 체크박스 타일 위젯
class BiaryCheckboxTile extends StatelessWidget {
  const BiaryCheckboxTile({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.linkText,
    this.onLinkTap
  });

  final String label;
  final bool value;
  final ValueChanged<bool?> onChanged;
  final String? linkText;
  final VoidCallback? onLinkTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primaryBrown,
            side: const BorderSide(color: AppColors.inputBorder, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4)
            )
          )
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.darkGray,
              fontSize: 14
            )
          )
        ),
        if (linkText != null && onLinkTap != null) ...[
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onLinkTap,
            child: Text(
              linkText!,
              style: const TextStyle(
                color: AppColors.linkText,
                fontSize: 13,
                decoration: TextDecoration.underline,
                decorationColor: AppColors.linkText
              )
            )
          )
        ]
      ]
    );
  }
}