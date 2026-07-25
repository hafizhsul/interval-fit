# Spec — v2: Health Connect, App-Kill Hardening, Confirmation

## Scope

Three changes to ship after v1 core is complete:

1. **Confirmation bottom sheet** on template tap (HomeScreen)
2. **Health Connect real reads** via `health_connect` package
3. **App-kill hardening** — auto-save on lifecycle events + OEM battery hints

All three are small, independent changes. No architectural shifts.

---

## 1. Confirmation Bottom Sheet

### Problem
Tapping a template card navigates directly to ActiveWorkoutScreen and starts the 3-2-1 countdown immediately. User has no chance to review or cancel.

### Solution
Show a bottom sheet with workout summary before navigation.

### Flow
```
Tap template card → showModalBottomSheet() → user sees summary → 
  "Mulai Latihan" → Navigator.pop() + push ActiveWorkoutScreen
  "Batal" / dismiss → stay on HomeScreen
```

### UI (bottom sheet)
- Template name + exercise icon (SVG from existing `ExerciseHero`)
- Detail row: `N set × Xs kerja / Ys rest`
- Total duration: calculated from config
- Actions: primary "Mulai Latihan", secondary "Batal"
- Dismissible by swipe down

### Implementation
- Modify `home_screen.dart` `_TemplateCard.onTap`: replace `Navigator.push(ActiveWorkoutScreen(...))` with `showModalBottomSheet(context: context, builder: (_) => WorkoutConfirmSheet(template: template))`
- New widget `workout_confirm_sheet.dart` in `lib/features/home/widgets/`
- Duration calculation: reuse logic already in `ActiveWorkoutController` (`_buildSegments`)

### Files changed
- `lib/features/home/home_screen.dart` — onTap handler
- `lib/features/home/widgets/workout_confirm_sheet.dart` — new file

---

## 2. Health Connect Real Reads

### Problem
`HealthConnectService.fetchToday()` returns empty list (stub). Health tab shows nothing useful.

### Solution
Replace stub with real `health_connect` API calls. READ-only — never write to Health Connect.

### Package
`health_connect: ^2.0.0` (Google official)

### Data flow
```
Health tab opened / sync triggered
  → check HC availability (HealthConnect.isAvailable())
  → if unavailable: show "Install Google Health Connect" CTA
  → request permissions (steps, heartRate, activeEnergyBurned)
  → read records for today's date range
  → map to HealthData model (existing)
  → bulkInsert into local DB (existing repository)
  → display on Health tab (existing UI)
```

### Service changes
`health_connect_service.dart`:
- Add `_checkAvailability()` — return error state if not installed
- Add `_requestPermissions()` — request all three record types
- Replace `fetchToday()` with real `HealthConnectClient.queryRecords()` call
- Handle `PermissionNotGrantedException` gracefully
- Handle `RecordTypeNotAvailableException` (device doesn't support a type)

### Permission handling
- On first visit to Health tab: show permission request flow
- If denied: show "Grant permissions in Settings" with deep link to Android settings
- Cache permission state so we don't prompt every time

### Edge cases
- HC not installed → show install CTA (link to Play Store)
- Permission denied → show settings link
- No data today → show 0 with "No data yet" label
- Device without HC hardware → same as not installed

### Files changed
- `pubspec.yaml` — add `health_connect` dependency
- `lib/core/health_connect_service.dart` — replace stub with real API
- `lib/features/health/health_screen.dart` — handle not-available/denied states
- `lib/data/repositories/health_repository.dart` — no changes needed (already supports insert/bulkInsert)

---

## 3. App-Kill Hardening

### 3a. Auto-Save on Lifecycle Events

#### Problem
If app is killed while a workout is in progress (e.g., user locks phone, switches apps), partial progress may be lost. Currently only saved on complete/stop.

#### Solution
Save session progress when app lifecycle changes indicate potential termination.

#### Flow
```
AppLifecycleState.paused (app minimized / screen locked)
  → _controller.saveProgress() → write partial WorkoutSession to DB
  → engine keeps running (not stopped)

AppLifecycleState.detached (app being killed)
  → _controller.saveProgress()

AppLifecycleState.resumed (app comes back)
  → check if there's an unsaved partial session in progress
  → continue workout (engine still running in background)
```

#### saveProgress() method
New method on `ActiveWorkoutController`:
- Snapshot current state (completedSets, currentPhase, elapsed time)
- Write to DB as incomplete session (isComplete: false, stoppedEarly: true)
- Do NOT stop the engine — it keeps running

#### Implementation
- Add `AppLifecycleListener` in `ActiveWorkoutScreen.initState()`
- Dispose listener in `dispose()`
- Add `saveProgress()` method to `ActiveWorkoutController` (~15 lines)

### 3b. OEM Battery Optimization Hints

#### Problem
Android OEMs (Xiaomi, Oppo, Realme) aggressively kill background processes. Even foreground service can be terminated.

#### Solution
Add a button in Settings that opens the battery optimization exemption screen. User must manually grant exemption.

#### Implementation
- `AndroidManifest.xml`: add `<uses-permission android:name="android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS" />`
- MethodChannel in Kotlin MainActivity: expose `requestBatteryOptimizationExemption()`
- `SettingsScreen`: add ListTile "Optimasi Baterai" → show bottom sheet explanation + button to open settings
- Only shown once per app install (track in shared_preferences)

#### Files changed
- `android/app/src/main/AndroidManifest.xml` — add permission
- `android/app/src/main/kotlin/.../MainActivity.kt` — add method channel handler
- `lib/features/settings/settings_screen.dart` — add battery optimization option
- `lib/core/providers.dart` — add provider for tracking "shown battery hint" flag

---

## Implementation Order

1. Confirmation bottom sheet (smallest, no dependencies)
2. App-kill hardening (auto-save + battery hints — both small)
3. Health Connect integration (requires new dependency, more code)

Each can be tested independently.

---

## Testing Checklist

- [ ] Tap template card → bottom sheet appears with correct summary
- [ ] Tap "Batal" → sheet dismisses, stays on HomeScreen
- [ ] Tap "Mulai Latihan" → navigates to ActiveWorkoutScreen, countdown starts
- [ ] HC available + authorized → health data displays correctly
- [ ] HC not installed → install CTA shown
- [ ] HC permission denied → settings link shown
- [ ] Minimize app during workout → partial session saved to DB
- [ ] Resume app during workout → workout continues, no data loss
- [ ] OEM battery hint button → opens system settings
- [ ] `flutter analyze` clean
- [ ] All 45 tests pass
