import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/models/workout_template.dart';
import '../../shared/format.dart';
import '../../shared/theme/app_theme.dart';
import '../active_workout/active_workout_screen.dart';
import '../history/history_screen.dart';
import '../settings/settings_screen.dart';
import '../template_builder/template_builder_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templates = ref.watch(templateListProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('INTERVALFIT'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'History',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const HistoryScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: templates.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load templates:\n$e')),
        data: (list) {
          if (list.isEmpty) return const _EmptyState();
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: list.length,
            itemBuilder: (context, i) => _TemplateCard(template: list[i]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const TemplateBuilderScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Template'),
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
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.fitness_center,
                size: 72, color: AppColors.primary.withValues(alpha: 0.7)),
            const SizedBox(height: 16),
            Text('No templates yet',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text('Tap the Template button to create your first session.',
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

/// Warna aksen kartu per jenis latihan (fungsional, bukan hiasan).
Color _accentFor(String exerciseType) {
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

IconData _iconFor(String exerciseType) {
  switch (exerciseType) {
    case 'run':
      return Icons.directions_run;
    case 'walk':
      return Icons.directions_walk;
    case 'skipping':
      return Icons.sports_gymnastics;
    default:
      return Icons.fitness_center;
  }
}

class _TemplateCard extends ConsumerWidget {
  const _TemplateCard({required this.template});

  final WorkoutTemplate template;

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete template?'),
        content: Text('"${template.name}" will be permanently deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.work),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(templateRepositoryProvider).delete(template.id!);
    ref.invalidate(templateListProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = _accentFor(template.exerciseType);
    final summary =
        '${template.sets} sets · ${shortDuration(template.workSeconds)} work / '
        '${shortDuration(template.restSeconds)} rest';
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ActiveWorkoutScreen(template: template),
          ),
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Strip aksen kiri — sinyal jenis latihan.
              Container(width: 6, color: accent),
              Padding(
                padding: const EdgeInsets.all(12),
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: accent.withValues(alpha: 0.18),
                  child: Icon(_iconFor(template.exerciseType), color: accent),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(template.name,
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 2),
                      Text(summary,
                          style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (v) async {
                  if (v == 'edit') {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            TemplateBuilderScreen(existing: template),
                      ),
                    );
                  } else if (v == 'delete') {
                    await _confirmDelete(context, ref);
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
