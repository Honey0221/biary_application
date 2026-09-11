import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';

class ChildSelector extends StatelessWidget {
  final dynamic child;
  final VoidCallback onTap;

  const ChildSelector({super.key, required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasChild = child != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(
              color: hasChild ? AppColors.primaryBrown : AppColors.inputBorder
          ),
          borderRadius: BorderRadius.circular(10),
          color: Colors.white
        ),
        child: Row(
          children: [
            Icon(
              LucideIcons.baby,
              size: 18,
              color: hasChild ? AppColors.primaryBrown : AppColors.grayCaption
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                hasChild ? child.name : '아이를 선택해주세요',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: hasChild ? FontWeight.w600 : FontWeight.normal,
                  color: hasChild ? AppColors.darkGray : AppColors.grayCaption
                )
              )
            ),
            const Icon(
              LucideIcons.chevronDown,
              size: 16,
              color: AppColors.grayCaption
            )
          ]
        )
      )
    );
  }
}