import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/providers.dart';
import '../../data/models/workout_template.dart';
import '../../shared/design/tokens.dart';
import '../../shared/format.dart';
import '../../shared/theme/app_theme.dart';
import '../history/history_screen.dart';
import '../settings/settings_screen.dart';
import '../stats/stats_screen.dart';
import '../template_builder/template_builder_screen.dart';
import 'widgets/workout_confirm_sheet.dart';

class _NavPage {
  const _NavPage(this.label, this.iconPath);
  final String label;
  final String iconPath;
}

const _navPages = [
  _NavPage('Home', 'assets/svg/home.svg'),
  _NavPage('History', 'assets/svg/history.svg'),
  _NavPage('Stats', 'assets/svg/stats.svg'),
  _NavPage('Settings', 'assets/svg/settings.svg'),
];

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Image.asset(
          'assets/images/title-logo.png',
          width: 120,
          height: 32,
          fit: BoxFit.contain,
        ),
      ),
    body: IndexedStack(
      index: _index,
      children: const [
        _HomeList(),
        _HistoryPage(),
        _StatsPage(),
        _SettingsPage(),
      ],
    ),
    floatingActionButton: _CenterCreateButton(
      size: 56,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const TemplateBuilderScreen()),
      ),
    ),
  floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
  bottomNavigationBar: BottomAppBar(
    color: AppColors.surface,
    surfaceTintColor: AppColors.surface,
    elevation: 0,
    notchMargin: AppSpacing.sm,
    shape: const CircularNotchedRectangle(),
    child: SizedBox(
      height: 72,
      child: Row(
        children: [
          Expanded(
            child: _NavBarButton(
              iconPath: _navPages[0].iconPath,
              selected: _index == 0,
              onTap: () => setState(() => _index = 0),
            ),
          ),
          Expanded(
            child: _NavBarButton(
              iconPath: _navPages[1].iconPath,
              selected: _index == 1,
              onTap: () => setState(() => _index = 1),
            ),
          ),
          const SizedBox(width: 72),
          Expanded(
            child: _NavBarButton(
              iconPath: _navPages[2].iconPath,
              selected: _index == 2,
              onTap: () => setState(() => _index = 2),
            ),
          ),
          Expanded(
            child: _NavBarButton(
              iconPath: _navPages[3].iconPath,
              selected: _index == 3,
              onTap: () => setState(() => _index = 3),
            ),
          ),
        ],
      ),
    ),
  ),
);
}
}

class _NavBarButton extends StatelessWidget {
  const _NavBarButton({
    required this.iconPath,
    required this.selected,
    required this.onTap,
  });

  final String iconPath;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.onSurfaceMute;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        onTap: onTap,
        child: Center(
          child: SvgPicture.asset(
            iconPath,
            width: 26,
            height: 26,
            colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
          ),
        ),
      ),
    );
  }
}

class _CenterCreateButton extends StatelessWidget {
  const _CenterCreateButton({this.size = 72, required this.onTap});

  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: FloatingActionButton(
        shape: const CircleBorder(),
        backgroundColor: AppColors.primary,
        elevation: 6,
        onPressed: onTap,
        child: SvgPicture.asset(
          'assets/svg/plus.svg',
          width: 28,
          height: 28,
          colorFilter: const ColorFilter.mode(AppColors.background, BlendMode.srcIn),
        ),
      ),
    );
  }
}

class _HomeList extends ConsumerWidget {
  const _HomeList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templates = ref.watch(templateListProvider);
    return templates.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Failed to load templates:\n$e')),
      data: (list) {
        if (list.isEmpty) return const _EmptyState();
        return RefreshIndicator(
          onRefresh: () => ref.refresh(templateListProvider.future),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.xxl,
            ),
            itemCount: list.length,
            itemBuilder: (context, i) => _TemplateCard(template: list[i]),
          ),
        );
      },
    );
  }
}

class _HistoryPage extends StatelessWidget {
  const _HistoryPage();

  @override
  Widget build(BuildContext context) {
    return const HistoryScreen();
  }
}

class _StatsPage extends StatelessWidget {
  const _StatsPage();

  @override
  Widget build(BuildContext context) {
    return const StatsScreen();
  }
}

class _SettingsPage extends StatelessWidget {
  const _SettingsPage();

  @override
  Widget build(BuildContext context) {
    return const SettingsScreen();
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
              'Tap the + button to create your first session.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

String _exerciseAssetPath(String exerciseType) {
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
    final assetPath = _exerciseAssetPath(template.exerciseType);
    final workStr = shortDuration(template.workSeconds);
    final restStr = shortDuration(template.restSeconds);
    final estimated = formatTotalEstimate(
      template.sets,
      template.workSeconds,
      template.restSeconds,
      template.warmupSeconds,
      template.cooldownSeconds,
    );

    return Card(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      elevation: 0,
      color: AppColors.surfaceHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: () async {
          await showModalBottomSheet(
            context: context,
            backgroundColor: AppColors.surfaceHigh,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
            ),
            builder: (_) => WorkoutConfirmSheet(template: template),
          );
          if (!context.mounted) return;
          ref.read(workoutRefreshTrigger.notifier).state++;
          ref.invalidate(templateListProvider);
        },
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
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
                      template.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 17),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${template.sets} sets',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '· $workStr work / $restStr rest',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 13,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$estimated estimated',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.onSurfaceMute,
                                fontSize: 12,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<_CardAction>(
                icon: const Icon(Icons.more_vert, color: AppColors.onSurfaceMute, size: 20),
                padding: EdgeInsets.zero,
                onSelected: (action) async {
                  if (action == _CardAction.edit) {
                    if (context.mounted) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => TemplateBuilderScreen(existing: template),
                        ),
                      );
                    }
                  } else if (action == _CardAction.delete) {
                    if (context.mounted) {
                      await _confirmDelete(context, ref);
                    }
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: _CardAction.edit,
                    child: Text('Edit'),
                  ),
                  const PopupMenuItem(
                    value: _CardAction.delete,
                    child: Text('Delete'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _CardAction { edit, delete }
