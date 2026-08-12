import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/background_service.dart';
import 'core/providers.dart';
import 'features/splash/splash_screen.dart';
import 'shared/theme/app_theme.dart';

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
  final overrides = await bootstrapOverrides();
  runApp(ProviderScope(overrides: overrides, child: const IntervalFitApp()));
}

class IntervalFitApp extends ConsumerWidget {
  const IntervalFitApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    AppColors.setLight(mode == ThemeMode.light);
    return MaterialApp(
      title: 'Interval Fit',
      theme: mode == ThemeMode.light ? AppTheme.light : AppTheme.dark,
      themeMode: ThemeMode.light,
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}
