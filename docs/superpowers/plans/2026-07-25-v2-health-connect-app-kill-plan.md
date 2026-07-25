# v2 Features Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship v2 features: confirmation bottom sheet, app-kill hardening, Health Connect integration.

**Architecture:** Three independent additions to existing v1 core. No architectural changes — each feature adds/modifies specific files without refactoring existing patterns.

**Tech Stack:** Flutter/Dart, Riverpod, sqflite, `health_connect` (new dep).

## Global Constraints

- `flutter analyze` must stay clean — no new warnings or errors
- All 45 existing tests must remain passing
- Follow existing code patterns (design tokens, theme, widget style)
- No new dependencies beyond `health_connect`

---

### Task 1: Confirmation Bottom Sheet

**Files:**
- Create: `lib/features/home/widgets/workout_confirm_sheet.dart`
- Modify: `lib/features/home/home_screen.dart:340-347`
- Test: `test/features/home/widgets/workout_confirm_sheet_test.dart`

**Interfaces:**
- Consumes: `WorkoutTemplate` from existing model (`lib/data/models/workout_template.dart`)
- Produces: `WorkoutConfirmSheet` widget — stateless, takes `WorkoutTemplate`, returns nothing (navigates on confirm)

- [ ] **Step 1: Create workout_confirm_sheet.dart**

```dart
import 'package:flutter/material.dart';

import '../../../data/models/workout_template.dart';
import '../../../shared/design/tokens.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/exercise_hero.dart';

class WorkoutConfirmSheet extends StatelessWidget {
  const WorkoutConfirmSheet({super.key, required this.template});

  final WorkoutTemplate template;

  @override
  Widget build(BuildContext context) {
    final totalWork = template.sets * template.workSeconds;
    final totalRest = template.sets * template.restSeconds;
    final totalSeconds = totalWork + totalRest +
        template.warmupSeconds + template.cooldownSeconds +
        3; // get-ready seconds

    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    final estDuration = minutes > 0 ? '${minutes}m${seconds}s' : '${seconds}s';

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 32,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.onSurfaceMute.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          ExerciseHero(exerciseType: template.exerciseType, color: AppColors.primary),
          const SizedBox(height: AppSpacing.md),
          Text(
            template.name,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _Row(label: 'Sets', value: '${template.sets}'),
          _Row(label: 'Work', value: '${template.workSeconds}s'),
          _Row(label: 'Rest', value: '${template.restSeconds}s'),
          if (template.warmupSeconds > 0)
            _Row(label: 'Warmup', value: '${template.warmupSeconds}s'),
          if (template.cooldownSeconds > 0)
            _Row(label: 'Cooldown', value: '${template.cooldownSeconds}s'),
          _Row(label: 'Est. Total', value: estDuration),
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              backgroundColor: AppColors.primary,
            ),
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ActiveWorkoutScreen(template: template),
                ),
              );
            },
            child: const Text('Mulai Latihan', style: TextStyle(fontSize: 16)),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Batal', style: TextStyle(color: AppColors.onSurfaceMute)),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.onSurfaceMute,
          )),
          Text(value, style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppColors.onSurface,
          )),
        ],
      ),
    );
  }
}
```

Note: import `'../../active_workout/active_workout_screen.dart'` for `ActiveWorkoutScreen`.

- [ ] **Step 2: Modify home_screen.dart onTap**

Replace lines 340-347 to show bottom sheet instead of pushing directly:

```dart
onTap: () async {
  await showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.surfaceHigh,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
    ),
    builder: (_) => WorkoutConfirmSheet(template: template),
  );
  if (!context.mounted) return;
  ref.read(workoutRefreshTrigger.notifier).state++;
  ref.invalidate(templateListProvider);
},
```

- [ ] **Step 3: Write test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:interval_fit/features/home/widgets/workout_confirm_sheet.dart';
import 'package:interval_fit/data/models/workout_template.dart';

