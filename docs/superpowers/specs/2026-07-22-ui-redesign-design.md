# IntervalFit UI Redesign — Design Spec

**Date:** 2026-07-22
**Status:** Approved (pending spec review)
**Scope:** Visual layer only. No changes to `core/` (timer_engine, voice_service, background_service), `data/` (models, repositories), or `features/active_workout/active_workout_controller.dart`.

## 1. Decisions

| Decision | Choice | Rationale |
|---|---|---|
| Visual style | **Minimalism** | High contrast, flat surfaces, legible in sunlight while moving. Matches existing Barlow condensed direction. |
| Theme mode | **OLED Dark Mode** | True black `#000000` background. Battery saving on OLED panels, athletic/energetic feel. Existing app already dark. |
| Exercise assets | **AI-generated SVG** | Sharp, scalable, themeable, small app size, editable later. Wire via `flutter_svg`. |
| Approach | **A: Token-first refactor** | Add design tokens + extract 4-7 shared widgets + refactor screens to consume them. Smallest diff, max reuse, preserves working controller/data layer. |

## 2. Design Tokens

### 2.1 Spacing (8dp grid)

```dart
// lib/shared/design/tokens.dart
class AppSpacing {
  const AppSpacing._();
  static const double xs  = 4;
  static const double sm  = 8;
  static const double md  = 16;
  static const double lg  = 24;
  static const double xl  = 32;
  static const double xxl = 48;
}
```

### 2.2 Radius

```dart
class AppRadius {
  const AppRadius._();
  static const double sm   = 12;  // inputs, chips
  static const double md   = 16;  // cards
  static const double lg   = 24;  // hero cards, FAB
  static const double pill = 999;
}
```

### 2.3 Motion

```dart
class AppMotion {
  const AppMotion._();
  static const Duration fast   = Duration(milliseconds: 150); // press, hover
  static const Duration normal = Duration(milliseconds: 250); // phase color
  static const Duration slow   = Duration(milliseconds: 400); // screen
  static const Curve easing    = Curves.easeOutCubic;
}
```

### 2.4 Color Palette

OLED true black canvas. WCAG AA verified (≥4.5:1 for text on background).

| Token | Hex | Use | Contrast on bg |
|---|---|---|---|
| `background` | `#000000` | True black OLED canvas | — |
| `surface` | `#0A0A0B` | Raised surface | — |
| `surfaceHigh` | `#15151A` | Cards, FAB bg | — |
| `border` | `#1F1F26` | Subtle dividers | — |
| `onSurface` | `#F5F5F7` | Primary text | 17.4:1 |
| `onSurfaceMute` | `#8E8E93` | Secondary text | 6.9:1 |
| `onSurfaceDim` | `#48484A` | Tertiary (decor only) | 2.8:1 |
| `primary` | `#FF6B35` | Energy orange (brand) | 5.2:1 |
| `work` | `#FF3B30` | Vivid red phase | 4.8:1 |
| `rest` | `#0A84FF` | Vivid blue phase | 5.6:1 |
| `warmup` | `#FFD60A` | Amber phase | 13.1:1 |
| `cooldown` | `#30D158` | Green-teal phase | 8.9:1 |
| `done` | `#30D158` | Success | 8.9:1 |
| `destructive` | `#FF453A` | Stop, delete | 4.6:1 |

### 2.5 Typography Scale

Barlow family kept (already bundled, offline-first).

| Style | Font | Size | Weight | Notes |
|---|---|---|---|---|
| `displayLarge` | BarlowCondensed | 140 | W700 | Timer seconds, tabular figs |
| `displayMedium` | BarlowCondensed | 64 | W700 | Get-ready countdown |
| `headlineLarge` | BarlowCondensed | 32 | W700 | Screen titles |
| `headlineMedium` | BarlowCondensed | 24 | W700 | Section headers |
| `titleLarge` | Barlow | 20 | W600 | Card titles |
| `bodyLarge` | Barlow | 16 | W400 | Primary body |
| `bodyMedium` | Barlow | 14 | W400 | Summary text |
| `labelLarge` | Barlow | 14 | W600 | Buttons, +0.5 letter spacing |
| `labelSmall` | Barlow | 12 | W600 | Chips, +1 letter spacing |

## 3. Shared Widgets

All in `lib/shared/widgets/`. Extracted from existing code where possible.

