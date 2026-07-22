import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/models/workout_session.dart';
import '../../shared/format.dart';

/// Provider lokal file ini (tidak menyentuh providers.dart, sesuai batasan).
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
      appBar: AppBar(title: const Text('History')),
      body: history.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load history:\n$e')),
        data: (list) {
          if (list.isEmpty) {
            return const Center(child: Text('No workout history yet.'));
          }
          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (context, i) => _SessionTile(session: list[i]),
          );
        },
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({required this.session});

  final WorkoutSession session;

  @override
  Widget build(BuildContext context) {
    final date =
        DateTime.fromMillisecondsSinceEpoch(session.startedAt).toLocal();
    final dateStr = '${date.year}-${_pad(date.month)}-${_pad(date.day)} '
        '${_pad(date.hour)}:${_pad(date.minute)}';
    return ListTile(
      title: Text(session.templateName),
      subtitle: Text(
        '$dateStr · ${formatMmSs(session.durationSeconds)} · '
        '${session.setsCompleted}/${session.setsPlanned} set',
      ),
      trailing: Chip(
        label: Text(session.completed ? 'Completed' : 'Partial'),
        backgroundColor: session.completed
            ? Colors.green.withValues(alpha: 0.3)
            : Colors.orange.withValues(alpha: 0.3),
      ),
    );
  }

  String _pad(int n) => n.toString().padLeft(2, '0');
}
