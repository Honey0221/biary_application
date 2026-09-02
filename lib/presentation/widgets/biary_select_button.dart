import 'package:flutter/material.dart';
import 'package:honey/core/constants/app_colors.dart';

class BiarySelectButton extends StatelessWidget {
  const BiarySelectButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.hasError = false,
    this.verticalPadding = 14.0,
    this.borderRadius = 10.0
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool hasError;
  final double verticalPadding;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: verticalPadding),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryBrown : Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: selected ?
              AppColors.primaryBrown : hasError ?
                AppColors.error : AppColors.inputBorder
          )
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            color: selected ? Colors.white : AppColors.textMedium
          )
        )
      )
    );
  }
}