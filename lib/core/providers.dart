import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../data/models/workout_template.dart';
import '../data/repositories/app_database.dart';
import '../data/repositories/health_repository.dart';
import '../data/repositories/history_repository.dart';
import '../data/repositories/template_repository.dart';
import 'health_connect_service.dart';
import 'settings_service.dart';
import 'voice_service.dart';

/// Provider hub. Async singletons (DB, prefs) di-`override` di main() setelah
/// di-await, supaya widget bisa `.read` tanpa FutureProvider di mana-mana.
/// ponytail: override-di-main lebih simpel dari nested FutureProvider.

final databaseProvider = Provider<Database>((ref) {
  throw UnimplementedError('override di main() setelah AppDatabase.instance()');
});

final sharedPrefsProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'override di main() setelah SharedPreferences.getInstance()',
  );
});

final settingsServiceProvider = Provider<SettingsService>(
  (ref) => SettingsService(ref.watch(sharedPrefsProvider)),
);

final themeModeProvider = StateProvider<ThemeMode>((ref) {
  final settings = ref.watch(settingsServiceProvider);
  return settings.themeMode;
});

final voiceServiceProvider = Provider<VoiceService>((ref) {
  final settings = ref.watch(settingsServiceProvider);
  final vs = VoiceService(enabled: settings.voiceEnabled);
  vs.init();
  return vs;
});

final templateRepositoryProvider = Provider<TemplateRepository>(
  (ref) => TemplateRepository(ref.watch(databaseProvider)),
);

final historyRepositoryProvider = Provider<HistoryRepository>(
  (ref) => HistoryRepository(ref.watch(databaseProvider)),
);

final healthRepositoryProvider = Provider<HealthRepository>(
  (ref) => HealthRepository(ref.watch(databaseProvider)),
);

final healthConnectServiceProvider = Provider<HealthConnectService>(
  (ref) => HealthConnectService(ref.watch(healthRepositoryProvider)),
);

/// Trigger a health data refresh.
final healthRefreshTrigger = StateProvider<int>((ref) => 0);

final healthForDateProvider = FutureProvider.family<Map<String, double>, int>((
  ref,
  epochMs,
) {
  final service = ref.watch(healthConnectServiceProvider);
  return service.getForDate(epochMs);
});

/// Daftar template untuk home. Auto-refresh via [refresh].
final templateListProvider = FutureProvider.autoDispose<List<WorkoutTemplate>>((
  ref,
) {
  return ref.watch(templateRepositoryProvider).getAll();
});

/// Increment to signal that a workout session was saved (FR-6).
/// History & Stats providers watch this so they re-fetch after workout.
final workoutRefreshTrigger = StateProvider<int>((ref) => 0);

/// Bootstrap: buka DB + prefs, kembalikan overrides untuk ProviderScope.
///
/// [onProgress] reports bootstrap milestones (0..1) so the splash can show
/// real loading progress instead of a fake timer.
Future<List<Override>> bootstrapOverrides({
  void Function(double)? onProgress,
}) async {
  final db = await AppDatabase.instance();
  onProgress?.call(0.4);
  final prefs = await SharedPreferences.getInstance();
  onProgress?.call(0.8);
  final overrides = [
    databaseProvider.overrideWithValue(db),
    sharedPrefsProvider.overrideWithValue(prefs),
  ];
  onProgress?.call(1.0);
  return overrides;
}
