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
    final totalSeconds =
        template.warmupSeconds +
        template.cooldownSeconds +
        3 +
        template.sets * (template.workSeconds + template.restSeconds);
    final total = _duration(totalSeconds);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.onSurfaceDim,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'READY WHEN YOU ARE',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.primary,
                        letterSpacing: 1.7,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      template.name,
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                  ],
                ),
              ),
              ExerciseHero(
                exerciseType: template.exerciseType,
                color: AppColors.primary,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'SESSION OVERVIEW',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.onSurfaceMute,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _Metric(label: 'SETS', value: '${template.sets}'),
                    ),
                    Expanded(
                      child: _Metric(
                        label: 'WORK',
                        value: '${template.workSeconds}s',
                      ),
                    ),
                    Expanded(
                      child: _Metric(
                        label: 'REST',
                        value: '${template.restSeconds}s',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Divider(color: AppColors.border),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Estimated total',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const Spacer(),
                    Text(
                      total,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ActiveWorkoutScreen(template: template),
                ),
              );
            },
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Start session'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
            ),
          ),
          Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Not now'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

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

String _duration(int seconds) {
  final minutes = seconds ~/ 60;
  final remainder = seconds % 60;
  return minutes == 0 ? '${remainder}s' : '${minutes}m ${remainder}s';
}
