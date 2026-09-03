import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:honey/core/constants/app_colors.dart';
import 'package:honey/core/utils/date_formatter.dart';
import 'package:honey/presentation/widgets/biary_button.dart';
import 'package:honey/presentation/widgets/biary_dialog.dart';
import 'package:honey/providers/meal_record_provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../data/models/meal_item.dart';
import '../../../data/models/meal_record.dart';
import '../../../data/models/meal_record_photo.dart';

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            _HeaderCard(
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
            else ...record.items.map((item) => _FoodItemTile(item: item)),

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
              _PhotoRow(photos: record.photos)
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

            // 5. 영양 분석 버튼
            BiaryButton(
              label: '영양 분석 시작',
              onPressed: () {
                // TODO: Phase 5 구현 예정
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('구현 예정 기능입니다'))
                );
              }
            )
          ]
        )
      )
    );
  }
}

// 헤더 카드
class _HeaderCard extends StatelessWidget {
  final String date;
  final String mealType;

  const _HeaderCard({required this.date, required this.mealType});

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

// 음식 항목 타일
class _FoodItemTile extends StatelessWidget {
  final MealItem item;

  const _FoodItemTile({required this.item});

  static const _reactionIcons = {
    'good': LucideIcons.smile,
    'normal': LucideIcons.meh,
    'bad': LucideIcons.frown
  };
  static const _reactionLabels = {
    'good': '좋아요', 'normal': '보통', 'bad': '거부'
  };
  static const _reactionColors = {
    'good': AppColors.success,
    'normal': AppColors.primaryLight,
    'bad': AppColors.error
  };

  @override
  Widget build(BuildContext context) {
    final reaction = item.reactionType;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(10)
      ),
      child: Row(
        children: [
          // 음식명
          Expanded(
            child: Text(
              item.customFoodName,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.darkGray
              )
            )
          ),
          // 섭취량
          if (item.intakeAmountG != null) ...[
            Text(
              '${item.intakeAmountG!.toStringAsFixed(0)}g',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textMedium
              )
            ),
            const SizedBox(width: 10)
          ],
          // 반응 칩
          if (reaction != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: (_reactionColors[reaction] ?? AppColors.primaryLight)
                  .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20)
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _reactionIcons[reaction] ?? LucideIcons.meh,
                    size: 13,
                    color: _reactionColors[reaction] ?? AppColors.primaryLight
                  ),
                  const SizedBox(width: 3),
                  Text(
                    _reactionLabels[reaction] ?? '',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: _reactionColors[reaction] ?? AppColors.primaryLight
                    )
                  )
                ]
              )
            )
        ]
      )
    );
  }
}

// 사진 가로 스크롤
class _PhotoRow extends StatelessWidget {
  final List<MealRecordPhoto> photos;

  const _PhotoRow({required this.photos});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: photos.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              photos[i].photoUrl,
              width: 100, height: 100,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                width: 100, height: 100,
                color: AppColors.surfaceMuted,
                child: const Icon(
                  LucideIcons.imageOff,
                  color: AppColors.grayCaption
                )
              )
            )
          );
        }
      )
    );
  }
}