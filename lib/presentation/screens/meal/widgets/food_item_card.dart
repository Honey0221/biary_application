import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import 'food_search_field.dart';
import 'food_entry.dart';

class FoodItemCard extends ConsumerWidget {
  final FoodEntry foodEntry;
  final bool canDelete;
  final VoidCallback onRemove;
  final VoidCallback onFoodChanged;
  final ValueChanged<String?> onReactionChanged;

  const FoodItemCard({
    super.key,
    required this.foodEntry,
    required this.canDelete,
    required this.onRemove,
    required this.onFoodChanged,
    required this.onReactionChanged
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.inputBorder),
        borderRadius: BorderRadius.circular(10),
        color: Colors.white
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: FoodSearchField(
                  controller: foodEntry.nameCtrl,
                  selectedFood: foodEntry.selectedFood,
                  hintText: '음식명 검색 또는 직접 입력',
                  onSelected: (result) {
                    foodEntry.nameCtrl.text = result.foodName;
                    foodEntry.selectedFood = result;
                    onFoodChanged();
                  },
                  onChanged: onFoodChanged,
                )
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: foodEntry.amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: '섭취량(g)',
                    hintStyle: TextStyle(color: AppColors.grayCaption),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true
                  ),
                  style: const TextStyle(fontSize: 15)
                )
              ),
              if (canDelete) ...[
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: onRemove,
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      LucideIcons.trash2,
                      size: 18,
                      color: AppColors.grayCaption
                    )
                  )
                )
              ]
            ]
          ),
          const Divider(height: 16, color: AppColors.divider),
          Row(
            children: [
              const Text('반응', style: TextStyle(
                fontSize: 12, color: AppColors.grayCaption
              )),
              const SizedBox(width: 12),
              ..._buildReactionChips()
            ]
          )
        ]
      )
    );
  }

  List<Widget> _buildReactionChips() {
    const types = ['good', 'normal', 'bad'];
    const labels = {'good': '좋아요', 'normal': '보통', 'bad': '거부'};
    const icons = {
      'good': LucideIcons.smile,
      'normal': LucideIcons.meh,
      'bad': LucideIcons.frown
    };

    return types.map((type) {
      final selected = foodEntry.reactionType == type;
      return Padding(
        padding: const EdgeInsets.only(right: 6),
        child: GestureDetector(
          onTap: () => onReactionChanged(selected ? null : type),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: selected ? AppColors.primaryBrown : Colors.transparent,
              border: Border.all(
                color: selected ? AppColors.primaryBrown : AppColors.inputBorder
              ),
              borderRadius: BorderRadius.circular(20)
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icons[type]!, size: 13,
                  color: selected ? Colors.white : AppColors.grayCaption),
                const SizedBox(width: 4),
                Text(labels[type]!, style: TextStyle(
                  fontSize: 12,
                  color: selected ? Colors.white : AppColors.grayCaption)
                )
              ]
            )
          )
        )
      );
    }).toList();
  }
}