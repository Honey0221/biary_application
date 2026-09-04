import 'package:flutter/material.dart';
import 'package:honey/core/constants/app_colors.dart';
import 'package:honey/presentation/widgets/biary_button.dart';

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
    final hasTwoButtons = cancelLabel != null;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        decoration: BoxDecoration(
          color: AppColors.warmCream,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.divider),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 4)
            )
          ]
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkGray,
                      height: 1.4
                    )
                  ),
                  const SizedBox(height: 10),
                  Text(
                    content,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textMedium,
                      height: 1.7
                    )
                  )
                ]
              )
            ),
            const Divider(height: 1, color: AppColors.divider),
            Padding(
              padding: const EdgeInsets.all(16),
              child: hasTwoButtons ? Row(
                children: [
                  Expanded(
                    child: BiaryButton(
                      label: cancelLabel!,
                      type: BiaryButtonType.outlined,
                      height: 46,
                      onPressed: () {
                        Navigator.of(context).pop();
                        onCancel?.call();
                      }
                    )
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _confirmButton(context)
                  )
                ]
              ) : _confirmButton(context),
            )
          ]
        )
      )
    );
  }

  Widget _confirmButton(BuildContext context) {
    return isDangerous ? ElevatedButton(
      onPressed: () {
        Navigator.of(context).pop();
        onConfirm?.call();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.error,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(46),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)
        ),
        elevation: 0
      ),
      child: Text(
        confirmLabel,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600
        )
      )
    ) : BiaryButton(
      label: confirmLabel,
      height: 46,
      onPressed: () {
        Navigator.of(context).pop();
        onConfirm?.call();
      }
    );
  }
}