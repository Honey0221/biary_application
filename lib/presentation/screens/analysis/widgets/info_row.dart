import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../data/models/analysis_result.dart';

class InfoRow extends StatelessWidget {
  const InfoRow({super.key, required this.result, required this.childName});

  final AnalysisResult result;
  final String childName;

  @override
  Widget build(BuildContext context) {
    final date = DateFormatter.toDateLabel(result.targetDate);
    final mealLabel = {
      'breakfast': '아침',
      'lunch': '점심',
      'dinner': '저녁',
      'snack': '간식'
    }[result.mealType] ?? result.mealType;

    return Text(
        '$date · $childName · $mealLabel',
        style: const TextStyle(fontSize: 13, color: AppColors.textMedium)
    );
  }
}