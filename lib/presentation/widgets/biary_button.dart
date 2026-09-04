import 'package:flutter/material.dart';
import 'package:honey/core/constants/app_colors.dart';

// 버튼 타입 열거형
enum BiaryButtonType { filled, outlined, text }

// 버튼 위젯
class BiaryButton extends StatelessWidget {
  const BiaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.type = BiaryButtonType.filled,
    this.isLoading = false,
    this.width = double.infinity,
    this.height = 52,
    this.contentPadding,
    this.icon
  });

  final String label;
  final VoidCallback? onPressed;
  final BiaryButtonType type;
  final bool isLoading;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? contentPadding;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: _buildButton()
    );
  }

  Widget _buildButton() {
    final isDisabled = onPressed == null;

    switch (type) {
      case BiaryButtonType.filled:
        return ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: 
              isDisabled ? AppColors.divider : AppColors.primaryBrown,
            foregroundColor: 
              isDisabled ? AppColors.grayCaption : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)
            ),
            elevation: 0
          ),
          child: _buildChild()
        );
      case BiaryButtonType.outlined:
        return OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: 
              isDisabled ? AppColors.grayCaption : AppColors.primaryBrown,
            side: BorderSide(
              color: isDisabled ? AppColors.divider : AppColors.primaryBrown,
              width: 1.2
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)
            ),
            padding: contentPadding
          ),
          child: _buildChild()
        );
      case BiaryButtonType.text:
        return TextButton(
          onPressed: isLoading ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor:
              isDisabled ? AppColors.grayCaption : AppColors.linkText
          ),
          child: _buildChild()
        );
    }
  }

  Widget _buildChild() {
    if (isLoading) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
      );
    }

    final textWidget = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.3
      )
    );

    if (icon != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [icon!, const SizedBox(width: 8), textWidget]
      );
    }

    return textWidget;
  }
}