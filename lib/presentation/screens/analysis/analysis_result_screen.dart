import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:honey/core/constants/app_colors.dart';
import 'package:honey/data/models/analysis_result.dart';

import 'widgets/modified_banner.dart';
import 'widgets/disclaimer.dart';
import 'widgets/blur_lock_section.dart';
import 'widgets/ai_comment_card.dart';
import 'widgets/nutrient_bars.dart';
import 'widgets/info_row.dart';
import 'widgets/section_title.dart';

class AnalysisResultScreen extends ConsumerWidget {
  const AnalysisResultScreen({
    super.key,
    required this.result,
    required this.childName,
    required this.isGuest,
    required this.isModified
  });

  final AnalysisResult result;
  final String childName;
  final bool isGuest;
  final bool isModified; // 기록 수정 후 재진입시 true

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.warmCream,
        appBar: AppBar(
          backgroundColor: AppColors.warmCream,
          elevation: 0,
          scrolledUnderElevation: 0,
          automaticallyImplyLeading: false,
          title: const Text(
            '영양 분석 결과',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.darkGray
            )
          ),
          centerTitle: true
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 수정 안내 배너
              if (isModified) ModifiedBanner(),
              const SizedBox(height: 8),

              // 날짜, 아이, 식사 구분
              InfoRow(result: result, childName: childName),
              const SizedBox(height: 24),

              // 영양소 달성률
              SectionTitle(title: '영양소 달성률'),
              const SizedBox(height: 12),
              NutrientBars(result: result, isGuest: isGuest),
              const SizedBox(height: 24),

              // AI 코멘트
              if (!isGuest && (result.aiComment?.isNotEmpty ?? false)) ...[
                SectionTitle(title: 'AI 코멘트'),
                const SizedBox(height: 8),
                AiCommentCard(comment: result.aiComment!),
                const SizedBox(height: 24)
              ],

              // 블러 잠금 영역
              BlurLockSection(isGuest: isGuest),
              const SizedBox(height: 32),

              // 참고 안내
              const Disclaimer(),
              const SizedBox(height: 24),

              // 홈 이동 버튼
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => context.go('/home'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryBrown,
                    side: const BorderSide(color: AppColors.primaryBrown),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)
                    )
                  ),
                  child: const Text('홈으로 돌아가기', style: TextStyle(fontSize: 15))
                )
              )
            ]
          )
        )
      )
    );
  }
}