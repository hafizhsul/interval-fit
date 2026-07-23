import 'package:flutter/material.dart';

import '../design/tokens.dart';
import '../theme/app_theme.dart';

class MetricBadge extends StatelessWidget {
  const MetricBadge({
    super.key,
    required this.label,
    required this.value,
    this.color,
  });

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: const TextStyle(fontFamily: 'Barlow', fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.onSurface)),
          Text(label, style: const TextStyle(fontFamily: 'Barlow', fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1, color: AppColors.onSurfaceMute)),
        ],
      ),
    );
  }
}