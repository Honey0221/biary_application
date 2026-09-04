import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:honey/data/models/food_search_result.dart';
import 'package:honey/providers/food_search_provider.dart';

import '../../core/constants/app_colors.dart';

class FoodSearchField extends ConsumerWidget {
  final TextEditingController controller;
  final FoodSearchResult? selectedFood;
  final String hintText;
  final bool hasError;
  final ValueChanged<FoodSearchResult> onSelected;
  final VoidCallback onChanged;

  const FoodSearchField({
    super.key,
    required this.controller,
    required this.selectedFood,
    this.hintText = '음식명 검색',
    this.hasError = false,
    required this.onSelected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Autocomplete<FoodSearchResult>(
      initialValue: TextEditingValue(text: controller.text),
      optionsBuilder: (textVal) async {
        final q = textVal.text.trim();
        if (q.length < 2) return const [];
        try {
          return await ref.read(foodApiRepositoryProvider).searchFoods(q);
        } catch (_) {
          return const [];
        }
      },
      displayStringForOption: (r) => r.foodName,
      onSelected: (result) {
        controller.text = result.foodName;
        onSelected(result);
        onChanged();
      },
      fieldViewBuilder: (ctx, autoCrl, focusNode, _) {
        return TextField(
          controller: autoCrl,
          focusNode: focusNode,
          onChanged: (val) {
            controller.text = val;
            onChanged();
          },
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(
              color: AppColors.grayCaption,
              fontSize: 13,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: hasError ? AppColors.error : AppColors.inputBorder,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: hasError ? AppColors.error : AppColors.inputBorder,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primaryBrown),
            )
          )
        );
      },
      optionsViewBuilder: (ctx, onSel, options) =>
        _FoodSearchDropDown(options: options, onSelected: onSel)
    );
  }
}

class _FoodSearchDropDown extends StatelessWidget {
  final Iterable<FoodSearchResult> options;
  final void Function(FoodSearchResult) onSelected;

  const _FoodSearchDropDown({required this.options, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 200),
          child: ListView.separated(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            itemCount: options.length,
            separatorBuilder: (_, _) =>
              const Divider(height: 1, color: AppColors.divider),
            itemBuilder: (_, i) {
              final item = options.elementAt(i);
              return ListTile(
                dense: true,
                title: Text(
                  item.foodName,
                  style: const TextStyle(fontSize: 14),
                ),
                subtitle: item.makerName != null ? Text(
                    item.makerName!,
                    style: const TextStyle(fontSize: 12),
                  )
                : null,
                trailing: item.calories != null ? Text(
                  '${item.calories!.toStringAsFixed(0)} kcal',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.grayCaption,
                  ))
                : null,
                onTap: () => onSelected(item)
              );
            }
          )
        )
      )
    );
  }
}
