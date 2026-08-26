import 'package:flutter/material.dart';
import 'package:honey/core/constants/app_colors.dart';

// 세그먼트 버튼 위젯
class BiarySegmentedButton extends StatelessWidget {
  const BiarySegmentedButton({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    this.height = 44
  });

  final List<String> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.warmCream,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.inputBorder)
      ),
      child: Row(
        children: List.generate(items.length, (index) {
          final isSelected = index == selectedIndex;
          final isFirst = index == 0;
          final isLast = index == items.length - 1;

          return Expanded(
            child: GestureDetector(
              onTap: () => onSelected(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryBrown : Colors.transparent,
                  borderRadius: BorderRadius.horizontal(
                    left: isFirst ? const Radius.circular(7) : Radius.zero,
                    right: isLast ? const Radius.circular(7) : Radius.zero
                  )
                ),
                alignment: Alignment.center,
                child: Text(
                  items[index],
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.primaryBrown,
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400
                  )
                )
              )
            )
          );
        })
      )
    );
  }
}