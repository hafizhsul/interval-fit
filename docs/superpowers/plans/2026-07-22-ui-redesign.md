# IntervalFit UI Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesign IntervalFit's UI to a minimalist OLED dark theme with a token-based design system, shared widgets, micro-interactions, and per-exercise SVG illustrations.

**Architecture:** Token-first refactor. Add `lib/shared/design/tokens.dart` (spacing/radius/motion) and refactor `lib/shared/theme/app_theme.dart` to OLED-black palette. Extract 7 shared widgets in `lib/shared/widgets/`. Refactor 5 feature screens to consume tokens + shared widgets. Add `flutter_svg` dep + 7 SVG assets. `core/`, `data/`, `active_workout_controller.dart` untouched.

**Tech Stack:** Flutter, Riverpod, flutter_svg (new), existing Barlow fonts, existing sqflite/flutter_tts/audioplayers.

**Spec:** `docs/superpowers/specs/2026-07-22-ui-redesign-design.md` — design tokens, color palette, typography scale, widget specs, screen layouts all defined there. Read it for visual details.

## Global Constraints

- **Visual style:** Minimalism — flat surfaces, bold typography, high contrast.
- **Theme mode:** OLED Dark — true black `#000000` background.
- **Touch targets:** minimum 48x48dp (WCAG).
- **Contrast:** minimum 4.5:1 for text on background (WCAG AA).
- **Motion:** 150-300ms, `Curves.easeOutCubic` unless noted.
- **Untouched (lead-protected):** `lib/core/**`, `lib/data/**`, `lib/features/active_workout/active_workout_controller.dart`.
- **Test commands:** `flutter analyze` (must be clean), `flutter test` (all must pass).
- **Commit style:** Conventional Commits, English. Each task ends with a commit.
- **No comments** in code unless explicitly noted (per project CLAUDE.md).
- **Language:** UI English-only (existing decision).

## File Structure

### New files

| Path | Responsibility |
|---|---|
| `lib/shared/design/tokens.dart` | Spacing, radius, motion constants |
| `lib/shared/widgets/athletic_card.dart` | Card with optional accent strip + avatar |
| `lib/shared/widgets/phase_progress_ring.dart` | Circular progress ring (extracted) |
| `lib/shared/widgets/circle_control_button.dart` | 64dp press-scale button (extracted) |
| `lib/shared/widgets/exercise_hero.dart` | 120dp SVG with parallax |
| `lib/shared/widgets/metric_badge.dart` | Pill stat badge |
| `lib/shared/widgets/phase_pill.dart` | Tinted phase label pill |
| `lib/shared/widgets/segmented_progress.dart` | N-segment set progress bar |
| `assets/svg/*.svg` (7 files) | Exercise + UI illustrations |
| `test/shared/widgets/*_test.dart` (6 files) | Widget tests |

### Modified files

| Path | Changes |
|---|---|
| `pubspec.yaml` | Add `flutter_svg: ^2.0.10+1`, declare `assets/svg/` |
| `lib/shared/theme/app_theme.dart` | OLED black palette, new typography scale, inputDecorationTheme |
| `lib/features/home/home_screen.dart` | Use AthleticCard, tokens, SVG |
| `lib/features/template_builder/template_builder_screen.dart` | Tokens, SVG preview on type select |
| `lib/features/active_workout/active_workout_screen.dart` | Use shared widgets, ExerciseHero, PhasePill, SegmentedProgress |
| `lib/features/history/history_screen.dart` | Use AthleticCard, MetricBadge |
| `lib/features/settings/settings_screen.dart` | Tokens, SVG speaker icon |
| `test/features/home_screen_test.dart` | Update finders for new tree |
| `test/features/template_builder_screen_test.dart` | Update finders for new tree |

---

## Task 1: Add `flutter_svg` dependency and SVG assets

**Files:**
- Modify: `pubspec.yaml`
- Create: `assets/svg/skipping.svg`, `assets/svg/walk.svg`, `assets/svg/run.svg`, `assets/svg/custom.svg`, `assets/svg/speaker.svg`, `assets/svg/history.svg`, `assets/svg/dumbbell.svg`

**Interfaces:**
- Produces: 7 SVG assets in `assets/svg/`, registered in pubspec `flutter.assets`. Consumed by `ExerciseHero` (Task 7), `SettingsScreen` (Task 12), `HomeScreen` (Task 9), `HistoryScreen` (Task 11).

- [ ] **Step 1: Add flutter_svg to pubspec.yaml**

In the `dependencies:` block, after `flutter_background_service: ^5.1.0`, add:

```yaml
  # SVG rendering for exercise illustrations
  flutter_svg: ^2.0.10+1
```

In the `flutter:` block, change `assets:` to include both dirs:

```yaml
  assets:
    - assets/audio/
    - assets/svg/
```

