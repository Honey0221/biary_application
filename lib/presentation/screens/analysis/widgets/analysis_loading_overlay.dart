import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:honey/data/services/analysis_service.dart';
import 'package:honey/providers/ui_provider.dart';

import '../../../../core/constants/app_colors.dart';

class AnalysisLoadingOverlay extends ConsumerStatefulWidget {
  const AnalysisLoadingOverlay._({
    required this.childName,
    required this.taskBuilder,
    required this.onComplete
  });

  final String childName;
  final Future<dynamic> Function(ProgressCallback onProgress) taskBuilder;
  final void Function(dynamic result) onComplete;

  static Future<T?> show<T> (BuildContext context, WidgetRef ref, {
    required String childName,
    required Future<T> Function(ProgressCallback onProgress) taskBuilder
  }) async {
    ref.read(tabBarVisibleProvider.notifier).state = false;

    final result = await showGeneralDialog<T>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      pageBuilder: (ctx, _, _) => AnalysisLoadingOverlay._(
        childName: childName,
        taskBuilder: taskBuilder,
        onComplete: (res) => Navigator.of(ctx).pop(res as T?)
      )
    );

    ref.read(tabBarVisibleProvider.notifier).state = true;

    return result;
  }

  @override
  ConsumerState<AnalysisLoadingOverlay> createState() => _AnalysisLoadingOverlayState();
}

class _AnalysisLoadingOverlayState extends ConsumerState<AnalysisLoadingOverlay>
  with SingleTickerProviderStateMixin {
  double _progress = 0.0;
  String _message = '분석 준비 중...';
  late AnimationController _tweenCtrl;
  late Animation<double> _tweenAnim;

  @override
  void initState() {
    super.initState();

    // 가장 느린 Edge Function 대기 구간 애니메이션 준비
    _tweenCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12)
    );
    _tweenAnim = Tween<double>(begin: 0.55, end: 0.90).animate(
      CurvedAnimation(parent: _tweenCtrl, curve: Curves.easeOut)
    )..addListener(() {
      if (_progress >= 0.55 && _progress < 0.90) {
        setState(() => _progress = _tweenAnim.value);
      }
    });

    // 분석 시작
    widget.taskBuilder(_onProgress).then((result) {
      _tweenCtrl.stop();
      setState(() {
        _progress = 1.0;
        _message = '분석이 완료되었어요!';
      });
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) widget.onComplete(result);
      });
    }).catchError((_) {
      if (mounted) widget.onComplete(null);
    });
  }

  void _onProgress(double progress, String message) {
    if (!mounted) return;
    setState(() {
      _progress = progress;
      _message = message;
    });

    if (progress >= 0.55 && !_tweenCtrl.isAnimating) {
      _tweenCtrl.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _tweenCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: AppColors.warmCream,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 16,
                offset: const Offset(0, 4)
              )
            ]
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.biotech_rounded, size: 48, color: AppColors.primaryBrown
              ),
              const SizedBox(height: 16),
              Text(
                '${widget.childName}의 영양 분석 중',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkGray
                )
              ),
              const SizedBox(height: 20),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: _progress),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                builder: (_, value, _) => Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: value,
                        minHeight: 8,
                        backgroundColor: AppColors.warmCream.withValues(alpha: 0.4),
                        color: AppColors.primaryBrown
                      )
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${(value * 100).toInt()}%',
                      style: const TextStyle(
                        fontSize: 12, color: AppColors.textMedium
                      )
                    )
                  ]
                )
              ),
              const SizedBox(height: 14),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  _message,
                  key: ValueKey(_message),
                  style: const TextStyle(
                    fontSize: 13, color: AppColors.textMedium
                  ),
                  textAlign: TextAlign.center
                )
              )
            ]
          )
        )
      )
    );
  }
}