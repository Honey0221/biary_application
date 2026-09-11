import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';

class MealDatePicker extends StatelessWidget {
  final DateTime date;
  final VoidCallback onTap;

  const MealDatePicker({super.key, required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final formatted = DateFormatter.toDateLabel(date);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.inputBorder),
          borderRadius: BorderRadius.circular(10),
          color: Colors.white
        ),
        child: Row(
          children: [
            const Icon(LucideIcons.calendar, size: 18, color: AppColors.grayCaption),
            const SizedBox(width: 8),
            Text(formatted,
                style: const TextStyle(fontSize: 15, color: AppColors.darkGray)
            )
          ]
        )
      )
    );
  }
}