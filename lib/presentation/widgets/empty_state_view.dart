import 'package:flutter/material.dart';
import 'package:honey/presentation/widgets/biary_button.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:honey/core/constants/app_colors.dart';

// 빈 상태 위젯
class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    super.key,
    this.icon = LucideIcons.clipboardList,
    required this.message,
    this.subMessage,
    this.actionLabel,
    this.onAction
  });

  final IconData icon;
  final String message;
  final String? subMessage;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: AppColors.primaryMuted),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(
                color: AppColors.textMedium,
                fontSize: 15,
                fontWeight: FontWeight.w500
              ),
              textAlign: TextAlign.center
            ),
            if (subMessage != null) ...[
              const SizedBox(height: 6),
              Text(
                subMessage!,
                style: const TextStyle(
                  color: AppColors.grayCaption,
                  fontSize: 13
                ),
                textAlign: TextAlign.center
              )
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              BiaryButton(
                label: actionLabel!,
                onPressed: onAction,
                width: 160,
                height: 44
              )
            ]
          ]
        )
      )
    );
  }
}