### 3.1 `AthleticCard`
Replaces ad-hoc `Card` in home/history.
- `surfaceHigh` bg, border 1px subtle, radius `lg`
- Optional left accent strip (phase color, 4px)
- Optional leading icon avatar (48dp CircleAvatar, tinted)
- `InkWell` ripple on tap, `AnimatedScale(0.98)` on pressDown
- Min touch target 48dp height

### 3.2 `PhaseProgressRing`
Extracted from `active_workout_screen._Ring`.
- `CustomPainter` arc, 16px stroke, rounded cap
- `AnimatedColor` transition (250ms) when phase changes
- Track = border color, arc = phase color
- Child centered (timer digits / icon)
- Size 280dp

### 3.3 `CircleControlButton`
Extracted from `_CircleButton`.
- 64x64 minimum (WCAG), radius pill
- `AnimatedScale` 1.0→0.92 on press, 150ms easeOutCubic
- Optional haptic (`HapticLight`) on tap
- Label below, 12px labelSmall

### 3.4 `ExerciseHero`
New, for active workout top area.
- 120x120 SVG illustration per exercise type (skipping/walk/run/custom)
- Sits above phase label, new visual layer
- Subtle parallax: translate Y -4px on phase change (250ms)

### 3.5 `MetricBadge`
New, for history + active workout stats.
- Pill shape, `surfaceHigh` bg, border
- Label (`labelSmall`) + value (`titleLarge`)
- Examples: "10/10 SETS", "05:30"

### 3.6 `PhasePill`
New, replaces phase Text label in active workout.
- Pill bg = phase color at 18% alpha
- Text = phase color, `labelSmall` uppercase +2 letter spacing
- `AnimatedColor` 250ms on phase change

### 3.7 `SegmentedProgress`
New, thin bar showing set progress.
- N segments (one per set), filled = done, current = pulsing phase color
- 4px height, gap 4px, radius 2px
- Below `PhaseProgressRing`, new visual layer
- Hidden during getReady/done

## 4. Micro-interactions

All 150-300ms `easeOutCubic` unless noted.

| Interaction | Widget | Duration |
|---|---|---|
| Card press scale + ripple | AthleticCard | 150ms |
| Button press scale + haptic | CircleControlButton | 150ms |
| Phase color tween | PhaseProgressRing, PhasePill | 250ms |
| Hero parallax Y -4px | ExerciseHero | 250ms |
| Done check scale-in + fade | ActiveWorkoutScreen | 300ms |
| Get-ready pulse (existing) | _GetReadyCountdown | 600ms |
| Switch animated color | Settings | 200ms |
| SVG preview fade on type select | TemplateBuilder | 250ms |

## 5. Screens

### 5.1 Home Screen

```
AppBar
  title: "INTERVALFIT" (headlineLarge, primary color, letter-spacing 2)
  actions: History icon, Settings icon (24dp, onSurfaceMute)

Body (ListView, padding md horizontal, lg top, xxl bottom for FAB)
  SectionLabel "Templates" (headlineMedium, onSurfaceMute, +1 spacing)
  AthleticCard × N
    leading: CircleAvatar 48dp, surfaceHigh bg, SVG 28dp tinted phase color
    title: template.name (titleLarge)
    subtitle: "10 sets · 30s work / 30s rest" (bodyMedium, onSurfaceMute)
    accent strip: 4px left, exercise color
    trailing: PopupMenuButton (edit/delete)
    tap: → ActiveWorkoutScreen

FAB.extended
  label: "New Template" (labelLarge)
  icon: Lucide plus
  bg: primary, fg: background
  AnimatedScale 0.95 on press

EmptyState
  SVG 96dp (custom/dumbbell), onSurfaceDim
  headlineMedium "No templates yet"
  bodyMedium hint
```

### 5.2 Template Builder Screen

```
AppBar title: "New Template" / "Edit Template" (headlineLarge)

Form (ListView, padding md)
  TextFormField Name — surfaceHigh bg, radius sm, 56dp height
  DropdownButton Exercise type — same style
    → shows SVG preview 64dp when selected
  TextFormField Sets — number keyboard
  DurationInput × 4 (work/rest/warmup/cooldown)
    Row: input + unit dropdown (sec/min)
    surfaceHigh bg, radius sm

BottomBar (pinned)
  FilledButton "Save" — primary bg, 52dp height, radius sm, labelLarge
  AnimatedOpacity on form valid state
```

### 5.3 Active Workout Screen (centerpiece)

