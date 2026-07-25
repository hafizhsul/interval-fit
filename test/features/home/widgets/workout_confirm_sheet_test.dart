import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:interval_fit/features/home/widgets/workout_confirm_sheet.dart';
import 'package:interval_fit/data/models/workout_template.dart';

void main() {
  final template = WorkoutTemplate(
    id: 1,
    name: 'Test Workout',
    exerciseType: 'skipping',
    sets: 10,
    workSeconds: 30,
    restSeconds: 30,
    warmupSeconds: 0,
    cooldownSeconds: 0,
    createdAt: 0,
  );

  testWidgets('shows template name and details', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: WorkoutConfirmSheet(template: template)),
    ));
    expect(find.text('Test Workout'), findsOneWidget);
    expect(find.text('10'), findsOneWidget);
    expect(find.text('30s'), findsNWidgets(2));
  });
}
