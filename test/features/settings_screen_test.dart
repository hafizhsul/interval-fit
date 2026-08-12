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
  testWidgets('appearance switch updates and persists light theme', (
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
              theme: mode == ThemeMode.light ? AppTheme.light : AppTheme.dark,
              themeMode: ThemeMode.light,
              home: const SettingsScreen(),
            );
          },
        ),
      ),
    );

    expect(find.text('Dark theme'), findsOneWidget);
    await tester.tap(find.byType(Switch).last);
    await tester.pumpAndSettle();

    expect(find.text('Bright and clear for daytime'), findsOneWidget);
    expect(prefs.getBool('dark_theme'), isFalse);
    expect(
      tester
          .widget<MaterialApp>(find.byType(MaterialApp))
          .theme!
          .scaffoldBackgroundColor,
      const Color(0xFFF7F4EF),
    );
  });
}
