import 'package:flutter/material.dart';

import '../design/tokens.dart';
import '../theme/app_theme.dart';

class MetricBadge extends StatelessWidget {
  const MetricBadge({
    super.key,
    required this.label,
    required this.value,
    this.color,
    this.child,
  });

  final String label;
  final String value;
  final Color? color;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.border),
      ),
      child: child != null
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                child!,
                Text(label, style: Theme.of(context).textTheme.labelMedium),
              ],
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(value, style: Theme.of(context).textTheme.headlineSmall),
                Text(label, style: Theme.of(context).textTheme.labelMedium),
              ],
            ),
    );
  }
}