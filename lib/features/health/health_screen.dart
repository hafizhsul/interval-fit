import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/health_data.dart';
import '../../shared/design/tokens.dart';
import '../../shared/theme/app_theme.dart';
import '../../core/providers.dart';
import '../../core/health_connect_service.dart';

class HealthScreen extends ConsumerWidget {
  const HealthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.watch(healthConnectServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Health Connect',
          style: TextStyle(
            fontFamily: 'BarlowCondensed',
            fontSize: 26,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: AppColors.onSurface,
          ),
        ),
      ),
      body: FutureBuilder<String>(
        future: _computeScreenState(service),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          switch (snap.data) {
            case 'notAvailable':
              return _notAvailableView(context);
            case 'noPermission':
              return _noPermissionView(context, service, ref);
            default:
              return _healthDataView(context, ref, service);
          }
        },
      ),
    );
  }

  Future<String> _computeScreenState(HealthConnectService service) async {
    if (!await service.isAvailable()) return 'notAvailable';
    if (!await service.hasPermission()) return 'noPermission';
    return 'ready';
  }

  Widget _notAvailableView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.info_outline, size: 48, color: AppColors.onSurfaceMute),
          const SizedBox(height: AppSpacing.md),
          Text('Health Connect not installed',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Text(
              'Install Google Health Connect from Google Play Store to sync your activity data.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }

  Widget _noPermissionView(BuildContext context, HealthConnectService service, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shield_outlined, size: 48, color: AppColors.onSurfaceMute),
          const SizedBox(height: AppSpacing.md),
          Text('Permission required',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Grant Health Connect permission to sync your activity data.',
            style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.lg),
          FilledButton.icon(
            onPressed: () async {
              await service.requestPermissions();
              if (context.mounted) {
                ref.invalidate(healthConnectServiceProvider);
              }
            },
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Grant permissions'),
          ),
        ],
      ),
    );
  }

  Widget _healthDataView(BuildContext context, WidgetRef ref, HealthConnectService service) {
    final agg = service.getTodayAggregated();
    return FutureBuilder<Map<String, double>>(
      future: agg,
      builder: (context, snapshot) {
        final data = snapshot.data ?? const {};
        final steps = data[HealthRecordType.steps.name] ?? 0;
        final heartRate = data[HealthRecordType.heartRate.name] ?? 0;
        final calories =
            data[HealthRecordType.activeEnergyBurned.name] ?? 0;

        return ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            _StatCard(
              title: 'Steps',
              value: '${steps.toInt()}',
              unit: 'steps',
              icon: Icons.directions_walk,
            ),
            const SizedBox(height: AppSpacing.sm),
            _StatCard(
              title: 'Heart Rate',
              value: heartRate == 0 ? '—' : '${heartRate.toInt()}',
              unit: 'bpm',
              icon: Icons.monitor_heart,
            ),
            const SizedBox(height: AppSpacing.sm),
            _StatCard(
              title: 'Calories',
              value: '${calories.toInt()}',
              unit: 'kcal',
              icon: Icons.local_fire_department,
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: () async {
                await service.syncToday();
                if (context.mounted) {
                  ref.invalidate(healthConnectServiceProvider);
                }
              },
              icon: const Icon(Icons.sync),
              label: const Text('Sync Now'),
            ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
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
      elevation: 0,
      color: AppColors.surfaceHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Icon(icon, size: 32, color: AppColors.primary),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.onSurfaceMute,
                        ),
                  ),
                  Text(
                    '$value $unit',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 20,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
