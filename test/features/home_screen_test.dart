import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:interval_fit/core/providers.dart';
import 'package:interval_fit/data/models/workout_template.dart';
import 'package:interval_fit/features/home/home_screen.dart';
import 'package:interval_fit/shared/theme/app_theme.dart';

WorkoutTemplate _tpl(String name) => WorkoutTemplate(
      name: name,
      exerciseType: 'skipping',
      sets: 5,
      workSeconds: 30,
      restSeconds: 15,
      createdAt: 0,
    );

void main() {
  testWidgets('HomeScreen renders template list', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          templateListProvider.overrideWith(
            (ref) async => [_tpl('Lari Pagi'), _tpl('Skipping HIIT')],
          ),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Lari Pagi'), findsOneWidget);
    expect(find.text('Skipping HIIT'), findsOneWidget);
    // Summary format.
    expect(find.textContaining('5 set'), findsWidgets);
  });

  testWidgets('HomeScreen shows empty state', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          templateListProvider.overrideWith((ref) async => []),
        ],
        child: MaterialApp(theme: AppTheme.dark, home: const HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('No templates yet'), findsOneWidget);
  });
}
