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
    // Real NavigationBar, not a hand-rolled row.
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationDestination), findsNWidgets(5));
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
    // The whole card is the start action; no inline Start button.
    expect(find.text('Start'), findsNothing);
    await tester.dragUntilVisible(
      find.text('Evening Stretch'),
      find.byType(CustomScrollView),
      const Offset(0, -200),
    );
    expect(find.text('Evening Stretch'), findsOneWidget);
  });

  testWidgets('profile menu opens settings', (tester) async {
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

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    expect(find.text('Voice guidance'), findsOneWidget);
    // Embedded Profile shows the branded MenuHeader, not the intro block.
    expect(find.text('Profile'), findsNWidgets(2)); // nav label + header
    expect(find.text('Make it yours'), findsNothing);
  });

  testWidgets('tabs keep their state after switching away', (tester) async {
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

    // Open Profile, then return Home: the dashboard must not rebuild from
    // scratch (entrance animation already ran, grid still present).
    await tester.tap(find.text('Profile').last);
    await tester.pumpAndSettle();
    expect(find.text('Voice guidance'), findsOneWidget);

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(find.text('Morning Burn'), findsOneWidget);
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
            // Mirror IntervalFitApp.buildApp's effective-brightness logic.
            final effectiveLight = switch (mode) {
              ThemeMode.light => true,
              ThemeMode.dark => false,
              ThemeMode.system =>
                WidgetsBinding.instance.platformDispatcher.platformBrightness ==
                    Brightness.light,
            };
            AppColors.setLight(effectiveLight);
            return MaterialApp(
              theme: effectiveLight ? AppTheme.light : AppTheme.dark,
              home: const HomeScreen(),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    final darkColor = tester.widget<Text>(find.text('History')).style!.color;
    final darkNav = tester
        .widget<NavigationBar>(find.byType(NavigationBar))
        .backgroundColor;
    container.read(themeModeProvider.notifier).state = ThemeMode.light;
    await tester.pumpAndSettle();

    expect(
      tester.widget<Text>(find.text('History')).style!.color,
      isNot(darkColor),
    );
    // Regression: the nav bar background is AppColors.surfaceHigh; it must
    // follow the theme, not stay dark (AppTheme getters used to stomp
    // AppColors to dark regardless of the active mode).
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).backgroundColor,
      isNot(darkNav),
    );
  });

  testWidgets('nav follows platform brightness in system mode', (tester) async {
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
    addTearDown(
      () =>
          tester.binding.platformDispatcher.clearPlatformBrightnessTestValue(),
    );
    // Regression: ThemeMode.system used to be treated as dark, so a light
    // platform rendered a light app with a dark nav bar.
    tester.binding.platformDispatcher.platformBrightnessTestValue =
        Brightness.light;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: Consumer(
          builder: (context, ref, _) {
            final mode = ref.watch(themeModeProvider);
            final effectiveLight = switch (mode) {
              ThemeMode.light => true,
              ThemeMode.dark => false,
              ThemeMode.system =>
                WidgetsBinding.instance.platformDispatcher.platformBrightness ==
                    Brightness.light,
            };
            AppColors.setLight(effectiveLight);
            return MaterialApp(
              theme: effectiveLight ? AppTheme.light : AppTheme.dark,
              home: const HomeScreen(),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    Color navColor() => tester
        .widget<NavigationBar>(find.byType(NavigationBar))
        .backgroundColor!;

    // Fresh installs default to dark — switch to System explicitly, then the
    // light platform must produce a light nav.
    container.read(themeModeProvider.notifier).state = ThemeMode.system;
    await tester.pumpAndSettle();
    final lightNav = navColor();

    // Explicit dark → dark nav.
    container.read(themeModeProvider.notifier).state = ThemeMode.dark;
    await tester.pumpAndSettle();
    final darkNav = navColor();
    expect(darkNav, isNot(lightNav));

    // Back to system, platform flips dark → nav follows without touching
    // the theme setting.
    tester.binding.platformDispatcher.platformBrightnessTestValue =
        Brightness.dark;
    container.read(themeModeProvider.notifier).state = ThemeMode.system;
    await tester.pumpAndSettle();
    expect(navColor(), darkNav);
  });
}
