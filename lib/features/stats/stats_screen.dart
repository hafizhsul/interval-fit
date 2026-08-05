import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../shared/design/tokens.dart';
import '../../shared/format.dart';
import '../../shared/theme/app_theme.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stat = ref.watch(_statsProvider);

    return Scaffold(
      body: stat.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load stats:\n$e')),
        data: (s) {
          if (s.totalWorkouts == 0) {
            return RefreshIndicator(
              onRefresh: () => ref.refresh(_statsProvider.future),
              child: const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.show_chart, size: 96, color: AppColors.onSurfaceDim),
                      SizedBox(height: AppSpacing.lg),
                      Text('No stats yet', style: TextStyle(fontSize: 20)),
                      SizedBox(height: AppSpacing.sm),
                      Text(
                        'Complete a workout to see your progress.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
  return RefreshIndicator(
        onRefresh: () => ref.refresh(_statsProvider.future),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.sm,
            ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Statistics',
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w800, color: AppColors.onSurface),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Your workout progress overview',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: AppColors.onSurfaceMute),
                  ),
                ],
              ),
            ),
            Expanded(child: _StatsBody(stat: s)),
          ],
        ),
      );
        },
      ),
    );
  }
}

final _statsProvider = FutureProvider.autoDispose<_SessionStat>((ref) async {
  ref.watch(workoutRefreshTrigger);
  final sessions = await ref.read(historyRepositoryProvider).getAll();
  int totalWorkouts = 0;
  int totalCompleted = 0;
  int totalSets = 0;
  Duration totalDuration = Duration.zero;
  Map<String, int> exerciseCount = {};
  String mostUsedExercise = '-';
  int mostCount = 0;

  for (final s in sessions) {
    totalWorkouts++;
    if (s.completed) totalCompleted++;
    totalSets += s.setsCompleted;
    totalDuration += Duration(seconds: s.durationSeconds);
    exerciseCount[s.exerciseType] = (exerciseCount[s.exerciseType] ?? 0) + 1;
  }

  for (final entry in exerciseCount.entries) {
    if (entry.value > mostCount) {
      mostCount = entry.value;
      mostUsedExercise = entry.key;
    }
  }

  return _SessionStat(
    totalWorkouts: totalWorkouts,
    totalCompleted: totalCompleted,
    totalSets: totalSets,
    totalDuration: totalDuration,
    mostUsedExercise: mostUsedExercise,
  );
});

class _SessionStat {
  final int totalWorkouts;
  final int totalCompleted;
  final int totalSets;
  final Duration totalDuration;
  final String mostUsedExercise;

  const _SessionStat({
    required this.totalWorkouts,
    required this.totalCompleted,
    required this.totalSets,
    required this.totalDuration,
    required this.mostUsedExercise,
  });
}

class _StatsBody extends StatelessWidget {
  const _StatsBody({required this.stat});

  final _SessionStat stat;

  @override
  Widget build(BuildContext context) {
    final completionRate = stat.totalWorkouts > 0
        ? ((stat.totalCompleted / stat.totalWorkouts) * 100).toStringAsFixed(0)
        : '0';

    return ListView(
      padding: EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.lg, AppSpacing.md, AppSpacing.xxl),
      children: [
        // Top row: 2 cards
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Total Workouts',
                value: '${stat.totalWorkouts}',
                icon: Icons.fitness_center,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _StatCard(
                label: 'Completion Rate',
                value: '$completionRate%',
                icon: Icons.check_circle_outline,
                color: AppColors.done,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        // Second row: 2 cards
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Total Sets',
                value: '${stat.totalSets}',
                icon: Icons.repeat,
                color: AppColors.rest,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _StatCard(
                label: 'Total Time',
                value: formatMmSs(stat.totalDuration.inSeconds),
                icon: Icons.timer_outlined,
                color: AppColors.warmup,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        // Favorite exercise card
        Card(
          margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          elevation: 0,
          color: AppColors.surfaceHigh,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            side: BorderSide(color: AppColors.border),
          ),
          child: InkWell(
            onTap: () {},
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Center(
                      child: Icon(Icons.trending_up, color: AppColors.primary, size: 28),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Favorite Exercise',
                          style: Theme.of(context).textTheme.titleLarge,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          stat.mostUsedExercise.toUpperCase(),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      elevation: 0,
      color: AppColors.surfaceHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: AppSpacing.sm),
                Text(label, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              value,
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                color: color,
                fontSize: 32,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
