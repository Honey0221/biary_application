import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/nutrient_codes.dart';
import '../../../../core/utils/nutrient_calculator.dart';
import '../../../../data/models/analysis_result.dart';

class NutrientBars extends StatelessWidget {
  const NutrientBars({super.key, required this.result, required this.isGuest});

  final AnalysisResult result;
  final bool isGuest;

  static const _guestCodes = [
    NutrientCodes.energy,
    NutrientCodes.carbs,
    NutrientCodes.protein,
    NutrientCodes.fat
  ];

  @override
  Widget build(BuildContext context) {
    final codes = isGuest ? _guestCodes : NutrientCodes.displayOrder;
    final nutrients = result.nutrients;

    return Column(
        children: codes.map((code) {
          final value = nutrients[code] ?? 0.0;
          final status = result.statusSummary[code];
          final rate = (NutrientCalculator.rateFromStatus(status) / 100).clamp(0.0, 1.5);
          final color = _colorFromStatus(status);
          final label = NutrientCodes.labelKr[code] ?? code;

          return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                              children: [
                                Text(label,
                                    style: const TextStyle(
                                        fontSize: 13, color: AppColors.darkGray
                                    )
                                ),
                                if (result.aiEstimatedFoods.isNotEmpty)
                                  const Padding(
                                      padding: EdgeInsets.only(left: 4),
                                      child: Text('AI 추정',
                                          style: TextStyle(
                                              fontSize: 10, color: AppColors.warning
                                          )
                                      )
                                  )
                              ]
                          ),
                          Text(
                              '${value.toStringAsFixed(1)} / '
                                  '${_statusLabel(status)}',
                              style: TextStyle(fontSize: 11, color: color)
                          )
                        ]
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                            value: rate.clamp(0.0, 1.0),
                            minHeight: 8,
                            backgroundColor: AppColors.surfaceMuted,
                            color: color
                        )
                    )
                  ]
              )
          );
        }).toList()
    );
  }

  Color _colorFromStatus(String? status) {
    return switch (status) {
      'adequate' => AppColors.nutrientOk,
      'slightlyLow' || 'deficient' => AppColors.nutrientLow,
      'slightlyHigh' || 'excess' => AppColors.nutrientHigh,
      _ => AppColors.textMedium
    };
  }

  String _statusLabel(String? status) {
    return switch (status) {
      'adequate' => '적정',
      'slightlyLow' => '약간 부족',
      'deficient' => '부족',
      'slightlyHigh' => '약간 과잉',
      'excess' => '과잉',
      'no_standard' => '기준 없음',
      _ => '-'
    };
  }
}