- [ ] **Step 2: Create the 7 SVG files**

Create `assets/svg/` directory and write these files. All SVGs use `stroke="currentColor"` so they can be tinted via `ColorFilter.mode(color, BlendMode.srcIn)` in `flutter_svg`.

`assets/svg/skipping.svg` — jump rope figure:

```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 120 120" fill="none" stroke="currentColor" stroke-width="4" stroke-linecap="round" stroke-linejoin="round">
  <path d="M30 110 C20 80 20 40 60 40 C100 40 100 80 90 110"/>
  <circle cx="60" cy="28" r="8"/>
  <path d="M60 36 L60 60"/>
  <path d="M60 60 L48 80"/>
  <path d="M60 60 L72 80"/>
  <path d="M48 80 L48 100"/>
  <path d="M72 80 L72 100"/>
</svg>
```

`assets/svg/walk.svg` — walking figure:

```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 120 120" fill="none" stroke="currentColor" stroke-width="4" stroke-linecap="round" stroke-linejoin="round">
  <circle cx="70" cy="20" r="8"/>
  <path d="M70 28 L68 56"/>
  <path d="M68 56 L52 80"/>
  <path d="M68 56 L82 70"/>
  <path d="M52 80 L48 105"/>
  <path d="M82 70 L92 95"/>
  <path d="M40 60 L80 50"/>
</svg>
```

`assets/svg/run.svg` — running figure:

```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 120 120" fill="none" stroke="currentColor" stroke-width="4" stroke-linecap="round" stroke-linejoin="round">
  <circle cx="78" cy="22" r="8"/>
  <path d="M78 30 L72 55"/>
  <path d="M72 55 L58 75"/>
  <path d="M72 55 L88 68"/>
  <path d="M58 75 L50 100"/>
  <path d="M88 68 L100 92"/>
  <path d="M35 58 L75 48"/>
  <path d="M30 85 L50 75"/>
</svg>
```

`assets/svg/custom.svg` — dumbbell:

```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 120 120" fill="none" stroke="currentColor" stroke-width="4" stroke-linecap="round" stroke-linejoin="round">
  <path d="M20 50 L20 70"/>
  <path d="M30 40 L30 80"/>
  <path d="M30 60 L90 60"/>
  <path d="M90 40 L90 80"/>
  <path d="M100 50 L100 70"/>
</svg>
```

`assets/svg/speaker.svg` — speaker icon (24x24, stroke-width 2):

```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <polygon points="11 5 6 9 2 9 2 15 6 15 11 19 11 5"/>
  <path d="M15.54 8.46a5 5 0 0 1 0 7.07"/>
  <path d="M19.07 4.93a10 10 0 0 1 0 14.14"/>
</svg>
```

`assets/svg/history.svg` — clock icon (24x24, stroke-width 2):

```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <circle cx="12" cy="12" r="10"/>
  <polyline points="12 6 12 12 16 14"/>
</svg>
```

`assets/svg/dumbbell.svg` — same shape as custom.svg (separate file so empty state can swap without touching exercise icons). Copy the exact content of `custom.svg` above.

- [ ] **Step 3: Run flutter pub get**

Run: `flutter pub get`
Expected: "Got dependencies!" with no errors.

- [ ] **Step 4: Verify SVGs exist**

Run: `ls -la assets/svg/`
Expected: 7 `.svg` files listed.

- [ ] **Step 5: Commit**

```bash
git add pubspec.yaml pubspec.lock assets/svg/
git commit -m "feat(ui): add flutter_svg dep and exercise SVG assets"
```

---

## Task 2: Create design tokens

**Files:**
- Create: `lib/shared/design/tokens.dart`
- Create: `test/shared/design/tokens_test.dart`

**Interfaces:**
- Produces: `AppSpacing` (xs/sm/md/lg/xl/xxl doubles), `AppRadius` (sm/md/lg/pill doubles), `AppMotion` (fast/normal/slow Durations, `easing` Curve). Consumed by all subsequent widget/screen tasks.

- [ ] **Step 1: Write the failing test**

Create `test/shared/design/tokens_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:interval_fit/shared/design/tokens.dart';

void main() {
  test('AppSpacing follows 8dp grid', () {
    expect(AppSpacing.xs, 4);
    expect(AppSpacing.sm, 8);
    expect(AppSpacing.md, 16);
    expect(AppSpacing.lg, 24);
    expect(AppSpacing.xl, 32);
    expect(AppSpacing.xxl, 48);
  });

  test('AppRadius values are correct', () {
    expect(AppRadius.sm, 12);
    expect(AppRadius.md, 16);
    expect(AppRadius.lg, 24);
    expect(AppRadius.pill, 999);
  });

  test('AppMotion durations are within spec range', () {
    expect(AppMotion.fast.inMilliseconds, 150);
    expect(AppMotion.normal.inMilliseconds, 250);
    expect(AppMotion.slow.inMilliseconds, 400);
    expect(AppMotion.easing, Curves.easeOutCubic);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/shared/design/tokens_test.dart`
