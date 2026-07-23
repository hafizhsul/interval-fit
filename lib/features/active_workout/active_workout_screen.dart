import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/timer_engine.dart';
import '../../data/models/workout_template.dart';
import '../../shared/design/tokens.dart';
import '../../shared/format.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/circle_control_button.dart';
import '../../shared/widgets/exercise_hero.dart';
import '../../shared/widgets/phase_pill.dart';
import '../../shared/widgets/phase_progress_ring.dart';
import '../../shared/widgets/segmented_progress.dart';
import 'active_workout_controller.dart';

class ActiveWorkoutScreen extends ConsumerStatefulWidget {
  const ActiveWorkoutScreen({super.key, required this.template});

  final WorkoutTemplate template;

  @override
  ConsumerState<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends ConsumerState<ActiveWorkoutScreen> {
  late final ActiveWorkoutController _controller;
  bool _popped = false;

  @override
  void initState() {
    super.initState();
    _controller = ActiveWorkoutController(
      template: widget.template,
      voice: ref.read(voiceServiceProvider),
      history: ref.read(historyRepositoryProvider),
    );
    _controller.state.addListener(_onState);
    _controller.start();
  }

  void _onState() {
    final s = _controller.state.value;
    if (s.phase == WorkoutPhase.done && !_popped) {
      _popped = true;
      final save = _controller.saveFuture;
      (save ?? Future<void>.value()).whenComplete(() {
        if (mounted) Navigator.of(context).pop();
      });
    }
  }

  @override
  void dispose() {
    _controller.state.removeListener(_onState);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _stop() async {
    await _controller.stop();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TimerState>(
      valueListenable: _controller.state,
      builder: (context, s, _) {
        final isDone = s.phase == WorkoutPhase.done;
        final isPaused = s.status == TimerStatus.paused;
        final phaseColor = PhasePill.colorFor(s.phase);
        final showSetLabel = !isDone &&
            s.phase != WorkoutPhase.getReady &&
            s.phase != WorkoutPhase.warmup &&
            s.phase != WorkoutPhase.cooldown;
        final showSegmented = !isDone && s.phase != WorkoutPhase.getReady;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: <Widget>[
                  ExerciseHero(
                    exerciseType: widget.template.exerciseType,
                    color: phaseColor,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  PhasePill(phase: s.phase),
                  if (showSetLabel) ...<Widget>[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'SET ${s.currentSet} / ${s.totalSets}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.onSurfaceMute,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                  Expanded(
                    child: Center(
                      child: isDone
                          ? const _DoneCheck()
                          : s.phase == WorkoutPhase.getReady
                              ? _GetReadyCountdown(remaining: s.phaseRemainingSeconds)
                              : PhaseProgressRing(
                                  progress: s.phaseProgress,
                                  color: phaseColor,
                                  size: 280,
                                  strokeWidth: 16,
                                  child: FittedBox(
                                    child: Text(
                                      s.phaseRemainingSeconds >= 60
                                          ? formatMmSs(s.phaseRemainingSeconds)
                                          : s.phaseRemainingSeconds.toString(),
                                      style: Theme.of(context).textTheme.displayLarge,
                                    ),
                                  ),
                                ),
                    ),
                  ),
                  if (showSegmented) ...<Widget>[
                    const SizedBox(height: AppSpacing.lg),
                    SegmentedProgress(
                      total: s.totalSets,
                      current: s.currentSet,
                      color: phaseColor,
                    ),
                  ],
                  if (!isDone)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.lg),
                      child: _controls(isPaused, phaseColor),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _controls(bool isPaused, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        CircleControlButton(
          icon: isPaused ? Icons.play_arrow : Icons.pause,
          label: isPaused ? 'Resume' : 'Pause',
          color: color,
          onPressed: () => isPaused ? _controller.resume() : _controller.pause(),
        ),
        CircleControlButton(
          icon: Icons.skip_next,
          label: 'Skip',
          color: color,
          onPressed: _controller.skip,
        ),
        CircleControlButton(
          icon: Icons.stop,
          label: 'Stop',
          color: AppColors.destructive,
          onPressed: _stop,
        ),
      ],
    );
  }
}

class _DoneCheck extends StatefulWidget {
  const _DoneCheck();

  @override
  State<_DoneCheck> createState() => _DoneCheckState();
}

class _DoneCheckState extends State<_DoneCheck> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  );
  late final Animation<double> _scale = Tween(begin: 0.0, end: 1.0)
      .chain(CurveTween(curve: Curves.easeOutCubic))
      .animate(_ctrl);
  late final Animation<double> _fade = Tween(begin: 0.0, end: 1.0)
      .chain(CurveTween(curve: Curves.easeOutCubic))
      .animate(_ctrl);

  @override
  void initState() {
    super.initState();
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = PhasePill.colorFor(WorkoutPhase.done);
    return FadeTransition(
      opacity: _fade,
      child: ScaleTransition(
        scale: _scale,
        child: Icon(Icons.check_circle, color: color, size: 160),
      ),
    );
  }
}

class _GetReadyCountdown extends StatefulWidget {
  const _GetReadyCountdown({required this.remaining});

  final int remaining;

  @override
  State<_GetReadyCountdown> createState() => _GetReadyCountdownState();
}

class _GetReadyCountdownState extends State<_GetReadyCountdown>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );
  late final Animation<double> _scale = Tween<double>(begin: 1.0, end: 1.07)
      .chain(CurveTween(curve: Curves.easeOut))
      .animate(_ctrl);

  @override
  void initState() {
    super.initState();
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(covariant _GetReadyCountdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.remaining != widget.remaining) {
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Text(
        widget.remaining.toString(),
        style: const TextStyle(
          fontFamily: 'BarlowCondensed',
          fontSize: 320,
          fontWeight: FontWeight.w700,
          height: 1.0,
          color: AppColors.primary,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}