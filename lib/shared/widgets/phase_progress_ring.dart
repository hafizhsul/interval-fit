import 'dart:math' as math;

import 'package:flutter/material.dart';

class PhaseProgressRing extends StatelessWidget {
  const PhaseProgressRing({
    super.key,
    required this.progress,
    required this.color,
    required this.child,
    this.size = 280,
    this.strokeWidth = 16,
  });

  final double progress;
  final Color color;
  final Widget child;
  final double size;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: PhaseRingPainter(
          progress: progress,
          color: color,
          strokeWidth: strokeWidth,
          trackColor: Theme.of(context).colorScheme.outline,
        ),
        child: Padding(
          padding: EdgeInsets.all(strokeWidth * 2.5),
          child: Center(child: child),
        ),
      ),
    );
  }
}

class PhaseRingPainter extends CustomPainter {
  PhaseRingPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
    required this.trackColor,
  });

  final double progress;
  final Color color;
  final double strokeWidth;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - strokeWidth) / 2;
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = trackColor;
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
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
  bool shouldRepaint(PhaseRingPainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.trackColor != trackColor;
}
