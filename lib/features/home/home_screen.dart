import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/providers.dart';
import '../../data/models/workout_template.dart';
import '../../shared/design/tokens.dart';
import '../../shared/format.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/loading_skeleton.dart';
import '../health/health_screen.dart';
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

class _TransparentTitleLogo extends StatelessWidget {
  const _TransparentTitleLogo();

  static const _dropBlack = ColorFilter.matrix([
    1,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
    0,
    1,
    1,
    1,
    0,
    0,
  ]);

  static const _fitBlack = ColorFilter.matrix([
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0.333,
    0.333,
    0.333,
    0,
    0,
  ]);

  static const _fitWhite = ColorFilter.matrix([
    0,
    0,
    0,
    0,
    255,
    0,
    0,
    0,
    0,
    255,
    0,
    0,
    0,
    0,
    255,
    0.333,
    0.333,
    0.333,
    0,
    0,
  ]);

  Widget _part({
    required Alignment alignment,
    required double heightFactor,
    required ColorFilter filter,
  }) {
    return ClipRect(
      child: Align(
        alignment: alignment,
        heightFactor: heightFactor,
        child: ColorFiltered(
          colorFilter: filter,
          child: Image.asset(
            'assets/images/title-logo.png',
            width: 118,
            height: 32,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final light = Theme.of(context).brightness == Brightness.light;
    return Semantics(
      label: 'Interval Fit',
      image: true,
      child: SizedBox(
        width: 118,
        height: 32,
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _part(
                alignment: Alignment.topCenter,
                heightFactor: 238 / 444,
                filter: _dropBlack,
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _part(
                alignment: Alignment.bottomCenter,
                heightFactor: 206 / 444,
                filter: light ? _fitBlack : _fitWhite,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _navPages = [
  _NavPage('Home', 'assets/svg/home.svg'),
  _NavPage('History', 'assets/svg/history.svg'),
  _NavPage('Stats', 'assets/svg/stats.svg'),
  _NavPage('Health', 'assets/svg/heart.svg'),
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
    ref.watch(themeModeProvider);
    return Scaffold(
      appBar: AppBar(
        titleSpacing: AppSpacing.md,
        title: const _TransparentTitleLogo(),
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: SvgPicture.asset(
              'assets/svg/settings.svg',
              width: 22,
              height: 22,
              colorFilter: ColorFilter.mode(
                AppColors.onSurfaceMute,
                BlendMode.srcIn,
              ),
            ),
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      body: _selectedPage(),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Create workout',
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(color: AppColors.background, width: 5),
        ),
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const TemplateBuilderScreen()),
        ),
        child: const Icon(Icons.add_rounded, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
          child: Container(
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.surfaceHigh,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.border),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(child: _navButton(0)),
                Expanded(child: _navButton(1)),
                const SizedBox(width: 70),
                Expanded(child: _navButton(2)),
                Expanded(child: _navButton(3)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _selectedPage() {
    switch (_index) {
      case 1:
        return const HistoryScreen();
      case 2:
        return const StatsScreen();
      case 3:
        return const HealthScreen();
      default:
        return const _HomeDashboard();
    }
  }

  Widget _navButton(int index) {
    final selected = _index == index;
    final color = selected ? AppColors.primary : AppColors.onSurfaceDim;
    return InkWell(
      onTap: () => setState(() => _index = index),
      splashFactory: NoSplash.splashFactory,
      child: Center(
        child: AnimatedContainer(
          duration: AppMotion.fast,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.13)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                _navPages[index].iconPath,
                width: 21,
                height: 21,
                colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
              ),
              const SizedBox(height: 4),
              Text(
                _navPages[index].label,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeDashboard extends ConsumerStatefulWidget {
  const _HomeDashboard();

  @override
  ConsumerState<_HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends ConsumerState<_HomeDashboard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: AppMotion.slow,
    )..forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  Animation<double> _entrance(double begin, double end) {
    return CurvedAnimation(
      parent: _entranceController,
      curve: Interval(begin, end, curve: AppMotion.easing),
    );
  }

  Future<void> _openWorkout(BuildContext context, WorkoutTemplate template) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceHigh,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) => WorkoutConfirmSheet(template: template),
    );
  }

  @override
  Widget build(BuildContext context) {
    final templates = ref.watch(templateListProvider);
    return templates.when(
      loading: () => const _HomeSkeleton(),
      error: (error, _) =>
          Center(child: Text('Failed to load templates:\n$error')),
      data: (list) {
        return RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.surfaceHigh,
          onRefresh: () => ref.refresh(templateListProvider.future),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              if (list.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyState(),
                )
              else ...[
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.md,
                    0,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: _DashboardEntrance(
                      animation: _entrance(0, 0.34),
                      child: const _Greeting(),
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
                    child: _DashboardEntrance(
                      animation: _entrance(0.18, 0.48),
                      child: _LibraryHeader(count: list.length),
                    ),
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
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final template = list[index];
                      final begin = (0.34 + index * 0.06)
                          .clamp(0.0, 0.78)
                          .toDouble();
                      return _DashboardEntrance(
                        animation: _entrance(
                          begin,
                          (begin + 0.24).clamp(0.0, 1.0),
                        ),
                        child: _TemplateCard(
                          template: template,
                          onTap: () => _openWorkout(context, template),
                        ),
                      );
                    }, childCount: list.length),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: AppSpacing.md,
                          mainAxisSpacing: AppSpacing.md,
                          childAspectRatio: 0.92,
                        ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            0,
          ),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SkeletonBox(width: 112, height: 12),
                SizedBox(height: AppSpacing.sm),
                SkeletonBox(width: 250, height: 72),
                SizedBox(height: AppSpacing.sm),
                SkeletonBox(width: 210, height: 16),
              ],
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
            child: Row(
              children: const [
                Expanded(
                  child: SkeletonBox(width: double.infinity, height: 30),
                ),
                SizedBox(width: AppSpacing.md),
                SkeletonBox(width: 52, height: 32),
              ],
            ),
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
              childCount: 4,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: AppSpacing.md,
              mainAxisSpacing: AppSpacing.md,
              childAspectRatio: 0.92,
            ),
          ),
        ),
      ],
    );
  }
}

class _DashboardEntrance extends StatelessWidget {
  const _DashboardEntrance({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.08),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting();

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _greeting.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.primary,
            letterSpacing: 2.2,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'What are you\ntraining today?',
          style: Theme.of(
            context,
          ).textTheme.headlineLarge?.copyWith(fontSize: 38, height: 0.98),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Pick a session. Press start. Build momentum.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _LibraryHeader extends StatelessWidget {
  const _LibraryHeader({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'WORKOUTS',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.primary,
                  letterSpacing: 1.8,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                count > 1 ? 'Pick a session' : 'Start your routine',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        TextButton.icon(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const TemplateBuilderScreen()),
          ),
          icon: const Icon(Icons.add, size: 17),
          label: const Text('New workout'),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 10),
          ),
        ),
      ],
    );
  }
}

class _TemplateCard extends ConsumerWidget {
  const _TemplateCard({required this.template, required this.onTap});

  final WorkoutTemplate template;
  final VoidCallback onTap;

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
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
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(templateRepositoryProvider).delete(template.id!);
    ref.invalidate(templateListProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = _exerciseColor(template.exerciseType);
    final estimated = formatTotalEstimate(
      template.sets,
      template.workSeconds,
      template.restSeconds,
      template.warmupSeconds,
      template.cooldownSeconds,
    );
    return Semantics(
      container: true,
      label:
          '${template.name}, ${template.sets} sets, estimated $estimated. Start workout.',
      child: Card(
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
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Center(child: _artwork(template.exerciseType)),
                    ),
                    const Spacer(),
                    PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.more_horiz),
                      color: AppColors.surfaceHigh,
                      onSelected: (value) {
                        if (value == 'edit') {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  TemplateBuilderScreen(existing: template),
                            ),
                          );
                        } else {
                          _delete(context, ref);
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  template.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  '${template.sets} SETS',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: accent,
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
                      Icons.schedule,
                      size: 14,
                      color: AppColors.onSurfaceMute,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        estimated,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: onTap,
                      icon: Icon(
                        Icons.play_arrow_rounded,
                        size: 16,
                        color: accent,
                      ),
                      label: Text('Start', style: TextStyle(color: accent)),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        minimumSize: const Size(0, 36),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
              ],
            ),
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
    return Center(
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
                Icons.fitness_center_rounded,
                size: 42,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'No templates yet',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Tap + to build your first interval session.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const TemplateBuilderScreen(),
                ),
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create first workout'),
              style: FilledButton.styleFrom(minimumSize: const Size(220, 52)),
            ),
          ],
        ),
      ),
    );
  }
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

Widget _artwork(String exerciseType, {double size = 30, Color? color}) {
  final image = Image.asset(
    _assetPath(exerciseType),
    width: size,
    height: size,
    fit: BoxFit.contain,
  );
  if (color == null) return image;
  return ColorFiltered(
    colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    child: image,
  );
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
