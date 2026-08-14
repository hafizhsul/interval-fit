import 'package:flutter/material.dart';

import '../../core/timer_engine.dart' show WorkoutPhase;
import '../design/tokens.dart';
import '../theme/app_theme.dart';

class PhasePill extends StatelessWidget {
  const PhasePill({super.key, required this.phase});

  final WorkoutPhase phase;

  static Color colorFor(WorkoutPhase p) {
    switch (p) {
      case WorkoutPhase.getReady:
        return AppColors.primary;
      case WorkoutPhase.work:
        return AppColors.work;
      case WorkoutPhase.rest:
        return AppColors.rest;
      case WorkoutPhase.warmup:
        return AppColors.warmup;
      case WorkoutPhase.cooldown:
        return AppColors.cooldown;
      case WorkoutPhase.done:
        return AppColors.done;
    }
  }

  static String labelFor(WorkoutPhase p) {
    switch (p) {
      case WorkoutPhase.getReady:
        return 'GET READY';
      case WorkoutPhase.work:
        return 'WORK';
      case WorkoutPhase.rest:
        return 'REST';
      case WorkoutPhase.warmup:
        return 'WARM-UP';
      case WorkoutPhase.cooldown:
        return 'COOLDOWN';
      case WorkoutPhase.done:
        return 'DONE!';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = colorFor(phase);
    return AnimatedContainer(
      duration: AppMotion.normal,
      curve: AppMotion.easing,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        labelFor(phase),
        style: TextStyle(
          fontFamily: 'Barlow',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 2,
          color: color,
        ),
      ),
    );
  }
}
