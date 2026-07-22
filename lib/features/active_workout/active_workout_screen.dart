import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/timer_engine.dart';
import '../../data/models/workout_template.dart';
import '../../shared/format.dart';
import '../../shared/theme/app_theme.dart';
import 'active_workout_controller.dart';

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
      // Await save selesai sebelum pop — cegah save hilang kalau app di-kill
      // dalam jendela antara done → pop → dispose (device lambat / DB sibuk).
      // ponytail: 1s delay asli diganti await saveFuture; kalau save cepat, pop
      // instan. Kalau save lambat, pop nunggu — UX trade-off yang benar.
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

  Color _phaseColor(WorkoutPhase phase) {
    switch (phase) {
      case WorkoutPhase.getReady:
        return AppColors.accent;
      case WorkoutPhase.work:
        return AppColors.work;
      case WorkoutPhase.rest:
        return AppColors.rest;
      case WorkoutPhase.warmup:
        return AppColors.warmup;
      case WorkoutPhase.cooldown:
        return AppColors.cooldown;
      case WorkoutPhase.done:
        return AppColors.accent;
    }
  }

  String _phaseLabel(WorkoutPhase phase) {
    switch (phase) {
      case WorkoutPhase.getReady:
        return 'GET READY';
      case WorkoutPhase.work:
        return 'WORK';
      case WorkoutPhase.rest:
        return 'REST';
      case WorkoutPhase.warmup:
        return 'WARM-UP';
      case WorkoutPhase.cooldown:
        return 'COOLDOWN';
      case WorkoutPhase.done:
        return 'DONE!';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TimerState>(
      valueListenable: _controller.state,
      builder: (context, s, _) {
        final isDone = s.phase == WorkoutPhase.done;
        final isPaused = s.status == TimerStatus.paused;
        final color = _phaseColor(s.phase);
        // Latar gelap dengan aksen fase — angka & ring yang membawa warna,
        // bukan seluruh layar (lebih enak dilihat + hemat OLED).
        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Text(
                    _phaseLabel(s.phase),
                    style: TextStyle(
                      fontFamily: 'BarlowCondensed',
                      fontSize: 40,
                      fontWeight: FontWeight.w700,
                      color: color,
                      letterSpacing: 3,
                    ),
                  ),
                  if (!isDone && s.currentSet > 0)
                    Text(
                      'Set ${s.currentSet} / ${s.totalSets}',
                      style: const TextStyle(
                        fontSize: 20,
                        color: Colors.white70,
                      ),
                    ),
                  Expanded(
                    child: Center(
                      child: isDone
                          ? Icon(Icons.check_circle,
                              color: color, size: 160)
                          : s.phase == WorkoutPhase.getReady
                              ? _GetReadyCountdown(remaining: s.phaseRemainingSeconds)
                              : _Ring(
                                  progress: s.phaseProgress,
                                  color: color,
                                  child: FittedBox(
                                    child: Text(
                                      s.phaseRemainingSeconds >= 60
                                          ? formatMmSs(s.phaseRemainingSeconds)
                                          : s.phaseRemainingSeconds.toString(),
                                      style: Theme.of(context)
                                          .textTheme
                                          .displayLarge,
                                    ),
                                  ),
                                ),
                    ),
                  ),
                  if (!isDone) _controls(isPaused, color),
                  const SizedBox(height: 8),
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
        _CircleButton(
          icon: isPaused ? Icons.play_arrow : Icons.pause,
          label: isPaused ? 'Resume' : 'Pause',
          color: color,
          onPressed: () =>
              isPaused ? _controller.resume() : _controller.pause(),
        ),
        _CircleButton(
          icon: Icons.skip_next,
          label: 'Skip',
          color: color,
          onPressed: _controller.skip,
        ),
        _CircleButton(
          icon: Icons.stop,
          label: 'Stop',
          color: AppColors.destructive,
          onPressed: _stop,
        ),
      ],
    );
  }
}

/// Progress ring melingkar (FR-2). Isi cincin = fraksi fase yang berlalu.
class _Ring extends StatelessWidget {
  const _Ring({
    required this.progress,
    required this.color,
    required this.child,
  });

  final double progress;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      height: 260,
      child: CustomPaint(
        painter: _RingPainter(progress: progress, color: color),
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 14.0;
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - stroke) / 2;
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = AppColors.muted;
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawCircle(center, radius, track);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress.clamp(0.0, 1.0),
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color;
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.filled(
          iconSize: 36,
          onPressed: onPressed,
          icon: Icon(icon),
          tooltip: label,
          style: IconButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            minimumSize: const Size(64, 64),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(color: Colors.white70)),
      ],
    );
  }
}

/// Visual countdown besar untuk fase getReady (lihat PRD US3 — angka jelas
/// saat user akan memulai). ponytail: ring di-skip di getReady; angka 3/2/1
/// sangat besar (320px) + pulse tiap detik supaya “hidup” dan terbaca jauh.
/// Setiap kali `remaining` berubah, animasi pulse restart dari awal.
class _GetReadyCountdown extends StatefulWidget {
  const _GetReadyCountdown({required this.remaining});

  final int remaining;

  @override
  State<_GetReadyCountdown> createState() => _GetReadyCountdownState();
}

class _GetReadyCountdownState extends State<_GetReadyCountdown>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scale = Tween<double>(begin: 1.0, end: 1.07)
        .chain(CurveTween(curve: Curves.easeOut))
        .animate(_ctrl);
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(covariant _GetReadyCountdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.remaining != widget.remaining) {
      _ctrl.forward(from: 0); // pulse ulang tiap angka ganti
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

