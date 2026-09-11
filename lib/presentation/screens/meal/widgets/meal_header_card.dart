import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

class MealHeaderCard extends StatelessWidget {
  final String date;
  final String mealType;

  const MealHeaderCard({super.key, required this.date, required this.mealType});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider)
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              date,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.darkGray
              )
            )
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryBrown,
              borderRadius: BorderRadius.circular(20)
            ),
            child: Text(
              mealType,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white
              )
            )
          )
        ]
      )
    );
  }
}