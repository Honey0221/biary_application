import 'package:flutter/material.dart';
import 'package:honey/core/constants/app_colors.dart';
import 'package:honey/presentation/widgets/biary_text_field.dart';

// 라벨이 있는 필드 위젯
class BiaryLabeledField extends StatelessWidget {
  const BiaryLabeledField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.errorText,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.done,
    this.focusNode,
    this.maxLines = 1,
    this.suffixIcon,
    this.isRequired = false,
    this.onChanged,
    this.onSubmitted
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final String? errorText;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final FocusNode? focusNode;
  final int maxLines;
  final Widget? suffixIcon;
  final bool isRequired;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.darkGray,
                fontSize: 14,
                fontWeight: FontWeight.w500
              )
            ),
            if (isRequired) ...[
              const SizedBox(width: 2),
              const Text(
                '*',
                style: TextStyle(color: AppColors.error, fontSize: 14)
              )
            ]
          ]
        ),
        const SizedBox(height: 8),
        BiaryTextField(
          controller: controller,
          hint: hint ?? label,
          errorText: errorText,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          focusNode: focusNode,
          maxLines: maxLines,
          suffixIcon: suffixIcon,
          onChanged: onChanged,
          onSubmitted: onSubmitted
        )
      ],
    );
  }
}