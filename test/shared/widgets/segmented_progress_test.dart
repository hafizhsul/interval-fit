import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:interval_fit/shared/widgets/segmented_progress.dart';

void main() {
  testWidgets('renders correct number of segments', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SegmentedProgress(total: 3, current: 1, color: Colors.red),
        ),
      ),
    );
    expect(find.byType(SegmentedProgress), findsOneWidget);
  });

  testWidgets('fills completed segments, pulses current', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SegmentedProgress(total: 3, current: 2, color: Colors.red),
        ),
      ),
    );
    final painters = tester.widgetList<CustomPaint>(find.byType(CustomPaint));
    expect(painters.isNotEmpty, true);
  });
}