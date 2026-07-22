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
