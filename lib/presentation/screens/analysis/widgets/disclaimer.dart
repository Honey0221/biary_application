import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

class Disclaimer extends StatelessWidget {
  const Disclaimer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(10)
        ),
        child: const Text(
            '· 영양소 데이터: 식품안전처 식품영양성분 DB 기준\n'
                '· 영양 기준: 2025 한국인 영양소 섭취기준 (KDRI 2025)\n'
                '· AI 분석 및 계산 결과에 오차가 발생할 수 있습니다\n'
                '· 이 화면은 참고용 정보로, 전문 의료 상담을 대체하지 않습니다',
            style: TextStyle(
                fontSize: 11,
                color: AppColors.textMedium,
                height: 1.7
            )
        )
    );
  }
}