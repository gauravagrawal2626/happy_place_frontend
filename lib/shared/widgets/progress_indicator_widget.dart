import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Progress Indicator Widget - Reusable Component
/// 
/// Simple progress bar for multi-step flows
/// Used in: Onboarding
class ProgressIndicatorWidget extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final double height;
  final Color? activeColor;
  final Color? inactiveColor;

  const ProgressIndicatorWidget({
    super.key,
    required this.progress,
    this.height = 4,
    this.activeColor,
    this.inactiveColor,
  });

  /// Factory constructor for step-based progress
  factory ProgressIndicatorWidget.fromSteps({
    Key? key,
    required int currentStep,
    required int totalSteps,
    double height = 4,
    Color? activeColor,
    Color? inactiveColor,
  }) {
    return ProgressIndicatorWidget(
      key: key,
      progress: totalSteps > 0 ? currentStep / totalSteps : 0,
      height: height,
      activeColor: activeColor,
      inactiveColor: inactiveColor,
    );
  }

  @override
  Widget build(BuildContext context) {
    final active = activeColor ?? AppColors.textDark;
    final inactive = inactiveColor ?? AppColors.textDark.withOpacity(0.15);
    final safeProgress = progress.clamp(0.0, 1.0);

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: inactive,
        borderRadius: BorderRadius.circular(height / 2),
      ),
      child: Row(
        children: [
          if (safeProgress > 0)
            Expanded(
              flex: (safeProgress * 100).toInt().clamp(1, 100),
              child: Container(
                decoration: BoxDecoration(
                  color: active,
                  borderRadius: BorderRadius.circular(height / 2),
                ),
              ),
            ),
          if (safeProgress < 1)
            Expanded(
              flex: ((1 - safeProgress) * 100).toInt().clamp(1, 100),
              child: const SizedBox(),
            ),
        ],
      ),
    );
  }
}
