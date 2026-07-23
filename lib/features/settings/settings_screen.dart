import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/providers.dart';
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
        title: Text('Settings', style: Theme.of(context).textTheme.headlineLarge),
      ),
      body: ListView(
        padding: EdgeInsets.all(AppSpacing.md),
        children: [
          SwitchListTile(
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
            activeColor: AppColors.primary,
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'About',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: SvgPicture.asset(
              'assets/svg/dumbbell.svg',
              width: 24,
              height: 24,
              colorFilter: const ColorFilter.mode(AppColors.onSurfaceMute, BlendMode.srcIn),
            ),
            title: Text('IntervalFit', style: Theme.of(context).textTheme.titleLarge),
            subtitle: Text('v1.0.0', style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}