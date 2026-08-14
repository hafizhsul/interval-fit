import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/health_connect_service.dart';
import '../../core/providers.dart';
import '../../data/models/health_data.dart';
import '../../shared/design/tokens.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/loading_skeleton.dart';
import '../../shared/widgets/menu_header.dart';

class HealthScreen extends ConsumerWidget {
  const HealthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.watch(healthConnectServiceProvider);
    return FutureBuilder<String>(
      future: _state(service),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _HealthSkeleton();
        }
        switch (snapshot.data) {
          case 'notAvailable':
            return _StateView(
              title: 'Health',
              subtitle: 'Connect the data behind your effort.',
              icon: Icons.info_outline_rounded,
              message: 'Install Google Health Connect to sync activity data.',
            );
          case 'noPermission':
            return _PermissionView(service: service, ref: ref);
          default:
            return _DataView(service: service, ref: ref);
        }
      },
    );
  }

  Future<String> _state(HealthConnectService service) async {
    if (!await service.isAvailable()) return 'notAvailable';
    if (!await service.hasPermission()) return 'noPermission';
    return 'ready';
  }
}

class _HealthSkeleton extends StatelessWidget {
  const _HealthSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
      children: [
        const SkeletonMenuHeader(),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.lg,
          ),
          child: const SkeletonBox(height: 44, radius: AppRadius.md),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          child: SkeletonBox(width: 72, height: 14),
        ),
        const _HealthMetricSkeleton(),
        const _HealthMetricSkeleton(),
        const _HealthMetricSkeleton(),
      ],
    );
  }
}

class _HealthMetricSkeleton extends StatelessWidget {
  const _HealthMetricSkeleton();

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: const [
            SkeletonBox(width: 30, height: 30, radius: AppRadius.pill),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: 92, height: 16),
                  SizedBox(height: 8),
                  SkeletonBox(width: 128, height: 20),
                ],
              ),
            ),
            SkeletonBox(width: 24, height: 24, radius: AppRadius.pill),
          ],
        ),
      ),
    );
  }
}

class _HealthDataSkeleton extends StatelessWidget {
  const _HealthDataSkeleton();

  @override
  Widget build(BuildContext context) {
    return const _HealthSkeleton();
  }
}

class _DataView extends StatelessWidget {
  const _DataView({required this.service, required this.ref});

  final HealthConnectService service;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, double>>(
      future: service.getTodayAggregated(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _HealthDataSkeleton();
        }
        final data = snapshot.data ?? const <String, double>{};
        final steps = data[HealthRecordType.steps.name] ?? 0;
        final heart = data[HealthRecordType.heartRate.name] ?? 0;
        final calories = data[HealthRecordType.activeEnergyBurned.name] ?? 0;
        return ListView(
          padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
          children: [
            const MenuHeader(
              title: 'Health',
              subtitle: 'Today\'s activity and recovery signals.',
              icon: Icons.favorite_rounded,
              color: AppColors.cooldown,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.lg,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: AppColors.cooldown.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: AppColors.cooldown.withValues(alpha: 0.3),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.cooldown,
                      size: 18,
                    ),
                    SizedBox(width: AppSpacing.sm),
                    Text(
                      'CONNECTED',
                      style: TextStyle(
                        color: AppColors.cooldown,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: MenuSectionTitle(label: 'TODAY'),
            ),
            _HealthMetric(
              title: 'Steps',
              value: '${steps.toInt()}',
              unit: 'steps',
              icon: Icons.directions_walk_rounded,
            ),
            _HealthMetric(
              title: 'Heart rate',
              value: heart == 0 ? '--' : '${heart.toInt()}',
              unit: 'bpm',
              icon: Icons.monitor_heart_rounded,
            ),
            _HealthMetric(
              title: 'Calories',
              value: '${calories.toInt()}',
              unit: 'kcal',
              icon: Icons.local_fire_department_rounded,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                0,
              ),
              child: FilledButton.icon(
                onPressed: () async {
                  await service.syncToday();
                  ref.invalidate(healthConnectServiceProvider);
                },
                icon: const Icon(Icons.sync_rounded),
                label: const Text('Sync now'),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _HealthMetric extends StatelessWidget {
  const _HealthMetric({
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
  });

  final String title;
  final String value;
  final String unit;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary, size: 30),
        title: Text(title),
        subtitle: Text(
          '$value $unit',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        trailing: const Icon(Icons.insights_rounded),
      ),
    );
  }
}

class _PermissionView extends StatelessWidget {
  const _PermissionView({required this.service, required this.ref});

  final HealthConnectService service;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return _StateView(
      title: 'Health',
      subtitle: 'Connect the data behind your effort.',
      icon: Icons.shield_outlined,
      message: 'Grant Health Connect permission to sync activity data.',
      action: FilledButton.icon(
        onPressed: () async {
          await service.requestPermissions();
          ref.invalidate(healthConnectServiceProvider);
        },
        icon: const Icon(Icons.check_circle_outline),
        label: const Text('Grant permissions'),
      ),
    );
  }
}

class _StateView extends StatelessWidget {
  const _StateView({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.message,
    this.action,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        MenuHeader(
          title: title,
          subtitle: subtitle,
          icon: icon,
          color: AppColors.cooldown,
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
                      color: AppColors.cooldown.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 42, color: AppColors.cooldown),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  if (action != null) ...[
                    const SizedBox(height: AppSpacing.lg),
                    action!,
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
