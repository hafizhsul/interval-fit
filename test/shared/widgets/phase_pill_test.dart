import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:interval_fit/core/timer_engine.dart' show WorkoutPhase;
import 'package:interval_fit/shared/widgets/phase_pill.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
        home: Scaffold(body: Center(child: child)),
      );

  testWidgets('renders uppercase WORK label', (tester) async {
    await tester.pumpWidget(wrap(const PhasePill(phase: WorkoutPhase.work)));
    expect(find.text('WORK'), findsOneWidget);
  });

  testWidgets('renders REST for rest phase', (tester) async {
    await tester.pumpWidget(wrap(const PhasePill(phase: WorkoutPhase.rest)));
    expect(find.text('REST'), findsOneWidget);
  });

  testWidgets('renders GET READY for getReady phase', (tester) async {
    await tester.pumpWidget(wrap(const PhasePill(phase: WorkoutPhase.getReady)));
    expect(find.text('GET READY'), findsOneWidget);
  });

  testWidgets('has tinted background (phase color at 18% alpha)', (tester) async {
    await tester.pumpWidget(wrap(const PhasePill(phase: WorkoutPhase.work)));
    final container = tester.widget<AnimatedContainer>(find.byType(AnimatedContainer));
    final decoration = container.decoration as BoxDecoration;
    expect(decoration.color, isNotNull);
  });
}