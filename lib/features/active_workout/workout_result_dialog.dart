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
        side: const BorderSide(color: AppColors.border),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExerciseHero(exerciseType: exerciseType, color: accent),
          const SizedBox(height: AppSpacing.md),
          Text(
            completed ? 'Workout Complete!' : 'Workout Stopped',
            style: TextStyle(
              fontFamily: 'BarlowCondensed',
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: accent,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            templateName,
            style: const TextStyle(
              color: AppColors.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _row(Icons.timer_outlined, 'Duration', formatMmSs(durationSeconds)),
          const SizedBox(height: AppSpacing.sm),
          _row(Icons.repeat, 'Sets', '$setsCompleted / $setsPlanned'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(foregroundColor: AppColors.primary),
          child: const Text('OK', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.onSurfaceMute),
        const SizedBox(width: AppSpacing.sm),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.onSurfaceMute,
            fontSize: 14,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.onSurface,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