void main() {
  final template = WorkoutTemplate(
    id: 1,
    name: 'Test Workout',
    exerciseType: 'skipping',
    sets: 10,
    workSeconds: 30,
    restSeconds: 30,
    warmupSeconds: 0,
    cooldownSeconds: 0,
    createdAt: 0,
  );

  testWidgets('shows template name and details', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: WorkoutConfirmSheet(template: template)),
    ));
    expect(find.text('Test Workout'), findsOneWidget);
    expect(find.text('10'), findsOneWidget);
    expect(find.text('30s'), findsNWidgets(2));
  });
}
```

- [ ] **Step 4: Verify tests pass**

- [ ] **Step 5: Run `flutter analyze` — clean**

---

### Task 2: Auto-Save on Lifecycle Events

**Files:**
- Modify: `lib/features/active_workout/active_workout_controller.dart` (add `saveProgress()`)
- Modify: `lib/features/active_workout/active_workout_screen.dart` (add `AppLifecycleListener`)

**Interfaces:**
- New: `ActiveWorkoutController.saveProgress()` — saves current progress without stopping engine

- [ ] **Step 1: Add saveProgress() to ActiveWorkoutController**

After line 89 (`_onState` method closing brace), add:

```dart
  /// Save current progress without stopping the engine.
  /// Called when app lifecycle indicates potential termination.
  Future<void> saveProgress() async {
    if (_saveFuture != null) return;
    final s = _engine.state.value;
    if (s.phase == WorkoutPhase.done) return;
    final setsCompleted = s.phase == WorkoutPhase.rest
        ? s.currentSet
        : (s.currentSet > 0 ? s.currentSet - 1 : 0);
    await _history.insertSession(WorkoutSession(
      templateId: _template.id,
      templateName: _template.name,
      exerciseType: _template.exerciseType,
      startedAt: _startedAtMs,
      durationSeconds: s.totalElapsedSeconds,
      setsPlanned: _template.sets,
      setsCompleted: setsCompleted,
      completed: false,
    ));
  }
```

- [ ] **Step 2: Add AppLifecycleListener to ActiveWorkoutScreen**

In `_ActiveWorkoutScreenState`, add field after `_popped` (line 30):
```dart
  late final AppLifecycleListener _lifecycleListener;
```

In `initState()` after `_controller.start()` (line 42):
```dart
    _lifecycleListener = AppLifecycleListener(
      onPause: () => _controller.saveProgress(),
      onDetach: () => _controller.saveProgress(),
    );
```

In `dispose()` before line 61 (`super.dispose()`):
```dart
    _lifecycleListener.dispose();
```

- [ ] **Step 3: Update test for `ActiveWorkoutController.saveProgress()`**

Add test to `test/features/active_workout_controller_test.dart`.

- [ ] **Step 4: Verify tests pass**

- [ ] **Step 5: Run `flutter analyze` — clean**

---

### Task 3: OEM Battery Optimization Hints

**Files:**
- Modify: `android/app/src/main/AndroidManifest.xml`
- Modify: `android/app/src/main/kotlin/com/intervalfit/interval_fit/MainActivity.kt`
- Modify: `lib/features/settings/settings_screen.dart`

- [ ] **Step 1: Add permission to AndroidManifest.xml**

After line 8 (`WAKE_LOCK`), add:
```xml
    <uses-permission android:name="android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS"/>
```

- [ ] **Step 2: Add battery method channel to MainActivity.kt**

Add new channel and import:
```kotlin
import android.content.Intent
```

After `private val channel = "intervalfit/notifications"` (line 16), add:
```kotlin
    private val batteryChannel = "intervalfit/battery"
```

Add to `setMethodCallHandler`:
```kotlin
                    "requestBattery" -> {
                        val intent = Intent(android.provider.Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                            data = android.net.Uri.parse("package:${context.packageName}")
                        }
                        startActivity(intent)
                        result.success(null)
                    }
```

- [ ] **Step 3: Add DArt utility function**

Create `lib/core/battery_hint.dart`:
```dart
import 'package:flutter/services.dart';

void requestBatteryOptimizationExemption() {
  try {
    const MethodChannel('intervalfit/battery').invokeMethod('requestBattery');
  } catch (_) {}
}
```

- [ ] **Step 4: Add UI to SettingsScreen**

After the voice toggle card (after line 84), add:
```dart
          const SizedBox(height: AppSpacing.md),
          Card(
            margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            elevation: 0,
            color: AppColors.surfaceHigh,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              side: const BorderSide(color: AppColors.border),
            ),
            child: ListTile(
              leading: Icon(Icons.battery_std, color: AppColors.onSurfaceMute, size: 24),
              title: Text('Battery Optimization',
                  style: Theme.of(context).textTheme.titleLarge),
              subtitle: Text('Keep timer running when phone is locked',
                  style: Theme.of(context).textTheme.bodyMedium),
              trailing: const Icon(Icons.chevron_right,
                  color: AppColors.onSurfaceMute, size: 20),
              onTap: requestBatteryOptimizationExemption,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
            ),
          ),
