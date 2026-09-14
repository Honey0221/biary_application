import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:honey/core/constants/app_colors.dart';
import 'package:honey/core/utils/age_calculator.dart';
import 'package:honey/core/utils/date_formatter.dart';
import 'package:honey/data/services/analysis_service.dart';
import 'package:honey/main.dart';
import 'package:honey/presentation/screens/meal/widgets/food_item_tile.dart';
import 'package:honey/presentation/screens/meal/widgets/meal_header_card.dart';
import 'package:honey/presentation/screens/meal/widgets/photo_row.dart';
import 'package:honey/presentation/widgets/biary_button.dart';
import 'package:honey/presentation/widgets/biary_dialog.dart';
import 'package:honey/providers/analysis_provider.dart';
import 'package:honey/providers/child_profile_provider.dart';
import 'package:honey/providers/meal_record_provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/utils/analysis_flow_helper.dart';
import '../../../data/models/meal_record.dart';
import '../analysis/widgets/analysis_loading_overlay.dart';

class MealRecordDetailScreen extends ConsumerWidget {
  final String recordId;

  const MealRecordDetailScreen({super.key, required this.recordId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordAsync = ref.watch(mealRecordProvider(recordId));

    return recordAsync.when(
      loading: () => Scaffold(
        backgroundColor: AppColors.warmCream,
        appBar: AppBar(
          backgroundColor: AppColors.warmCream,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft, color: AppColors.darkGray),
            onPressed: () => context.pop()
          )
        ),
        body: const Center(child: CircularProgressIndicator())
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppColors.warmCream,
        appBar: AppBar(
          backgroundColor: AppColors.warmCream,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft, color: AppColors.darkGray),
            onPressed: () => context.pop()
          ),
          title: const Text('식단 기록',
            style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.darkGray)
          ),
          centerTitle: true
        ),
        body: Center(
          child: Text('불러오기 실패: $e',
            style: const TextStyle(color: AppColors.error)
          )
        )
      ),
      data: (record) => _DetailBody(record: record)
    );
  }
}

// 분석하기 버튼 상태
enum _AnalysisButtonState { loading, ready, done, reanalyze }

// 본문 위젯
class _DetailBody extends ConsumerWidget {
  final MealRecord record;

  const _DetailBody({required this.record});

  static const _mealTypeLabels = {
    'breakfast': '아침',
    'lunch': '점심',
    'dinner': '저녁',
    'snack': '간식'
  };

  String get _mealTypeLabel =>
    _mealTypeLabels[record.mealType] ?? record.mealType;

  void _onEdit(BuildContext context) {
    context.push('/record/${record.id}/edit', extra: record);
  }

