import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_fonts.dart';

class AiCommentCard extends StatelessWidget {
  const AiCommentCard({super.key, required this.comment});
  final String comment;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.inputBorder)
      ),
      child: Text(
        comment,
        style: const TextStyle(
          fontSize: 13,
          fontFamily: AppFonts.dodum,
          color: AppColors.darkGray,
          height: 1.6
        )
      )
    );
  }
}