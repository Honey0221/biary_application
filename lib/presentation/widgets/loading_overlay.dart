import 'package:flutter/material.dart';
import 'package:honey/core/constants/app_colors.dart';

// 로딩 오버레이 위젯
class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child
  });

  final bool isLoading;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          const Positioned.fill(
            child: ColoredBox(
              color: Color(0x66000000),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primaryBrown)
              )
            )
          )
      ]
    );
  }
}