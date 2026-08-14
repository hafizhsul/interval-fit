import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/background_service.dart';
import 'core/providers.dart';
import 'features/home/home_screen.dart';
import 'features/splash/splash_screen.dart';
import 'shared/theme/app_theme.dart';
import 'shared/widgets/crash_guard.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Background service init & izin notifikasi tak boleh membrick startup:
  // kalau plugin/native gagal, app tetap harus sampai ke home (timer inti jalan
  // di UI-isolate; FGS hanya optimasi FR-4). Guard supaya crash di sini tidak
  // bikin force-close berulang tiap buka app.
  try {
    await BackgroundKeepAlive.init();
    // Minta izin notifikasi (Android 13+) sekali di startup. Tanpa ini, gate di
    // BackgroundKeepAlive.start() selalu gagal -> FGS tak pernah nyala (FR-4).
    await BackgroundKeepAlive.requestNotificationPermission();
  } catch (_) {
    // degradasi wajar — lanjut tanpa background service.
  }
  runApp(IntervalFitApp.root());
}

class IntervalFitApp {
  const IntervalFitApp._();

  /// Root widget: the splash MUST live inside a MaterialApp so its bare
  /// Scaffold has Directionality + MaterialLocalizations + a Navigator
  /// (pushReplacement in [_boot]). Without this shell the first frame throws
  /// "No Directionality widget found" on-device (widget tests masked it by
  /// wrapping the splash manually).
  ///
  /// Splash is a branded dark composition (AppColors defaults to dark before
  /// bootstrap); the post-bootstrap app re-themes from the persisted setting.
  /// [bootstrap] is injectable for tests; null uses the real DB+prefs loader.
  /// [splashBuilder] is a test seam that replaces the splash to simulate a
  /// build failure; the [CrashGuard] then falls back to [_BootToHome].
  static Widget root({Bootstrap? bootstrap, WidgetBuilder? splashBuilder}) {
    return MaterialApp(
      title: 'Interval Fit',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: CrashGuard(
        fallback: _BootToHome(bootstrap: bootstrap),
        child: splashBuilder == null
            ? SplashScreen(bootstrap: bootstrap, appBuilder: buildApp)
            : Builder(builder: splashBuilder),
      ),
    );
  }

  /// Full app tree for a resolved bootstrap: ProviderScope (with overrides)
  /// + MaterialApp. Theme mode is read from the provider, so it reflects the
  /// persisted setting immediately.
  static Widget buildApp(List<Override> overrides) {
    return ProviderScope(
      overrides: overrides,
      child: Consumer(
        builder: (context, ref, _) {
          final mode = ref.watch(themeModeProvider);
          // AppTheme.light/dark getters each call AppColors.setLight as a side
          // effect; evaluating both leaves AppColors on whichever ran last
          // (dark). Re-assert the EFFECTIVE brightness so AppColors matches
          // the theme the framework actually renders — otherwise the nav bar
          // (AppColors.surfaceHigh) stays dark while the rest of the UI is
          // light. System must resolve to the platform brightness, not to
          // dark (the old `mode == ThemeMode.light` treated System as dark).
          final theme = AppTheme.light;
          final darkTheme = AppTheme.dark;
          final effectiveLight = switch (mode) {
            ThemeMode.light => true,
            ThemeMode.dark => false,
            // No MediaQuery ancestor above MaterialApp — read the platform
            // brightness directly (test binding can override it).
            ThemeMode.system =>
              WidgetsBinding.instance.platformDispatcher.platformBrightness ==
                  Brightness.light,
          };
          AppColors.setLight(effectiveLight);
          return MaterialApp(
            title: 'Interval Fit',
            theme: theme,
            darkTheme: darkTheme,
            themeMode: mode,
            debugShowCheckedModeBanner: false,
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}

/// Crash-safe fallback shown when the splash itself fails to build: runs
/// bootstrap in the background, then renders the real app tree in place.
class _BootToHome extends StatefulWidget {
  const _BootToHome({this.bootstrap});

  final Bootstrap? bootstrap;

  @override
  State<_BootToHome> createState() => _BootToHomeState();
}

class _BootToHomeState extends State<_BootToHome> {
  List<Override>? _overrides;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    var overrides = <Override>[];
    try {
      overrides = await (widget.bootstrap ?? bootstrapOverrides)();
    } catch (_) {
      // Bootstrap failure: proceed with no overrides; DB-dependent providers
      // then throw on read and surface through the normal error path (the
      // CrashGuard already stopped intercepting, so no recovery loop).
    }
    if (!mounted) return;
    setState(() => _overrides = overrides);
  }

  @override
  Widget build(BuildContext context) {
    final overrides = _overrides;
    if (overrides == null) {
      // Brief branded blank while bootstrap runs — the splash already failed.
      return ColoredBox(color: AppColors.background);
    }
    return IntervalFitApp.buildApp(overrides);
  }
}
