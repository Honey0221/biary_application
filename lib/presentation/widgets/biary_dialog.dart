import 'package:flutter/material.dart';
import 'package:honey/core/constants/app_colors.dart';

class BiaryDialog extends StatelessWidget {
  const BiaryDialog({
    super.key,
    required this.title,
    required this.content,
    this.confirmLabel = '확인',
    this.cancelLabel,
    this.onConfirm,
    this.onCancel,
    this.isDangerous = false
  });

  final String title;
  final String content;
  final String confirmLabel;
  final String? cancelLabel;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final bool isDangerous;

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String content,
    String confirmLabel = '확인',
    String? cancelLabel,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    bool isDangerous = false
  }) {
    return showDialog(
      context: context,
      barrierDismissible: cancelLabel != null,
      builder: (_) => BiaryDialog(
        title: title,
        content: content,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        onConfirm: onConfirm,
        onCancel: onCancel,
        isDangerous: isDangerous
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadiusGeometry.circular(16)),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.darkGray
        )
      ),
      content: Text(
        content,
        style: const TextStyle(
          fontSize: 14,
          color: AppColors.textMedium,
          height: 1.6
        )
      ),
      actions: [
        if (cancelLabel != null)
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onCancel?.call();
            },
            child: Text(
              confirmLabel,
              style: TextStyle(
                color: isDangerous ? AppColors.error : AppColors.primaryBrown,
                fontSize: 14,
                fontWeight: FontWeight.w600
              )
            )
          )
      ]
    );
  }
}