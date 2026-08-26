import 'package:flutter/material.dart';
import 'package:honey/core/constants/app_colors.dart';

// 텍스트 필드 위젯
class BiaryTextField extends StatefulWidget {
  const BiaryTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.errorText,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.maxLines = 1,
    this.suffixIcon
  });

  final TextEditingController controller;
  final String hint;
  final String? errorText;
  final bool obscureText;
  final TextInputType keyboardType;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;
  final int maxLines;
  final Widget? suffixIcon;

  @override
  State<BiaryTextField> createState() => _BiaryTextFieldState();
}

class _BiaryTextFieldState extends State<BiaryTextField> {
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  BorderSide get _borderSide {
    final hasError = widget.errorText != null;

    if (hasError) {
      return BorderSide(
        color: AppColors.error,
        width: _focusNode.hasFocus ? 1.5 : 1.0
      );
    }

    if (_focusNode.hasFocus) {
      return const BorderSide(color: AppColors.primaryBrown, width: 1.5);
    }

    return const BorderSide(color: AppColors.inputBorder);
  }

  OutlineInputBorder get _border =>
    OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: _borderSide
    );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: widget.controller,
          focusNode: _focusNode,
          obscureText: widget.obscureText,
          keyboardType: widget.keyboardType,
          onChanged: widget.onChanged,
          onSubmitted: widget.onSubmitted,
          enabled: widget.enabled,
          maxLines: widget.obscureText ? 1 : widget.maxLines,
          style: const TextStyle(color: AppColors.darkGray, fontSize: 15),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: const TextStyle(
              color: AppColors.grayCaption,
              fontSize: 15
            ),
            suffixIcon: widget.suffixIcon,
            filled: true,
            fillColor: widget.enabled ?
              Colors.white.withValues(alpha: 0.7)
              : AppColors.surfaceMuted,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 16
            ),
            border: _border,
            enabledBorder: _border,
            focusedBorder: _border,
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.divider)
            ),
            errorBorder: _border,
            focusedErrorBorder: _border
          )
        ),
        if (widget.errorText != null) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              widget.errorText!,
              style: const TextStyle(color: AppColors.error, fontSize: 12)
            )
          )
        ]
      ]
    );
  }
}