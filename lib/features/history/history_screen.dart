import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/models/workout_session.dart';
import '../../shared/design/tokens.dart';
import '../../shared/format.dart';
import '../../shared/theme/app_theme.dart';

final _historyProvider =
    FutureProvider.autoDispose<List<WorkoutSession>>((ref) {
  ref.watch(workoutRefreshTrigger);
  return ref.watch(historyRepositoryProvider).getAll();
});

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(_historyProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'History',
          style: TextStyle(
            fontFamily: 'BarlowCondensed',
            fontSize: 26,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: AppColors.onSurface,
          ),
        ),
      ),
      body: history.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load history:\n$e')),
        data: (list) {
          if (list.isEmpty) return const _EmptyState();
          return RefreshIndicator(
            onRefresh: () => ref.refresh(_historyProvider.future),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.xxl,
              ),
              itemCount: list.length,
              itemBuilder: (context, i) => _SessionTile(session: list[i]),
            ),
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history, size: 96, color: AppColors.onSurfaceDim),
            const SizedBox(height: AppSpacing.lg),
            Text('No history yet', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Complete a workout to see it here.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

Color _sessionColor(WorkoutSession session) {
  return session.completed ? AppColors.done : AppColors.warmup;
}

String _assetPath(String exerciseType) {
  switch (exerciseType) {
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

String _formatDate(int epochMs) {
  final d = DateTime.fromMillisecondsSinceEpoch(epochMs).toLocal();
  return '${d.year}-${_pad(d.month)}-${_pad(d.day)} ${_pad(d.hour)}:${_pad(d.minute)}';
}

String _pad(int n) => n.toString().padLeft(2, '0');

Color? _tintFor(String exerciseType) {
  switch (exerciseType) {
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

class _SessionTile extends ConsumerWidget {
  const _SessionTile({required this.session});

  final WorkoutSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = _sessionColor(session);
    final tint = _tintFor(session.exerciseType) ?? color;
    final assetPath = _assetPath(session.exerciseType);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      elevation: 0,
      color: AppColors.surfaceHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Center(
                  child: Image.asset(
                    assetPath,
                    width: 28,
                    height: 28,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      session.templateName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 17),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_formatDate(session.startedAt)} · ${formatMmSs(session.durationSeconds)} · ${session.setsCompleted}/${session.setsPlanned} set',
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppColors.onSurfaceMute, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