Expected: FAIL — `tokens.dart` does not exist.

- [ ] **Step 3: Create lib/shared/design/tokens.dart**

```dart
import 'package:flutter/material.dart';

class AppSpacing {
  const AppSpacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

class AppRadius {
  const AppRadius._();
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double pill = 999;
}

class AppMotion {
  const AppMotion._();
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);
  static const Curve easing = Curves.easeOutCubic;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/shared/design/tokens_test.dart`
Expected: PASS — 3 tests.

- [ ] **Step 5: Run flutter analyze**

Run: `flutter analyze`
Expected: "No issues found!"

- [ ] **Step 6: Commit**

```bash
git add lib/shared/design/tokens.dart test/shared/design/tokens_test.dart
git commit -m "feat(ui): add design tokens (spacing, radius, motion)"
```

---

## Task 3: Refactor app_theme.dart to OLED dark palette

**Files:**
- Modify: `lib/shared/theme/app_theme.dart` (full rewrite)

**Interfaces:**
- Produces: `AppColors` with new tokens (background `#000000`, surface, surfaceHigh, border, onSurface, onSurfaceMute, onSurfaceDim, primary, work, rest, warmup, cooldown, done, destructive). `AppTheme.dark` ThemeData with new typography scale + `inputDecorationTheme` + `switchTheme`. Consumed by all widget/screen tasks.
- Backward compat: keep `AppColors.muted` as alias to `onSurfaceMute` (existing screens reference it) until screens are refactored in Tasks 9-12.

- [ ] **Step 1: Run existing tests to establish baseline**

Run: `flutter test`
Expected: all existing tests PASS (baseline before refactor).

- [ ] **Step 2: Rewrite app_theme.dart**

Replace entire contents of `lib/shared/theme/app_theme.dart` with:

```dart
import 'package:flutter/material.dart';

import '../design/tokens.dart';

class AppColors {
  AppColors._();

  static const Color background = Color(0xFF000000);
  static const Color surface = Color(0xFF0A0A0B);
  static const Color surfaceHigh = Color(0xFF15151A);
  static const Color border = Color(0xFF1F1F26);
  static const Color onSurface = Color(0xFFF5F5F7);
  static const Color onSurfaceMute = Color(0xFF8E8E93);
  static const Color onSurfaceDim = Color(0xFF48484A);

  static const Color primary = Color(0xFFFF6B35);
  static const Color work = Color(0xFFFF3B30);
  static const Color rest = Color(0xFF0A84FF);
  static const Color warmup = Color(0xFFFFD60A);
  static const Color cooldown = Color(0xFF30D158);
  static const Color done = Color(0xFF30D158);
  static const Color destructive = Color(0xFFFF453A);

  static const Color muted = onSurfaceMute;
}

class AppTheme {
  AppTheme._();

  static const _sans = 'Barlow';
  static const _condensed = 'BarlowCondensed';

  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    final scheme = base.colorScheme.copyWith(
      primary: AppColors.primary,
      onPrimary: AppColors.background,
      secondary: AppColors.done,
      surface: AppColors.surfaceHigh,
      onSurface: AppColors.onSurface,
      outline: AppColors.border,
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: scheme,
      textTheme: base.textTheme
          .apply(
            fontFamily: _sans,
            bodyColor: AppColors.onSurface,
            displayColor: AppColors.onSurface,
          )
          .copyWith(
            displayLarge: const TextStyle(
              fontFamily: _condensed,
              fontSize: 140,
              fontWeight: FontWeight.w700,
              height: 1.0,
              color: Colors.white,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
            displayMedium: const TextStyle(
              fontFamily: _condensed,
              fontSize: 64,
              fontWeight: FontWeight.w700,
              height: 1.0,
              color: Colors.white,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
            headlineLarge: const TextStyle(
              fontFamily: _condensed,
              fontSize: 32,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: AppColors.onSurface,
            ),
            headlineMedium: const TextStyle(
              fontFamily: _condensed,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: AppColors.onSurfaceMute,
            ),
            titleLarge: const TextStyle(
              fontFamily: _sans,
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
            ),
            bodyLarge: const TextStyle(
              fontFamily: _sans,
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: AppColors.onSurface,
            ),
            bodyMedium: const TextStyle(
              fontFamily: _sans,
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppColors.onSurfaceMute,
            ),
            labelLarge: const TextStyle(
              fontFamily: _sans,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: AppColors.onSurface,
            ),
            labelSmall: const TextStyle(
              fontFamily: _sans,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
              color: AppColors.onSurfaceMute,
            ),
          ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceHigh,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.background,
          minimumSize: const Size(0, 52),
          textStyle: const TextStyle(
            fontFamily: _sans,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceHigh,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        titleTextStyle: TextStyle(
          fontFamily: _condensed,
          fontSize: 26,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: AppColors.onSurface,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary;
          return AppColors.onSurfaceDim;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary;
          return AppColors.surfaceHigh;
        }),
      ),
    );
  }
}
```

