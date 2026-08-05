import 'package:flutter/material.dart';

import '../../../data/models/workout_template.dart';
import '../../../shared/design/tokens.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/exercise_hero.dart';
import '../../active_workout/active_workout_screen.dart';

class WorkoutConfirmSheet extends StatelessWidget {
  const WorkoutConfirmSheet({super.key, required this.template});

  final WorkoutTemplate template;

  @override
  Widget build(BuildContext context) {
    final totalWork = template.sets * template.workSeconds;
    final totalRest = template.sets * template.restSeconds;
    final totalSeconds = totalWork + totalRest +
        template.warmupSeconds + template.cooldownSeconds +
        3; // get-ready seconds

    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    final estDuration = minutes > 0 ? '${minutes}m${seconds}s' : '${seconds}s';

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xxl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.onSurfaceMute.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ExerciseHero(exerciseType: template.exerciseType, color: AppColors.primary),
            const SizedBox(height: AppSpacing.md),
            Text(
              template.name,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _Row(label: 'Sets', value: '${template.sets}'),
            _Row(label: 'Work', value: '${template.workSeconds}s'),
            _Row(label: 'Rest', value: '${template.restSeconds}s'),
            if (template.warmupSeconds > 0)
              _Row(label: 'Warmup', value: '${template.warmupSeconds}s'),
            if (template.cooldownSeconds > 0)
              _Row(label: 'Cooldown', value: '${template.cooldownSeconds}s'),
            _Row(label: 'Est. Total', value: estDuration),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                backgroundColor: AppColors.primary,
              ),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ActiveWorkoutScreen(template: template),
                  ),
                );
              },
              child: const Text('Start Exercise', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: TextStyle(color: AppColors.onSurfaceMute)),
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.onSurfaceMute,
          )),
          Text(value, style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppColors.onSurface,
          )),
        ],
      ),
    );
  }
}
