import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/providers.dart';
import '../../data/models/workout_session.dart';
import '../../shared/design/tokens.dart';
import '../../shared/format.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/athletic_card.dart';
import '../../shared/widgets/metric_badge.dart';

final _historyProvider =
    FutureProvider.autoDispose<List<WorkoutSession>>((ref) {
  return ref.watch(historyRepositoryProvider).getAll();
});

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(_historyProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text('History', style: Theme.of(context).textTheme.headlineLarge),
      ),
      body: history.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load history:\n$e')),
        data: (list) {
          if (list.isEmpty) return const _EmptyState();
          return ListView.builder(
            padding: EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.lg, AppSpacing.md, AppSpacing.xxl),
            itemCount: list.length,
            itemBuilder: (context, i) => _SessionTile(session: list[i]),
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
            SvgPicture.asset(
              'assets/svg/history.svg',
              width: 96,
              height: 96,
              colorFilter: const ColorFilter.mode(AppColors.onSurfaceDim, BlendMode.srcIn),
            ),
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

IconData _sessionIcon(WorkoutSession session) {
  return session.completed ? Icons.check : Icons.pause;
}

String _formatDate(int epochMs) {
  final d = DateTime.fromMillisecondsSinceEpoch(epochMs).toLocal();
  return '${d.year}-${_pad(d.month)}-${_pad(d.day)} ${_pad(d.hour)}:${_pad(d.minute)}';
}

String _pad(int n) => n.toString().padLeft(2, '0');

class _SessionTile extends ConsumerWidget {
  const _SessionTile({required this.session});

  final WorkoutSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = _sessionColor(session);
    final icon = _sessionIcon(session);

    return AthleticCard(
      onTap: () {},
      accent: color,
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: AppColors.surfaceHigh,
        child: Icon(icon, color: color),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(session.templateName, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 2),
            Text(
              '${_formatDate(session.startedAt)} · ${formatMmSs(session.durationSeconds)} · ${session.setsCompleted}/${session.setsPlanned} set',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
      trailing: MetricBadge(
        label: session.completed ? 'Completed' : 'Partial',
        value: '',
        color: color,
      ),
    );
  }
}