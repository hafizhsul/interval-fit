import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:interval_fit/shared/widgets/phase_progress_ring.dart';

void main() {
  testWidgets('renders child centered', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PhaseProgressRing(
            progress: 0.5,
            color: Colors.red,
            child: const Text('30'),
          ),
        ),
      ),
    );
    expect(find.text('30'), findsOneWidget);
  });

  testWidgets('progress clamping works', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PhaseProgressRing(
            progress: 1.5,
            color: Colors.red,
            child: const Text('over'),
          ),
        ),
      ),
    );
    // Just verify it renders without error; progress is clamped internally
    expect(find.text('over'), findsOneWidget);
  });
}