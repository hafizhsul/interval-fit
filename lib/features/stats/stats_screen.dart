import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../shared/design/tokens.dart';
import '../../shared/format.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/loading_skeleton.dart';
import '../../shared/widgets/menu_header.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(_statsProvider);
    return stats.when(
      loading: () => const _StatsSkeleton(),
      error: (e, _) => Center(child: Text('Failed to load stats:\n$e')),
      data: (stat) => RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => ref.refresh(_statsProvider.future),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            const SliverToBoxAdapter(
              child: MenuHeader(
                title: 'Stats',
                subtitle: 'See the work add up.',
                icon: Icons.insights_rounded,
              ),
            ),
            if (stat.totalWorkouts == 0)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyState(),
              )
            else ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.lg,
                  ),
                  child: _ScoreCard(stat: stat),
                ),
              ),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    0,
                    AppSpacing.md,
                    AppSpacing.sm,
                  ),
                  child: MenuSectionTitle(label: 'THE NUMBERS'),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                sliver: SliverGrid(
                  delegate: SliverChildListDelegate([
                    _MetricCard(
                      label: 'WORKOUTS',
                      value: '${stat.totalWorkouts}',
                      icon: Icons.fitness_center_rounded,
                      color: AppColors.primary,
                    ),
                    _MetricCard(
                      label: 'SETS',
                      value: '${stat.totalSets}',
                      icon: Icons.repeat_rounded,
                      color: AppColors.rest,
                    ),
                    _MetricCard(
                      label: 'ACTIVE TIME',
                      value: formatMmSs(stat.totalDuration.inSeconds),
                      icon: Icons.timer_outlined,
                      color: AppColors.warmup,
                    ),
                    _MetricCard(
                      label: 'BEST DAY',
                      value: '${stat.bestDay}',
                      icon: Icons.local_fire_department_rounded,
                      color: AppColors.work,
                    ),
                  ]),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: AppSpacing.sm,
                    mainAxisSpacing: AppSpacing.sm,
                    childAspectRatio: 1.25,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.sm,
                  ),
                  child: _WeeklyChart(values: stat.week),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    0,
                    AppSpacing.md,
                    AppSpacing.xxl,
                  ),
                  child: Card(
                    margin: EdgeInsets.zero,
                    child: ListTile(
                      leading: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: const Icon(
                          Icons.trending_up_rounded,
                          color: AppColors.primary,
                        ),
                      ),
                      title: const Text('Most used'),
                      subtitle: Text(
                        stat.favorite.toUpperCase(),
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                      trailing: const Icon(Icons.arrow_forward_rounded),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatsSkeleton extends StatelessWidget {
  const _StatsSkeleton();

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        const SliverToBoxAdapter(child: SkeletonMenuHeader()),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.lg,
            ),
            child: const SkeletonBox(height: 190, radius: AppRadius.lg),
          ),
        ),
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: SkeletonBox(width: 128, height: 14),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (context, index) => const SkeletonMetricCard(),
              childCount: 4,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: AppSpacing.sm,
              mainAxisSpacing: AppSpacing.sm,
              childAspectRatio: 1.25,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.xxl,
            ),
            child: const SkeletonBox(height: 190, radius: AppRadius.lg),
          ),
        ),
      ],
    );
  }
}

final _statsProvider = FutureProvider.autoDispose<_SessionStat>((ref) async {
  ref.watch(workoutRefreshTrigger);
  final sessions = await ref.read(historyRepositoryProvider).getAll();
  final counts = <String, int>{};
  final week = List<int>.filled(7, 0);
  final today = DateUtils.dateOnly(DateTime.now());
  var completed = 0;
  var sets = 0;
  var duration = Duration.zero;

  for (final session in sessions) {
    if (session.completed) completed++;
    sets += session.setsCompleted;
    duration += Duration(seconds: session.durationSeconds);
    counts[session.exerciseType] = (counts[session.exerciseType] ?? 0) + 1;
    final date = DateUtils.dateOnly(
      DateTime.fromMillisecondsSinceEpoch(session.startedAt).toLocal(),
    );
    final ago = today.difference(date).inDays;
    if (ago >= 0 && ago < 7) week[6 - ago]++;
  }

  var favorite = '-';
  var favoriteCount = 0;
  for (final entry in counts.entries) {
    if (entry.value > favoriteCount) {
      favorite = entry.key;
      favoriteCount = entry.value;
    }
  }
  return _SessionStat(
    totalWorkouts: sessions.length,
    completed: completed,
    totalSets: sets,
    totalDuration: duration,
    favorite: favorite,
    week: week,
  );
});

class _SessionStat {
  const _SessionStat({
    required this.totalWorkouts,
    required this.completed,
    required this.totalSets,
    required this.totalDuration,
    required this.favorite,
    required this.week,
  });

  final int totalWorkouts;
  final int completed;
  final int totalSets;
  final Duration totalDuration;
  final String favorite;
  final List<int> week;

  int get completion =>
      totalWorkouts == 0 ? 0 : ((completed / totalWorkouts) * 100).round();
  int get bestDay => week.fold(0, (best, value) => value > best ? value : best);
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({required this.stat});

  final _SessionStat stat;

  @override
  Widget build(BuildContext context) {
    final ink = AppColors.background;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.primary, AppColors.work]),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CONSISTENCY SCORE',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: ink.withValues(alpha: 0.7),
                        letterSpacing: 1.6,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${stat.completion}%',
                      style: Theme.of(context).textTheme.displayMedium
                          ?.copyWith(color: ink, fontSize: 58),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.insights_rounded,
                color: ink.withValues(alpha: 0.7),
                size: 42,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: stat.completion / 100,
              backgroundColor: ink.withValues(alpha: 0.18),
              valueColor: AlwaysStoppedAnimation<Color>(ink),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            stat.completion >= 80
                ? 'Strong rhythm. Keep showing up.'
                : 'Every session counts. Build your rhythm.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: ink.withValues(alpha: 0.78),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
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
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(color: color, fontSize: 27),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontSize: 10,
                letterSpacing: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeeklyChart extends StatelessWidget {
  const _WeeklyChart({required this.values});

  final List<int> values;

  @override
  Widget build(BuildContext context) {
    final max = values.fold(1, (best, value) => value > best ? value : best);
    final today = DateUtils.dateOnly(DateTime.now());
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'LAST 7 DAYS',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.primary,
                letterSpacing: 1.8,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 110,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(7, (index) {
                  final value = values[index];
                  final date = today.subtract(Duration(days: 6 - index));
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: index == 6 ? 0 : AppSpacing.sm,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            value == 0 ? '' : '$value',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: AppColors.primary,
                                  fontSize: 10,
                                ),
                          ),
                          const SizedBox(height: 3),
                          Container(
                            height: value == 0 ? 10 : 18 + (value / max) * 56,
                            decoration: BoxDecoration(
                              color: value == 0
                                  ? AppColors.border
                                  : AppColors.primary,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(AppRadius.sm),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _dayLabel(date),
                            style: Theme.of(
                              context,
                            ).textTheme.labelSmall?.copyWith(fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _dayLabel(DateTime date) =>
    const ['', 'M', 'T', 'W', 'T', 'F', 'S', 'S'][date.weekday];

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.insights_rounded,
              size: 42,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'No stats yet',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Complete a workout to see your progress build.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
