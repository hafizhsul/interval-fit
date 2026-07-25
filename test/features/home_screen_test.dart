import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:interval_fit/core/providers.dart';
import 'package:interval_fit/core/settings_service.dart';
import 'package:interval_fit/core/voice_service.dart';
import 'package:interval_fit/data/models/workout_template.dart';
import 'package:interval_fit/features/home/home_screen.dart';
import 'package:interval_fit/shared/theme/app_theme.dart';

WorkoutTemplate _tpl(String name) => WorkoutTemplate(
      name: name,
      exerciseType: 'skipping',
      sets: 5,
      workSeconds: 30,
      restSeconds: 15,
      createdAt: 0,
    );

Future<SharedPreferences> _prefs() async {
  SharedPreferences.setMockInitialValues({});
  return SharedPreferences.getInstance();
}

void main() {
  testWidgets('HomeScreen renders template list', (tester) async {
    final prefs = await _prefs();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          templateListProvider.overrideWith(
            (ref) async => [_tpl('Lari Pagi'), _tpl('Skipping HIIT')],
          ),
          sharedPrefsProvider.overrideWithValue(prefs),
          settingsServiceProvider.overrideWith(
            (ref) => SettingsService(prefs),
          ),
          voiceServiceProvider.overrideWith(
            (ref) => VoiceService(enabled: false),
          ),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Lari Pagi'), findsOneWidget);
    expect(find.text('Skipping HIIT'), findsOneWidget);
    // Summary format.
    expect(find.textContaining('5 set'), findsWidgets);
  });

  testWidgets('HomeScreen shows empty state', (tester) async {
    final prefs = await _prefs();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          templateListProvider.overrideWith((ref) async => []),
          sharedPrefsProvider.overrideWithValue(prefs),
          settingsServiceProvider.overrideWith(
            (ref) => SettingsService(prefs),
          ),
          voiceServiceProvider.overrideWith(
            (ref) => VoiceService(enabled: false),
          ),
        ],
        child: MaterialApp(theme: AppTheme.dark, home: const HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('No templates yet'), findsOneWidget);
  });
}
