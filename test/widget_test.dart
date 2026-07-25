import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:interval_fit/core/providers.dart';
import 'package:interval_fit/core/settings_service.dart';
import 'package:interval_fit/core/voice_service.dart';
import 'package:interval_fit/features/home/home_screen.dart';

void main() {
  testWidgets('App shell renders HomeScreen', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
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
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
  });
}
