import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/models/workout_session.dart';
import '../../data/models/health_data.dart';
import '../../shared/design/tokens.dart';
import '../../shared/format.dart';
import '../../shared/theme/app_theme.dart';

final _historyProvider = FutureProvider.autoDispose<List<WorkoutSession>>((ref) {
  ref.watch(workoutRefreshTrigger);
  return ref.watch(historyRepositoryProvider).getAll();
});

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(_historyProvider);
    return history.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load history:\n$e')),
        data: (list) {
          if (list.isEmpty) return const _EmptyState();
          return RefreshIndicator(
            onRefresh: () => ref.refresh(_historyProvider.future),
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
                        'History',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w800, color: AppColors.onSurface),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Past workout sessions',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: AppColors.onSurfaceMute),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      0,
                      AppSpacing.md,
                      AppSpacing.xxl,
                    ),
                    itemCount: list.length,
                    itemBuilder: (context, i) => _SessionTile(session: list[i]),
                  ),
                ),
              ],
            ),
          );
        },
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
        onTap: () => _showDetail(context, ref, session),
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

Future<void> _showDetail(
  BuildContext context,
  WidgetRef ref,
  WorkoutSession session,
) async {
  final healthForDate = ref.watch(
    healthForDateProvider(session.startedAt).future,
  );

  await showDialog(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: AppColors.surfaceHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: const BorderSide(color: AppColors.border),
      ),
      title: Text(
        session.templateName,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DetailRow(label: 'Date', value: _formatDate(session.startedAt)),
            const SizedBox(height: 8),
            _DetailRow(label: 'Exercise', value: session.exerciseType),
            const SizedBox(height: 8),
            _DetailRow(
              label: 'Sets',
              value: '${session.setsCompleted}/${session.setsPlanned}',
            ),
            const SizedBox(height: 8),
            _DetailRow(
              label: 'Duration',
              value: formatMmSs(session.durationSeconds),
            ),
            const SizedBox(height: 8),
            _DetailRow(
              label: 'Status',
              value: session.completed ? 'Completed' : 'Stopped',
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  session.completed ? Icons.check_circle : Icons.cancel,
                  size: 16,
                  color: session.completed ? AppColors.done : AppColors.work,
                ),
                const SizedBox(width: 4),
                Text(
                  session.completed ? 'Session completed' : 'Session stopped early',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: session.completed ? AppColors.done : AppColors.work,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Health Data',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            FutureBuilder<Map<String, double>>(
              future: healthForDate,
              builder: (context, snapshot) {
                final data = snapshot.data ?? const {};
                final steps = data[HealthRecordType.steps.name] ?? 0;
                final heartRate = data[HealthRecordType.heartRate.name] ?? 0;
                final calories =
                    data[HealthRecordType.activeEnergyBurned.name] ?? 0;

                return Column(
                  children: [
                    _DetailRow(
                      label: 'Steps',
                      value: steps == 0 ? '—' : '${steps.toInt()}',
                    ),
                    const SizedBox(height: 6),
                    _DetailRow(
                      label: 'Heart Rate',
                      value: heartRate == 0 ? '—' : '${heartRate.toInt()} bpm',
                    ),
                    const SizedBox(height: 6),
                    _DetailRow(
                      label: 'Calories',
                      value: calories == 0 ? '—' : '${calories.toInt()} kcal',
                    ),
                  ],
                );
              },
            ),
          ],
        ),
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurfaceMute,
                ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}
