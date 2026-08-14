import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/battery_hint.dart';
import '../../core/providers.dart';
import '../../shared/design/tokens.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/menu_header.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late bool _voiceEnabled;
  late ThemeMode _themeMode;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsServiceProvider);
    _voiceEnabled = settings.voiceEnabled;
    _themeMode = settings.themeMode;
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.read(settingsServiceProvider);
    final voice = ref.read(voiceServiceProvider);
    final content = ListView(
      padding: const EdgeInsets.fromLTRB(0, AppSpacing.sm, 0, AppSpacing.xxl),
      children: [
        if (widget.embedded)
          const MenuHeader(
            title: 'Profile',
            subtitle: 'Tune the experience to your rhythm.',
            icon: Icons.person_rounded,
          )
        else
          const _SettingsIntro(),

        const _SectionLabel('AUDIO'),
        _SettingsCard(
          child: SwitchListTile(
            title: const Text('Voice guidance'),
            subtitle: const Text('Cues during countdowns and phase changes'),
            secondary: SvgPicture.asset(
              'assets/svg/speaker.svg',
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(
                AppColors.onSurfaceMute,
                BlendMode.srcIn,
              ),
            ),
            value: _voiceEnabled,
            onChanged: (value) {
              setState(() => _voiceEnabled = value);
              settings.setVoiceEnabled(value);
              voice.setEnabled(value);
            },
          ),
        ),
        const _SectionLabel('APPEARANCE'),
        _SettingsCard(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Theme'),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Match your phone or pick a look.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.md),
                SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(
                      value: ThemeMode.system,
                      icon: Icon(Icons.brightness_auto_rounded),
                      label: Text('System'),
                    ),
                    ButtonSegment(
                      value: ThemeMode.light,
                      icon: Icon(Icons.light_mode_rounded),
                      label: Text('Light'),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      icon: Icon(Icons.dark_mode_rounded),
                      label: Text('Dark'),
                    ),
                  ],
                  selected: {_themeMode},
                  onSelectionChanged: (selection) async {
                    final mode = selection.first;
                    setState(() => _themeMode = mode);
                    ref.read(themeModeProvider.notifier).state = mode;
                    await settings.setThemeMode(mode);
                  },
                ),
              ],
            ),
          ),
        ),
        const _SectionLabel('DEVICE'),
        _SettingsCard(
          child: ListTile(
            leading: const Icon(Icons.battery_std_rounded),
            title: const Text('Battery optimization'),
            subtitle: const Text('Keep timer running when the phone is locked'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: requestBatteryOptimizationExemption,
          ),
        ),
        const _SectionLabel('ABOUT'),
        _SettingsCard(
          child: ListTile(
            leading: SvgPicture.asset(
              'assets/svg/dumbbell.svg',
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(
                AppColors.onSurfaceMute,
                BlendMode.srcIn,
              ),
            ),
            title: const Text('Interval Fit'),
            subtitle: const Text('v1.1.0'),
            trailing: const Icon(Icons.chevron_right_rounded),
          ),
        ),
      ],
    );
    if (widget.embedded) return content;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('Settings'),
      ),
      body: content,
    );
  }
}

class _SettingsIntro extends StatelessWidget {
  const _SettingsIntro();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Make it yours',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Tune the experience to your rhythm.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppColors.primary,
          letterSpacing: 1.8,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: child,
    );
  }
}