- [ ] **Step 3: Run flutter analyze**

Run: `flutter analyze`
Expected: "No issues found!" (existing screens still compile via `AppColors.muted` alias).

- [ ] **Step 4: Run all tests**

Run: `flutter test`
Expected: all existing tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/shared/theme/app_theme.dart
git commit -m "feat(ui): refactor theme to OLED black palette + typography scale"
```

---

## Tasks 4-12: Shared widgets + screen refactors

The remaining tasks follow the same TDD pattern as Tasks 1-3. Each task creates a shared widget (or refactors a screen) with a failing test first, then implementation, then `flutter analyze` + `flutter test`, then commit.

### Task 4: PhasePill widget
Create `lib/shared/widgets/phase_pill.dart` + test. Widget spec in design doc section 3.6. Exposes `PhasePill.colorFor(phase)` and `PhasePill.labelFor(phase)` static helpers. Consumed by ActiveWorkoutScreen (Task 10).

### Task 5: PhaseProgressRing widget
Create `lib/shared/widgets/phase_progress_ring.dart` + test. Widget spec in design doc section 3.2. Extracted from `active_workout_screen._Ring`. Exposes `PhaseRingPainter` for testing. Consumed by ActiveWorkoutScreen (Task 10).

### Task 6: CircleControlButton widget
Create `lib/shared/widgets/circle_control_button.dart` + test. Widget spec in design doc section 3.3. Extracted from `_CircleButton`. 64dp min, AnimatedScale 0.92 on press, optional haptic. Consumed by ActiveWorkoutScreen (Task 10).

### Task 7: ExerciseHero widget
Create `lib/shared/widgets/exercise_hero.dart` + test. Widget spec in design doc section 3.4. 120dp SVG with parallax on color change. Uses `flutter_svg`. Consumed by ActiveWorkoutScreen (Task 10).

### Task 8: MetricBadge, SegmentedProgress, AthleticCard widgets
Create 3 widgets + 2 tests (segmented_progress + athletic_card). Widget specs in design doc sections 3.5, 3.7, 3.1. Consumed by HomeScreen (Task 9), HistoryScreen (Task 11), ActiveWorkoutScreen (Task 10).

### Task 9: Refactor HomeScreen
Modify `lib/features/home/home_screen.dart` + update `test/features/home_screen_test.dart`. Use AthleticCard, tokens, SVG icons. Screen spec in design doc section 5.1.

### Task 10: Refactor ActiveWorkoutScreen
Modify `lib/features/active_workout/active_workout_screen.dart`. Use PhaseProgressRing, CircleControlButton, ExerciseHero, PhasePill, SegmentedProgress. Screen spec in design doc section 5.3. Keep existing `_GetReadyCountdown` widget (already well-designed). Keep existing controller wiring (start/pause/resume/skip/stop + `_onState` save-await-pop logic from prior bug fix).

### Task 11: Refactor HistoryScreen
Modify `lib/features/history/history_screen.dart`. Use AthleticCard, MetricBadge. Screen spec in design doc section 5.4.

### Task 12: Refactor SettingsScreen
Modify `lib/features/settings/settings_screen.dart`. Use tokens, SVG speaker icon. Screen spec in design doc section 5.5.

### Task 13: Final verification
Run `flutter analyze` + `flutter test` + manual smoke test on emulator. Verify all existing tests still pass, no new warnings, OLED black theme renders correctly, SVGs load, micro-interactions feel smooth (150-300ms).

---

## Self-Review Notes

- **Spec coverage:** All 7 widgets from spec section 3 have tasks (4-8). All 5 screens from spec section 5 have tasks (9-12). Design tokens from spec section 2 covered in Tasks 2-3. SVG assets from spec section 6 covered in Task 1. Micro-interactions from spec section 4 implemented within each widget task.
- **Type consistency:** `PhasePill.colorFor(phase)` used by both PhasePill (Task 4) and ActiveWorkoutScreen (Task 10). `PhaseRingPainter` exposed by PhaseProgressRing (Task 5) for test access. `CircleControlButton` params match ActiveWorkoutScreen usage.
- **Backward compat:** `AppColors.muted` alias preserved until all screens refactored, removed implicitly when last screen (Task 12) stops referencing it — safe to leave as alias.
- **Untouched:** `lib/core/**`, `lib/data/**`, `active_workout_controller.dart` confirmed untouched by all tasks.
