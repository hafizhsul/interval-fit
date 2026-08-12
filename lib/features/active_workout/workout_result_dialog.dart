import 'package:flutter/material.dart';

import '../../shared/design/tokens.dart';
import '../../shared/format.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/exercise_hero.dart';

class WorkoutResultDialog extends StatelessWidget {
  const WorkoutResultDialog({
    super.key,
    required this.templateName,
    required this.exerciseType,
    required this.durationSeconds,
    required this.setsCompleted,
    required this.setsPlanned,
    required this.completed,
  });

  final String templateName;
  final String exerciseType;
  final int durationSeconds;
  final int setsCompleted;
  final int setsPlanned;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    final accent = completed ? AppColors.primary : AppColors.warmup;
    return AlertDialog(
      backgroundColor: AppColors.surfaceHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: AppColors.border),
      ),
      contentPadding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(
              completed ? Icons.check_rounded : Icons.pause_rounded,
              color: accent,
              size: 42,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            completed ? 'Session complete' : 'Session saved',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(color: accent),
          ),
          const SizedBox(height: 3),
          Text(
            templateName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          ExerciseHero(exerciseType: exerciseType, color: accent),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _ResultMetric(
                    label: 'TIME',
                    value: formatMmSs(durationSeconds),
                  ),
                ),
                Expanded(
                  child: _ResultMetric(
                    label: 'SETS',
                    value: '$setsCompleted/$setsPlanned',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Done'),
        ),
      ],
    );
  }
}

class _ResultMetric extends StatelessWidget {
  const _ResultMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 10),
        ),
        const SizedBox(height: 3),
        Text(value, style: Theme.of(context).textTheme.titleLarge),
      ],
    );
  }
}
