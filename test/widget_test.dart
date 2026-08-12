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

final _templates = [
  WorkoutTemplate(
    id: 1,
    name: 'Morning Burn',
    exerciseType: 'skipping',
    sets: 8,
    workSeconds: 30,
    restSeconds: 15,
    createdAt: 1,
  ),
  WorkoutTemplate(
    id: 2,
    name: 'Evening Stretch',
    exerciseType: 'walk',
    sets: 6,
    workSeconds: 45,
    restSeconds: 20,
    createdAt: 2,
  ),
];

List<Override> _overrides() => [
  templateListProvider.overrideWith((ref) async => _templates),
];

void main() {
  testWidgets('App shell renders HomeScreen', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ..._overrides(),
          sharedPrefsProvider.overrideWithValue(prefs),
          settingsServiceProvider.overrideWith((ref) => SettingsService(prefs)),
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

  testWidgets('home dashboard guides users to start a workout', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ..._overrides(),
          sharedPrefsProvider.overrideWithValue(prefs),
          settingsServiceProvider.overrideWith((ref) => SettingsService(prefs)),
          voiceServiceProvider.overrideWith(
            (ref) => VoiceService(enabled: false),
          ),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // The home flow has one clear action path; no featured or weekly cards.
    expect(find.text('NEXT UP'), findsNothing);
    expect(find.text('THIS WEEK'), findsNothing);
    expect(find.text('Morning Burn'), findsOneWidget);
    expect(find.text('WORKOUTS'), findsOneWidget);
    expect(find.text('Pick a session'), findsOneWidget);
    expect(find.text('Start'), findsWidgets);
    await tester.dragUntilVisible(
      find.text('Evening Stretch'),
      find.byType(CustomScrollView),
      const Offset(0, -200),
    );
    expect(find.text('Evening Stretch'), findsOneWidget);
  });

  testWidgets('bottom navigation follows theme immediately', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final settings = SettingsService(prefs);
    final container = ProviderContainer(
      overrides: [
        ..._overrides(),
        settingsServiceProvider.overrideWithValue(settings),
        voiceServiceProvider.overrideWith(
          (ref) => VoiceService(enabled: false),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: Consumer(
          builder: (context, ref, _) {
            final mode = ref.watch(themeModeProvider);
            AppColors.setLight(mode == ThemeMode.light);
            return MaterialApp(
              theme: mode == ThemeMode.light ? AppTheme.light : AppTheme.dark,
              home: const HomeScreen(),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    final darkColor = tester.widget<Text>(find.text('History')).style!.color;
    container.read(themeModeProvider.notifier).state = ThemeMode.light;
    await tester.pumpAndSettle();

    expect(
      tester.widget<Text>(find.text('History')).style!.color,
      isNot(darkColor),
    );
  });
}
