import 'package:flutter/material.dart';

import '../design/tokens.dart';
import '../theme/app_theme.dart';

class SegmentedProgress extends StatelessWidget {
  const SegmentedProgress({
    super.key,
    required this.total,
    required this.current,
    required this.color,
  });

  final int total;
  final int current;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (total <= 0) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final isDone = i < current - 1;
        final isCurrent = i == current - 1;

        return AnimatedContainer(
          duration: AppMotion.normal,
          curve: AppMotion.easing,
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          width: 8,
          height: 4,
          decoration: BoxDecoration(
            color: isDone
                ? color
                : isCurrent
                    ? color.withValues(alpha: 0.6)
                    : AppColors.onSurfaceDim,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }
}