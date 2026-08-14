import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:interval_fit/core/providers.dart';
import 'package:interval_fit/core/settings_service.dart';
import 'package:interval_fit/core/voice_service.dart';
import 'package:interval_fit/features/settings/settings_screen.dart';
import 'package:interval_fit/shared/theme/app_theme.dart';

void main() {
  testWidgets('theme segmented control updates and persists each mode', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final settings = SettingsService(prefs);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsServiceProvider.overrideWithValue(settings),
          voiceServiceProvider.overrideWithValue(VoiceService(enabled: false)),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            final mode = ref.watch(themeModeProvider);
            AppColors.setLight(mode == ThemeMode.light);
            return MaterialApp(
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: mode,
              home: const SettingsScreen(),
            );
          },
        ),
      ),
    );

    // Legacy default: no theme_mode key -> dark (old v1.1.x behavior).
    expect(
      tester
          .widget<SegmentedButton<ThemeMode>>(
            find.byType(SegmentedButton<ThemeMode>),
          )
          .selected,
      {ThemeMode.dark},
    );

    // Light.
    await tester.tap(find.text('Light'));
    await tester.pumpAndSettle();
    expect(prefs.getString('theme_mode'), 'light');
    expect(prefs.containsKey('dark_theme'), isFalse);
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.light,
    );

    // System.
    await tester.tap(find.text('System'));
    await tester.pumpAndSettle();
    expect(prefs.getString('theme_mode'), 'system');
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.system,
    );
  });

  test('SettingsService migrates legacy dark_theme boolean', () {
    SharedPreferences.setMockInitialValues({'dark_theme': false});
    return SharedPreferences.getInstance().then((prefs) {
      final settings = SettingsService(prefs);
      expect(settings.themeMode, ThemeMode.light);
      // New write removes the legacy key so it can't override.
      return settings.setThemeMode(ThemeMode.system).then((_) {
        expect(settings.themeMode, ThemeMode.system);
        expect(prefs.containsKey('dark_theme'), isFalse);
        expect(prefs.getString('theme_mode'), 'system');
      });
    });
  });
}
