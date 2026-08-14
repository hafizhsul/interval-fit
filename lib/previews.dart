// Flutter Widget Previewer (native, Flutter 3.35+): `flutter widget-preview start`.
//
// Must live under lib/ — the previewer's dependency graph derives the package
// name from the library URI, and files outside lib/ (scheme != package) crash
// the tool (`packageName!` null check). Previews are compile-time annotations
// only; tree shaking keeps them out of release builds.
//
// Previews run on Flutter Web, so only widgets without native plugins
// (sqflite, TTS, background service) can be previewed. Screens that read
// providers backed by sqflite are intentionally excluded; the pure shared
// widgets below are the previewable surface.
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import 'package:interval_fit/core/timer_engine.dart' show WorkoutPhase;
import 'package:interval_fit/shared/design/tokens.dart';
import 'package:interval_fit/shared/theme/app_theme.dart';
import 'package:interval_fit/shared/widgets/circle_control_button.dart';
import 'package:interval_fit/shared/widgets/exercise_hero.dart';
import 'package:interval_fit/shared/widgets/loading_skeleton.dart';
import 'package:interval_fit/shared/widgets/menu_header.dart';
import 'package:interval_fit/shared/widgets/phase_pill.dart';
import 'package:interval_fit/shared/widgets/phase_progress_ring.dart';
import 'package:interval_fit/shared/widgets/segmented_progress.dart';

/// Wraps every preview in the app theme. AppColors follows the previewer's
/// light/dark toggle via the ambient [Brightness].
Widget previewWrapper(Widget child) => _PreviewApp(child: child);

class _PreviewApp extends StatelessWidget {
  const _PreviewApp({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final light = Theme.of(context).brightness == Brightness.light;
    AppColors.setLight(light);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: light ? AppTheme.light : AppTheme.dark,
      home: Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: SingleChildScrollView(child: child)),
      ),
    );
  }
}

@Preview(name: 'Greeting', group: 'MenuHeader', wrapper: previewWrapper)
Widget menuHeaderPreview() => const MenuHeader(
  title: 'History',
  subtitle: 'Your movement, one session at a time.',
  icon: Icons.history_rounded,
);

@Preview(name: 'Section title', group: 'MenuHeader', wrapper: previewWrapper)
Widget menuSectionTitlePreview() =>
    const MenuSectionTitle(label: 'SESSION VAULT');

@Preview(name: 'Skeleton box', group: 'Skeletons', wrapper: previewWrapper)
Widget skeletonBoxPreview() =>
    const SkeletonBox(width: 240, height: 32, radius: AppRadius.sm);

@Preview(
  name: 'Menu header skeleton',
  group: 'Skeletons',
  wrapper: previewWrapper,
)
Widget skeletonMenuHeaderPreview() => const SkeletonMenuHeader();

@Preview(
  name: 'Metric card skeleton',
  group: 'Skeletons',
  wrapper: previewWrapper,
)
Widget skeletonMetricCardPreview() => const SkeletonMetricCard();

@Preview(name: 'Circle control', group: 'Controls', wrapper: previewWrapper)
Widget circleControlPreview() => CircleControlButton(
  icon: Icons.pause_rounded,
  label: 'Pause',
  color: AppColors.primary,
  onPressed: () {},
);

@Preview(name: 'Phase pill - work', group: 'PhasePill', wrapper: previewWrapper)
@Preview(name: 'Phase pill - rest', group: 'PhasePill', wrapper: previewWrapper)
@Preview(
  name: 'Phase pill - warmup',
  group: 'PhasePill',
  wrapper: previewWrapper,
)
Widget phasePillPreview() => PhasePill(phase: WorkoutPhase.work);

@Preview(name: 'Progress ring', group: 'Progress', wrapper: previewWrapper)
Widget progressRingPreview() => PhaseProgressRing(
  progress: 0.65,
  color: AppColors.work,
  child: Text(
    '00:24',
    style: ThemeData.dark().textTheme.displayLarge?.copyWith(
      color: AppColors.onSurface,
    ),
  ),
);

@Preview(name: 'Segmented progress', group: 'Progress', wrapper: previewWrapper)
Widget segmentedProgressPreview() =>
    SegmentedProgress(total: 8, current: 3, color: AppColors.primary);

@Preview(
  name: 'Exercise hero - run',
  group: 'ExerciseHero',
  wrapper: previewWrapper,
)
Widget exerciseHeroPreview() =>
    const ExerciseHero(exerciseType: 'run', color: AppColors.work);
