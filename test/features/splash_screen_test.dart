import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:interval_fit/core/providers.dart';
import 'package:interval_fit/core/settings_service.dart';
import 'package:interval_fit/core/voice_service.dart';
import 'package:interval_fit/features/home/home_screen.dart';
import 'package:interval_fit/features/splash/splash_screen.dart';
import 'package:interval_fit/main.dart';

/// Instant bootstrap that reports the same milestones the real one does and
/// provides the providers HomeScreen needs after navigation.
Future<List<Override>> _fakeBootstrap({
  void Function(double progress)? onProgress,
}) async {
  onProgress?.call(0.4);
  onProgress?.call(0.8);
  final prefs = await SharedPreferences.getInstance();
  onProgress?.call(1.0);
  return [
    sharedPrefsProvider.overrideWithValue(prefs),
    settingsServiceProvider.overrideWith((ref) => SettingsService(prefs)),
    voiceServiceProvider.overrideWith((ref) => VoiceService(enabled: false)),
  ];
}

void main() {
  testWidgets('splash shows brand mark, wordmark and progress bar', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      MaterialApp(home: SplashScreen(bootstrap: _fakeBootstrap)),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      find
          .byType(Semantics)
          .evaluate()
          .any(
            (e) => (e.widget as Semantics).properties.label == 'Interval Fit',
          ),
      isTrue,
    );
    expect(find.text('LOADING YOUR WORKOUTS'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);

    // Run out the min-splash delay so no timers stay pending.
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
  });

  testWidgets('progress bar reflects bootstrap milestones', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      MaterialApp(home: SplashScreen(bootstrap: _fakeBootstrap)),
    );
    // Bootstrap is instant; the value tween takes 250ms. Check before the
    // min-splash delay (1100ms) triggers navigation.
    await tester.pump(const Duration(milliseconds: 400));

    final indicator = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(indicator.value, 1.0);

    await tester.pumpAndSettle(const Duration(milliseconds: 100));
  });

  testWidgets('splash navigates to home after bootstrap completes', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      MaterialApp(home: SplashScreen(bootstrap: _fakeBootstrap)),
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    expect(find.byType(HomeScreen), findsOneWidget);
  });

  // Regression: the real root (main.dart) runs the splash BARE — a Scaffold
  // with no MaterialApp ancestor throws "No Directionality widget found" on
  // first frame (seen on-device). IntervalFitApp.root() must supply the shell.
  testWidgets('real root renders splash and boots to home', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(IntervalFitApp.root(bootstrap: _fakeBootstrap));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('LOADING YOUR WORKOUTS'), findsOneWidget);

    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  // Crash-safety: if the splash build itself fails, the CrashGuard swaps to
  // the _BootToHome fallback, which bootstraps and renders HomeScreen in place
  // instead of leaving the framework's red error screen on screen.
  testWidgets('root falls back to home when the splash build fails', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      IntervalFitApp.root(
        bootstrap: _fakeBootstrap,
        splashBuilder: (context) => throw StateError('boom'),
      ),
    );

    // First frame: the splash build threw and was recorded.
    expect(tester.takeException(), isA<StateError>());

    // Recovery frame: the guard swaps to _BootToHome, bootstrap resolves with
    // the fake overrides, and the app tree renders HomeScreen.
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