```
Scaffold bg: background (true black)

SafeArea > Column
  top: ExerciseHero 120dp SVG (parallax on phase change)

  PhasePill (uppercase phase name, tinted bg)

  Set label "SET 3 / 8" (labelSmall, onSurfaceMute, +2 spacing)
    — hidden during getReady/warmup/cooldown/done

  Expanded center:
    if getReady: _GetReadyCountdown (existing, 320px pulse)
    if done: Icon check_circle 160dp, scale-in + fade (300ms)
    else: PhaseProgressRing 280dp
      child: FittedBox > Text digits (displayLarge 140, tabular)
        format: "45" if <60s, "01:30" if ≥60s

  SegmentedProgress (N segments, current pulses)
    — hidden during getReady/done

  Controls row (spaceEvenly, padding lg bottom):
    CircleControlButton pause/resume (phase color)
    CircleControlButton skip (phase color)
    CircleControlButton stop (destructive color)
```

### 5.4 History Screen

```
AppBar title "History" (headlineLarge)

Body (ListView)
  if empty: SVG 96dp + "No history yet"

  AthleticCard × N
    leading: CircleAvatar 48dp
      completed? done color : warmup color
      icon: check / pause
    title: templateName (titleLarge)
    subtitle: "2026-07-22 14:30 · 05:30 · 8/10 set" (bodyMedium)
    trailing: MetricBadge "Completed" / "Partial" (chip style)
```

### 5.5 Settings Screen

```
AppBar title "Settings" (headlineLarge)

Section
  SwitchListTile Voice guidance
    leading: SVG speaker icon 24dp
    title: titleLarge
    subtitle: bodyMedium onSurfaceMute
    active color: primary
    56dp height (touch target)

  (future: language, haptics, etc. — YAGNI for v1)
```

## 6. Assets

New SVG assets in `assets/svg/`:
- `skipping.svg` — jump rope figure
- `walk.svg` — walking figure
- `run.svg` — running figure
- `custom.svg` — dumbbell
- `speaker.svg` — for settings voice toggle
- `history.svg` — optional, for empty state
- `dumbbell.svg` — for empty templates state

New dependency: `flutter_svg: ^2.0.10+1`

## 7. Files Touched

### New
- `lib/shared/design/tokens.dart` — spacing, radius, motion
- `lib/shared/widgets/athletic_card.dart`
- `lib/shared/widgets/phase_progress_ring.dart`
- `lib/shared/widgets/circle_control_button.dart`
- `lib/shared/widgets/exercise_hero.dart`
- `lib/shared/widgets/metric_badge.dart`
- `lib/shared/widgets/phase_pill.dart`
- `lib/shared/widgets/segmented_progress.dart`
- `assets/svg/*.svg` (7 files)

### Modified
- `lib/shared/theme/app_theme.dart` — OLED black palette, new typography scale
- `lib/features/home/home_screen.dart` — use AthleticCard, tokens, SVG
- `lib/features/template_builder/template_builder_screen.dart` — tokens, SVG preview
- `lib/features/active_workout/active_workout_screen.dart` — use shared widgets, ExerciseHero, PhasePill, SegmentedProgress
- `lib/features/history/history_screen.dart` — use AthleticCard, MetricBadge
- `lib/features/settings/settings_screen.dart` — tokens, SVG speaker icon
- `pubspec.yaml` — add `flutter_svg` dep, declare `assets/svg/`

### Untouched (lead-protected)
- `lib/core/timer_engine.dart`
- `lib/core/voice_service.dart`
- `lib/core/background_service.dart`
- `lib/core/providers.dart`
- `lib/core/settings_service.dart`
- `lib/data/**`
- `lib/features/active_workout/active_workout_controller.dart`

## 8. Testing

- Existing tests must still pass (no controller/data changes).
- Existing widget tests (`home_screen_test.dart`, `template_builder_screen_test.dart`) may need updates for new widget tree structure — update to find by key/semantics, not by raw Text.
- New widget tests for shared widgets: `athletic_card_test.dart`, `phase_pill_test.dart`, `segmented_progress_test.dart`.
- Visual verification: manual run on emulator/device.

## 9. WCAG Compliance

- All text ≥4.5:1 contrast on background (verified in token table).
- All interactive widgets ≥48x48dp touch target.
- Phase colors distinct in hue (red/blue/amber/green) — colorblind-safe.
- Phase changes also announced via voice cue (existing) — not color-only.

## 10. Out of Scope (YAGNI v1)

- Light mode toggle (OLED dark only).
- Multi-language UI (English-only per existing decision).
- Animated SVG (static illustrations only).
- Custom illustration per exercise subtype (4 types only).
- Onboarding/tutorial screens.
