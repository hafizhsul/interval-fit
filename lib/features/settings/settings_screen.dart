import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/providers.dart';
import '../../core/battery_hint.dart';
import '../../shared/design/tokens.dart';
import '../../shared/theme/app_theme.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late bool _voiceEnabled;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsServiceProvider);
    _voiceEnabled = settings.voiceEnabled;
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.read(settingsServiceProvider);
    final voice = ref.read(voiceServiceProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(
            fontFamily: 'BarlowCondensed',
            fontSize: 26,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: AppColors.onSurface,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.xxl,
        ),
        children: [
          Card(
            margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            elevation: 0,
            color: AppColors.surfaceHigh,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              side: const BorderSide(color: AppColors.border),
            ),
            child: SwitchListTile(
              title: Text('Voice guidance', style: Theme.of(context).textTheme.titleLarge),
              subtitle: Text(
                'Voice cues during countdown & phase changes',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              secondary: SvgPicture.asset(
                'assets/svg/speaker.svg',
                width: 24,
                height: 24,
                colorFilter: const ColorFilter.mode(AppColors.onSurfaceMute, BlendMode.srcIn),
              ),
              value: _voiceEnabled,
              onChanged: (v) {
                setState(() => _voiceEnabled = v);
                settings.setVoiceEnabled(v);
                voice.setEnabled(v);
              },
              activeThumbColor: AppColors.primary,
              activeTrackColor: AppColors.primary.withValues(alpha: 0.3),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Card(
            margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            elevation: 0,
            color: AppColors.surfaceHigh,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              side: const BorderSide(color: AppColors.border),
            ),
            child: ListTile(
              leading: Icon(Icons.battery_std, color: AppColors.onSurfaceMute, size: 24),
              title: Text('Battery Optimization',
                  style: Theme.of(context).textTheme.titleLarge),
              subtitle: Text('Keep timer running when phone is locked',
                  style: Theme.of(context).textTheme.bodyMedium),
              trailing: const Icon(Icons.chevron_right,
                  color: AppColors.onSurfaceMute, size: 20),
              onTap: requestBatteryOptimizationExemption,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Card(
            margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            elevation: 0,
            color: AppColors.surfaceHigh,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              side: const BorderSide(color: AppColors.border),
            ),
            child: ListTile(
              leading: SvgPicture.asset(
                'assets/svg/dumbbell.svg',
                width: 24,
                height: 24,
                colorFilter: const ColorFilter.mode(AppColors.onSurfaceMute, BlendMode.srcIn),
              ),
              title: Text('Interval Fit', style: Theme.of(context).textTheme.titleLarge),
              subtitle: Text('v1.1.0', style: Theme.of(context).textTheme.bodyMedium),
              trailing: Icon(Icons.chevron_right, color: AppColors.onSurfaceMute, size: 20),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