  Future<void> _onDelete(BuildContext context, WidgetRef ref) async {
    BiaryDialog.show(
      context,
      title: '기록 삭제',
      content: '정말 기록을 삭제하시겠어요?\n삭제된 기록은 복구할 수 없어요.',
      confirmLabel: '삭제',
      cancelLabel: '취소',
      isDangerous: true,
      onConfirm: () async {
        try {
          await ref.read(mealRecordRepositoryProvider).deleteRecord(record.id!);
          if (context.mounted) context.pop();
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('삭제 중 오류가 발생했습니다: $e'))
            );
          }
        }
      }
    );
  }

  Future<void> _onAnalysis(BuildContext context, WidgetRef ref) async {
    final child = ref.read(selectedChildProvider);
    if (child == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('아이 프로필을 먼저 등록해주세요')),
      );
      return;
    }

    final isGuest = supabase.auth.currentUser == null;
    if (isGuest) {
      final now = DateTime.now();
      final key = 'analysis_${now.year}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
      final box = Hive.box<int>('guestAnalysisBox');
      final count = box.get(key, defaultValue: 0)!;
      if (count >= 3) {
        if (context.mounted) {
          BiaryDialog.show(
            context,
            title: '오늘 분석 횟수를 모두 사용하셨어요',
            content: '게스트는 하루 3회까지 분석할 수 있어요.\n회원가입하면 무제한 이용 가능해요',
            confirmLabel: '회원가입',
            cancelLabel: '닫기',
            onConfirm: () => context.go('/signup')
          );
        }
        return;
      }
      await box.put(key, count + 1);
    }

    const isSubscriber = false; // TODO: 구독 여부 provider 연결

    if (!context.mounted) return;

    final response = await AnalysisLoadingOverlay.show<AnalysisResponse>(
      context, ref,
      childName: child.name,
      taskBuilder: (onProgress) => AnalysisService.analyze(
        isSubscriber: isSubscriber,
        items: record.items,
        childId: child.id,
        childAgeMonths: AgeCalculator.toMonths(child.birthDate),
        childGender: child.gender,
        onProgress: onProgress
      )
    );

    if (response == null || !context.mounted) return;

    final analysisRepo = ref.read(analysisRepositoryProvider);
    final analysisResult = await AnalysisFlowHelper.buildAndSave(
      response: response,
      mealRecordId: record.id!,
      childId: child.id,
      targetDate: record.mealDate,
      mealType: record.mealType,
      repo: analysisRepo
    );

    ref.invalidate(analysisProvider(record.id!));

    if (context.mounted) {
      context.go('/analysis/result', extra: {
        'result': analysisResult,
        'childName': child.name,
        'isGuest': isGuest,
        'isModified': false
      });
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analysisAsync = ref.watch(analysisProvider(record.id!));

    final buttonState = analysisAsync.when(
      loading: () => _AnalysisButtonState.loading,
      error: (_, _) => _AnalysisButtonState.ready,
      data: (result) {
        if (result == null) return _AnalysisButtonState.ready;
        if (AnalysisFlowHelper.needsNewAnalysis(result, record.updatedAt)) {
          return _AnalysisButtonState.reanalyze;
        }
        return _AnalysisButtonState.done;
      }
    );

    return Scaffold(
      backgroundColor: AppColors.warmCream,
      appBar: AppBar(
        backgroundColor: AppColors.warmCream,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.darkGray),
          onPressed: () => context.pop()
        ),
        title: const Text(
          '식단 기록 상세',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.darkGray
          )
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.pencil, color: AppColors.darkGray),
            tooltip: '수정',
            onPressed: () => _onEdit(context)
          ),
          IconButton(
            icon: const Icon(LucideIcons.trash2, color: AppColors.darkGray),
            tooltip: '삭제',
            onPressed: () => _onDelete(context, ref)
          ),
          const SizedBox(width: 4)
        ]
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 날짜 + 식사 구분 헤더 카드
            MealHeaderCard(
              date: DateFormatter.toDateLabel(record.mealDate),
              mealType: _mealTypeLabel
            ),
            const SizedBox(height: 24),

            // 2. 음식 목록
            const Text(
              '음식 목록', style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.darkGray
              )
            ),
            const SizedBox(height: 10),
            if (record.items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  '등록된 음식이 없어요',
                  style: TextStyle(
                    fontSize: 14, color: AppColors.grayCaption
                  )
                )
              )
            else ...record.items.map((item) => FoodItemTile(item: item)),

            // 3. 사진 (있을 때만)
            if (record.photos.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text(
                '사진', style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkGray
                )
              ),
              const SizedBox(height: 10),
              PhotoRow(photos: record.photos)
            ],

            // 4. 메모 (있을 때만)
            if (record.memo != null && record.memo!.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text(
                '메모', style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkGray
                )
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.inputBorder),
                  borderRadius: BorderRadius.circular(12)
                ),
                child: Text(
                  record.memo!,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: AppColors.darkGray
                  )
                )
              )
            ],
            const SizedBox(height: 36),

            // 5. 영양 분석 버튼 (상태별 디자인 변화)
            switch (buttonState) {
              _AnalysisButtonState.loading => BiaryButton(
                label: '분석 정보 확인 중',
                onPressed: null,
                isLoading: true
              ),
              _AnalysisButtonState.ready => BiaryButton(
                label: '영양 분석하기',
                onPressed: () => _onAnalysis(context, ref)
              ),
              _AnalysisButtonState.done => BiaryButton(
                label: '분석 완료',
                onPressed: null,
                icon: const Icon(LucideIcons.checkCircle, size: 16)
              ),
              _AnalysisButtonState.reanalyze => BiaryButton(
                label: '재분석하기',
                type: BiaryButtonType.outlined,
                onPressed: () => _onAnalysis(context, ref),
                icon: const Icon(LucideIcons.refreshCw, size: 16)
              )
            }
          ]
        )
      )
    );
  }
}