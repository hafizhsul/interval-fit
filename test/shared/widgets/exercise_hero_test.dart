import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:interval_fit/shared/widgets/exercise_hero.dart';

void main() {
  testWidgets('renders for skipping type', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ExerciseHero(exerciseType: 'skipping', color: Colors.orange),
        ),
      ),
    );
    await tester.pump();
    // Image.asset triggers an asset-not-found error in test env;
    // catch it so it doesn't fail the test.
    tester.takeException();
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('falls back to custom for unknown type', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ExerciseHero(exerciseType: 'yoga', color: Colors.orange),
        ),
      ),
    );
    await tester.pump();
    tester.takeException();
    expect(find.byType(Image), findsOneWidget);
  });
}
