import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/providers.dart';
import '../../data/models/workout_template.dart';
import '../../shared/design/tokens.dart';
import '../../shared/format.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/athletic_card.dart';
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
        title: Text(
          'INTERVALFIT',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            color: AppColors.primary,
            letterSpacing: 2,
          ),
        ),
        actions: [
          IconButton(
            icon: SvgPicture.asset(
              'assets/svg/history.svg',
              width: 24,
              height: 24,
              colorFilter: const ColorFilter.mode(AppColors.onSurfaceMute, BlendMode.srcIn),
            ),
            tooltip: 'History',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const HistoryScreen()),
            ),
          ),
          IconButton(
            icon: SvgPicture.asset(
              'assets/svg/settings.svg',
              width: 24,
              height: 24,
              colorFilter: const ColorFilter.mode(AppColors.onSurfaceMute, BlendMode.srcIn),
            ),
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
            padding: EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.lg, AppSpacing.md, AppSpacing.xxl),
            itemCount: list.length,
            itemBuilder: (context, i) => _TemplateCard(template: list[i]),
          );
        },
      ),
      floatingActionButton: _NewTemplateFab(),
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
              'assets/svg/dumbbell.svg',
              width: 96,
              height: 96,
              colorFilter: const ColorFilter.mode(AppColors.onSurfaceDim, BlendMode.srcIn),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('No templates yet', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Tap the New Template button to create your first session.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

String _exerciseIconPath(String exerciseType) {
  switch (exerciseType) {
    case 'skipping':
      return 'assets/svg/skipping.svg';
    case 'walk':
      return 'assets/svg/walk.svg';
    case 'run':
      return 'assets/svg/run.svg';
    default:
      return 'assets/svg/custom.svg';
  }
}

Color _exerciseColor(String exerciseType) {
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
    final accent = _exerciseColor(template.exerciseType);
    final iconPath = _exerciseIconPath(template.exerciseType);
    final summary =
        '${template.sets} sets · ${shortDuration(template.workSeconds)} work / '
        '${shortDuration(template.restSeconds)} rest';

    return AthleticCard(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ActiveWorkoutScreen(template: template)),
      ),
      accent: accent,
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: AppColors.surfaceHigh,
        child: SvgPicture.asset(
          iconPath,
          width: 28,
          height: 28,
          colorFilter: ColorFilter.mode(accent, BlendMode.srcIn),
        ),
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (v) async {
          if (v == 'edit') {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => TemplateBuilderScreen(existing: template)),
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
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(template.name, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 2),
            Text(summary, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _NewTemplateFab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: 1.0,
      duration: AppMotion.fast,
      curve: AppMotion.easing,
      child: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const TemplateBuilderScreen()),
        ),
        icon: SvgPicture.asset(
          'assets/svg/plus.svg',
          width: 24,
          height: 24,
          colorFilter: const ColorFilter.mode(AppColors.background, BlendMode.srcIn),
        ),
        label: Text('New Template', style: Theme.of(context).textTheme.labelLarge),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.background,
      ),
    );
  }
}