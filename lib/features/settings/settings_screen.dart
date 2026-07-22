import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';

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
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Voice guidance'),
            subtitle: const Text('Voice cues during countdown & phase changes'),
            value: _voiceEnabled,
            onChanged: (v) {
              setState(() => _voiceEnabled = v);
              settings.setVoiceEnabled(v);
              voice.setEnabled(v);
            },
          ),
        ],
      ),
    );
  }
}
