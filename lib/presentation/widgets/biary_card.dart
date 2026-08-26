import 'package:flutter/material.dart';
import 'package:honey/core/constants/app_colors.dart';

// 카드 위젯
class BiaryCard extends StatelessWidget {
  const BiaryCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.backgroundColor = Colors.white
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider, width: 1),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D000000),
                blurRadius: 8,
                offset: Offset(0, 2)
              )
            ]
          ),
          child: child
        )
      )
    );
  }
}