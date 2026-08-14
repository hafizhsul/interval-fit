import 'package:flutter/material.dart';

import '../design/tokens.dart';

class SegmentedProgress extends StatelessWidget {
  const SegmentedProgress({
    super.key,
    required this.total,
    required this.current,
    required this.color,
  });

  static const _maxSegments = 20;

  final int total;
  final int current;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (total <= 0) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    if (total > _maxSegments) {
      return Column(
        children: [
          LinearProgressIndicator(
            value: total > 0 ? (current - 1) / (total - 1) : 0,
            backgroundColor: scheme.outlineVariant,
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 4,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '$current / $total',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
              letterSpacing: 1,
            ),
          ),
        ],
      );
    }

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
                : scheme.outlineVariant,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }
}
