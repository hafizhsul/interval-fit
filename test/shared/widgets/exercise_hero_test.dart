import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:interval_fit/shared/widgets/exercise_hero.dart';

void main() {
  testWidgets('renders SVG for skipping', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ExerciseHero(
            exerciseType: 'skipping',
            color: Colors.orange,
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(SvgPicture), findsOneWidget);
  });

  testWidgets('falls back to custom for unknown type', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ExerciseHero(
            exerciseType: 'yoga',
            color: Colors.orange,
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(SvgPicture), findsOneWidget);
  });
}