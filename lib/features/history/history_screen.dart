import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/models/workout_session.dart';
import '../../shared/design/tokens.dart';
import '../../shared/format.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/loading_skeleton.dart';
import '../../shared/widgets/menu_header.dart';

final _historyProvider = FutureProvider.autoDispose<List<WorkoutSession>>((
  ref,
) {
  ref.watch(workoutRefreshTrigger);
  return ref.watch(historyRepositoryProvider).getAll();
});

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(_historyProvider);
    return history.when(
      loading: () => const _HistorySkeleton(),
      error: (e, _) => Center(child: Text('Failed to load history:\n$e')),
      data: (sessions) {
        if (sessions.isEmpty) return const _EmptyState();
        return RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.surfaceHigh,
          onRefresh: () => ref.refresh(_historyProvider.future),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              const SliverToBoxAdapter(
                child: MenuHeader(
                  title: 'History',
                  subtitle: 'Your movement, one session at a time.',
                  icon: Icons.history_rounded,
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.lg,
                  ),
                  child: _HistorySummary(sessions: sessions),
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
                  child: MenuSectionTitle(label: 'SESSION VAULT'),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  0,
                  AppSpacing.md,
                  AppSpacing.xxl,
                ),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _SessionCard(
                      session: sessions[index],
                      onTap: () => _showDetail(context, sessions[index]),
                    ),
                    childCount: sessions.length,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: AppSpacing.sm,
                    mainAxisSpacing: AppSpacing.sm,
                    childAspectRatio: 0.8,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HistorySkeleton extends StatelessWidget {
  const _HistorySkeleton();

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
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.xxl,
          ),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (context, index) => const SkeletonBox(),
              childCount: 6,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: AppSpacing.sm,
              mainAxisSpacing: AppSpacing.sm,
              childAspectRatio: 0.8,
            ),
          ),
        ),
      ],
    );
  }
}

class _HistorySummary extends StatelessWidget {
  const _HistorySummary({required this.sessions});

  final List<WorkoutSession> sessions;

  @override
  Widget build(BuildContext context) {
    final completed = sessions.where((s) => s.completed).length;
    final minutes =
        sessions.fold<int>(0, (sum, s) => sum + s.durationSeconds) ~/ 60;
    final rate = ((completed / sessions.length) * 100).round();
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.surfaceHigh, AppColors.surface],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'YOUR RHYTHM',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.primary,
              letterSpacing: 1.8,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$completed',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontSize: 50,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'completed',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const Spacer(),
              _SummaryMetric(value: '$minutes', label: 'MIN'),
              const SizedBox(width: AppSpacing.md),
              _SummaryMetric(value: '$rate%', label: 'FINISH'),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'LAST 7 DAYS',
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(letterSpacing: 1.4),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: List.generate(7, (index) {
              final date = DateUtils.dateOnly(
                DateTime.now(),
              ).subtract(Duration(days: 6 - index));
              final count = sessions.where((session) {
                final d = DateUtils.dateOnly(
                  DateTime.fromMillisecondsSinceEpoch(
                    session.startedAt,
                  ).toLocal(),
                );
                return d == date;
              }).length;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: index == 6 ? 0 : AppSpacing.xs,
                  ),
                  child: Column(
                    children: [
                      Text(
                        _dayLabel(date),
                        style: Theme.of(
                          context,
                        ).textTheme.labelSmall?.copyWith(fontSize: 10),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 32,
                        decoration: BoxDecoration(
                          color: count == 0
                              ? AppColors.background
                              : AppColors.primary.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          border: Border.all(
                            color: count == 0
                                ? AppColors.border
                                : AppColors.primary,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            count == 0 ? '·' : '$count',
                            style: TextStyle(
                              color: count == 0
                                  ? AppColors.onSurfaceDim
                                  : AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(color: AppColors.primary),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 9),
        ),
      ],
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.session, required this.onTap});

  final WorkoutSession session;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tint = _tintFor(session.exerciseType);
    final status = session.completed ? AppColors.done : AppColors.warmup;
    final date = DateTime.fromMillisecondsSinceEpoch(
      session.startedAt,
    ).toLocal();
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: tint.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Center(
                      child: Image.asset(
                        _assetPath(session.exerciseType),
                        width: 27,
                        height: 27,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    session.completed
                        ? Icons.check_circle_rounded
                        : Icons.timelapse_rounded,
                    color: status,
                    size: 18,
                  ),
                ],
              ),
              const Spacer(),
              Text(
                session.templateName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontSize: 16),
              ),
              const SizedBox(height: 3),
              Text(
                session.exerciseType.toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: tint,
                  fontSize: 10,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Divider(height: 1, color: AppColors.border),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: 14,
                    color: AppColors.onSurfaceMute,
                  ),
                  const SizedBox(width: 3),
                  Expanded(
                    child: Text(
                      formatMmSs(session.durationSeconds),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  Text(
                    '${session.setsCompleted}/${session.setsPlanned}',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: status,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${date.month}/${date.day}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurfaceMute,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const MenuHeader(
          title: 'History',
          subtitle: 'Your movement, one session at a time.',
          icon: Icons.history_rounded,
        ),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
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
                      Icons.history_rounded,
                      size: 42,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'No history yet',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Finish a workout and your progress will live here.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
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

String _dayLabel(DateTime date) =>
    const ['', 'M', 'T', 'W', 'T', 'F', 'S', 'S'][date.weekday];

String _assetPath(String type) {
  switch (type) {
    case 'skipping':
      return 'assets/images/skipping.png';
    case 'walk':
      return 'assets/images/walk.png';
    case 'run':
      return 'assets/images/run.png';
    default:
      return 'assets/images/custom.png';
  }
}

Color _tintFor(String type) {
  switch (type) {
    case 'run':
      return AppColors.work;
    case 'walk':
      return AppColors.cooldown;
    case 'skipping':
      return AppColors.primary;
    default:
      return AppColors.rest;
  }
}

Future<void> _showDetail(BuildContext context, WorkoutSession session) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(session.templateName),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _DetailRow(label: 'Exercise', value: session.exerciseType),
          _DetailRow(
            label: 'Duration',
            value: formatMmSs(session.durationSeconds),
          ),
          _DetailRow(
            label: 'Sets',
            value: '${session.setsCompleted}/${session.setsPlanned}',
          ),
          _DetailRow(
            label: 'Status',
            value: session.completed ? 'Completed' : 'Stopped',
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Text(value, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}
