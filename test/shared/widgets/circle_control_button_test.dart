import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:interval_fit/shared/widgets/circle_control_button.dart';

void main() {
  testWidgets('renders icon and label', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CircleControlButton(
            icon: Icons.pause,
            label: 'Pause',
            color: Colors.red,
            onPressed: () {},
          ),
        ),
      ),
    );
    expect(find.byIcon(Icons.pause), findsOneWidget);
    expect(find.text('Pause'), findsOneWidget);
  });

  testWidgets('fires onPressed on tap', (tester) async {
    var tapped = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CircleControlButton(
            icon: Icons.pause,
            label: 'Pause',
            color: Colors.red,
            onPressed: () => tapped++,
          ),
        ),
      ),
    );
    await tester.tap(find.byIcon(Icons.pause));
    expect(tapped, 1);
  });

  testWidgets('meets 48dp touch target minimum', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CircleControlButton(
            icon: Icons.pause,
            label: 'Pause',
            color: Colors.red,
            onPressed: () {},
          ),
        ),
      ),
    );
    final box = tester.getSize(find.byType(CircleControlButton));
    expect(box.width >= 48, true);
    expect(box.height >= 48, true);
  });
}