```

- [ ] **Step 5: Run `flutter analyze` — clean**

---

### Task 4: Health Connect Real Reads

**Files:**
- Modify: `pubspec.yaml` (add dependency)
- Modify: `lib/core/health_connect_service.dart` (replace stub)
- Modify: `lib/features/health/health_screen.dart` (handle edge cases)
- Modify: `lib/core/providers.dart` (add permission state provider)

**Interfaces:**
- Consumes: `health_connect` package API
- Produces: `HealthConnectService.fetchToday()` returns real data instead of `[]`

- [ ] **Step 1: Add dependency to pubspec.yaml**

After `flutter_svg: ^2.0.10+1` (line 53):
```yaml
  health_connect: ^2.0.0
```

Run `flutter pub get`.

- [ ] **Step 2: Rewrite health_connect_service.dart**

```dart
import 'package:health_connect/health_connect.dart';

import '../data/models/health_data.dart';
import '../data/repositories/health_repository.dart';

class HealthConnectService {
  HealthConnectService(this._repository);

  final HealthRepository _repository;
  final HealthConnect _hc = HealthConnect();

  Future<bool> isAvailable() async {
    try {
      return await _hc.isAvailable();
    } catch (_) {
      return false;
    }
  }

  Future<bool> requestPermissions() async {
    try {
      await _hc.requestPermissions([
        HealthRecordType.steps,
        HealthRecordType.heartRate,
        HealthRecordType.activeEnergyBurned,
      ]);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<HealthData>> fetchToday() async {
    try {
      final available = await isAvailable();
      if (!available) return [];

      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day);
      final end = start.add(const Duration(days: 1));

      final records = <HealthData>[];
      final types = [
        HealthRecordType.steps,
        HealthRecordType.heartRate,
        HealthRecordType.activeEnergyBurned,
      ];

      for (final type in types) {
        try {
          final result = await _hc.queryRecords(type, startTime: start, endTime: end);
          for (final r in result) {
            records.add(HealthData(
              type: _mapType(type),
              value: r.value?.toDouble() ?? 0,
              unit: _unitFor(type),
              startTime: r.startTime.millisecondsSinceEpoch,
              endTime: r.endTime.millisecondsSinceEpoch,
              syncedAt: DateTime.now().millisecondsSinceEpoch,
            ));
          }
        } catch (_) {
          // Record type not available on this device — skip
        }
      }
      return records;
    } catch (_) {
      return [];
    }
  }

  Future<void> syncToday() async {
    final records = await fetchToday();
    if (records.isEmpty) return;
    await _repository.deleteAll();
    await _repository.bulkInsert(records);
  }

  HealthData.HealthRecordType _mapType(HealthConnectRecordType t) {
    if (t == HealthRecordType.steps) return HealthData.HealthRecordType.steps;
    if (t == HealthRecordType.heartRate) return HealthData.HealthRecordType.heartRate;
    return HealthData.HealthRecordType.activeEnergyBurned;
  }

  String _unitFor(HealthConnectRecordType t) {
    if (t == HealthRecordType.steps) return 'steps';
    if (t == HealthRecordType.heartRate) return 'bpm';
    return 'kcal';
  }
}
```

Note: Adjust `HealthData.HealthRecordType` references — the existing enum is `HealthRecordType` (top-level), not nested. Use the existing import.

- [ ] **Step 3: Update health_screen.dart**

Replace the `build` method to check HC availability first:
```dart
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.watch(healthConnectServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Health Connect',
          style: TextStyle(
            fontFamily: 'BarlowCondensed',
            fontSize: 26,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: AppColors.onSurface,
          ),
        ),
      ),
      body: FutureBuilder<bool>(
        future: service.isAvailable(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.data != true) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.info_outline, size: 48, color: AppColors.onSurfaceMute),
                  const SizedBox(height: AppSpacing.md),
                  Text('Health Connect not installed',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: AppSpacing.sm),
                  Text('Install Google Health Connect to sync your activity data.',
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            );
          }
          return _healthDataView(context, ref, service);
        },
      ),
    );
  }

  Widget _healthDataView(BuildContext context, WidgetRef ref, HealthConnectService service) {
    final agg = service.getTodayAggregated();
    return FutureBuilder<Map<String, double>>(
      future: agg,
      builder: (context, snapshot) {
        // ... existing data display code from the current build method ...
        final data = snapshot.data ?? const {};
        // ... rest of the existing ListView code ...
      },
    );
  }
```

- [ ] **Step 4: Run `flutter pub get`**

- [ ] **Step 5: Run `flutter analyze` — clean**

- [ ] **Step 6: Run `flutter test` — 45+ tests passing**
