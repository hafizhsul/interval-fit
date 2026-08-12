import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

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
import 'workout_result_dialog.dart';

class ActiveWorkoutScreen extends ConsumerStatefulWidget {
  const ActiveWorkoutScreen({super.key, required this.template});

  final WorkoutTemplate template;

  @override
  ConsumerState<ActiveWorkoutScreen> createState() =>
      _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends ConsumerState<ActiveWorkoutScreen> {
  late final ActiveWorkoutController _controller;
  bool _popped = false;
  late final AppLifecycleListener _lifecycleListener;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    _controller = ActiveWorkoutController(
      template: widget.template,
      voice: ref.read(voiceServiceProvider),
      history: ref.read(historyRepositoryProvider),
    );
    _controller.state.addListener(_onState);
    _controller.start();
    _lifecycleListener = AppLifecycleListener(
      onPause: () => _controller.saveProgress(),
      onDetach: () => _controller.saveProgress(),
    );
  }

  void _onState() {
    final s = _controller.state.value;
    if (s.phase == WorkoutPhase.done && !_popped) {
      _popped = true;
      final save = _controller.saveFuture;
      (save ?? Future<void>.value()).whenComplete(() {
        if (mounted) _showResult();
      });
    }
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    _controller.state.removeListener(_onState);
    _controller.dispose();
    _lifecycleListener.dispose();
    super.dispose();
  }

  Future<void> _stop() async {
    await _controller.stop();
    if (mounted) _showResult();
  }

  void _showResult() {
    final s = _controller.state.value;
    // Calculate sets completed (same logic as ActiveWorkoutController._doSave).
    final isComplete = s.phase == WorkoutPhase.done;
    final setsDone = isComplete
        ? widget.template.sets
        : (s.phase == WorkoutPhase.rest
              ? s.currentSet
              : (s.currentSet > 0 ? s.currentSet - 1 : 0));
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => WorkoutResultDialog(
        templateName: widget.template.name,
        exerciseType: widget.template.exerciseType,
        durationSeconds: s.totalElapsedSeconds,
        setsCompleted: setsDone,
        setsPlanned: widget.template.sets,
        completed: isComplete,
      ),
    ).then((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TimerState>(
      valueListenable: _controller.state,
      builder: (context, s, _) {
        final isDone = s.phase == WorkoutPhase.done;
        final isPaused = s.status == TimerStatus.paused;
        final phaseColor = PhasePill.colorFor(s.phase);
        final showSet =
            !isDone &&
            s.phase != WorkoutPhase.getReady &&
            s.phase != WorkoutPhase.warmup &&
            s.phase != WorkoutPhase.cooldown;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'NOW TRAINING',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(color: phaseColor, fontSize: 10),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.template.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Stop workout',
                        onPressed: _stop,
                        icon: const Icon(Icons.close_rounded),
                        style: IconButton.styleFrom(
                          foregroundColor: AppColors.onSurfaceMute,
                          backgroundColor: AppColors.surfaceHigh,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _WorkoutStatusBar(
                    color: phaseColor,
                    paused: isPaused,
                    elapsed: formatMmSs(s.totalElapsedSeconds),
                  ),
                  if (!isDone && s.phase != WorkoutPhase.getReady) ...[
                    const SizedBox(height: AppSpacing.sm),
                    SegmentedProgress(
                      total: s.totalSets,
                      current: s.currentSet,
                      color: phaseColor,
                    ),
                  ],
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final ringSize = (constraints.maxWidth - 12).clamp(
                          210.0,
                          270.0,
                        );
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ExerciseHero(
                              exerciseType: widget.template.exerciseType,
                              color: phaseColor,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            PhasePill(phase: s.phase),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              _phaseDescription(s.phase),
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            if (isDone)
                              const _DoneCheck()
                            else if (s.phase == WorkoutPhase.getReady)
                              _GetReadyCountdown(
                                remaining: s.phaseRemainingSeconds,
                              )
                            else
                              PhaseProgressRing(
                                progress: s.phaseProgress,
                                color: phaseColor,
                                size: ringSize,
                                strokeWidth: 14,
                                child: FittedBox(
                                  child: Text(
                                    s.phaseRemainingSeconds >= 60
                                        ? formatMmSs(s.phaseRemainingSeconds)
                                        : s.phaseRemainingSeconds.toString(),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.displayLarge,
                                  ),
                                ),
                              ),
                            if (showSet) ...[
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                'ROUND ${s.currentSet} / ${s.totalSets}',
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: AppColors.onSurfaceMute,
                                      letterSpacing: 1.8,
                                    ),
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                  ),
                  if (!isDone) ...[
                    _ElapsedBadge(value: formatMmSs(s.totalElapsedSeconds)),
                    const SizedBox(height: AppSpacing.md),
                    _controls(isPaused, phaseColor),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _phaseDescription(WorkoutPhase phase) {
    switch (phase) {
      case WorkoutPhase.getReady:
        return 'Find your position. The session starts soon.';
      case WorkoutPhase.warmup:
        return 'Ease in and prepare your body.';
      case WorkoutPhase.work:
        return 'Stay steady. Follow the cue.';
      case WorkoutPhase.rest:
        return 'Breathe. Your next round is coming.';
      case WorkoutPhase.cooldown:
        return 'Slow down and let your body recover.';
      case WorkoutPhase.done:
        return 'That session is in the books.';
    }
  }

  Widget _controls(bool isPaused, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        CircleControlButton(
          icon: isPaused ? Icons.play_arrow : Icons.pause,
          label: isPaused ? 'Resume' : 'Pause',
          color: color,
          onPressed: () =>
              isPaused ? _controller.resume() : _controller.pause(),
        ),
        CircleControlButton(
          icon: Icons.skip_next_rounded,
          label: 'Skip',
          color: color,
          onPressed: _controller.skip,
        ),
        CircleControlButton(
          icon: Icons.stop_rounded,
          label: 'Stop',
          color: AppColors.destructive,
          onPressed: _stop,
        ),
      ],
    );
  }
}

class _WorkoutStatusBar extends StatelessWidget {
  const _WorkoutStatusBar({
    required this.color,
    required this.paused,
    required this.elapsed,
  });

  final Color color;
  final bool paused;
  final String elapsed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(
            paused ? Icons.pause_circle_outline : Icons.graphic_eq_rounded,
            color: paused ? AppColors.warmup : color,
            size: 19,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              paused ? 'Session paused' : 'Audio cues on · keep moving',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Text(
            elapsed,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _ElapsedBadge extends StatelessWidget {
  const _ElapsedBadge({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.timer_outlined, size: 17, color: AppColors.onSurfaceMute),
        const SizedBox(width: AppSpacing.xs),
        Text(
          'ACTIVE $value',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.onSurfaceMute,
            letterSpacing: 1.4,
          ),
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

class _DoneCheckState extends State<_DoneCheck>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  );
  late final Animation<double> _scale = Tween(
    begin: 0.0,
    end: 1.0,
  ).chain(CurveTween(curve: Curves.easeOutCubic)).animate(_ctrl);
  late final Animation<double> _fade = Tween(
    begin: 0.0,
    end: 1.0,
  ).chain(CurveTween(curve: Curves.easeOutCubic)).animate(_ctrl);

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
  late final Animation<double> _scale = Tween<double>(
    begin: 1.0,
    end: 1.07,
  ).chain(CurveTween(curve: Curves.easeOut)).animate(_ctrl);

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
