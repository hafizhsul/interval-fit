import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:interval_fit/core/providers.dart';
import 'package:interval_fit/data/models/workout_template.dart';
import 'package:interval_fit/data/repositories/template_repository.dart';
import 'package:interval_fit/features/template_builder/template_builder_screen.dart';
import 'package:mocktail/mocktail.dart';

class MockTemplateRepository extends Mock implements TemplateRepository {}

class FakeTemplate extends Fake implements WorkoutTemplate {}

void main() {
  setUpAll(() => registerFallbackValue(FakeTemplate()));

  Future<MockTemplateRepository> pump(WidgetTester tester) async {
    final repo = MockTemplateRepository();
    when(() => repo.create(any())).thenAnswer(
      (i) async => i.positionalArguments.first as WorkoutTemplate,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [templateRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(home: TemplateBuilderScreen()),
      ),
    );
    return repo;
  }

  testWidgets('validation blocks empty name — no save', (tester) async {
    final repo = await pump(tester);
    // Leave name empty (default is empty), tap Save.
    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pump();

    expect(find.text('Name is required'), findsOneWidget);
    verifyNever(() => repo.create(any()));
  });

  testWidgets('converts minutes to seconds on save', (tester) async {
    final repo = await pump(tester);

    await tester.enterText(find.widgetWithText(TextFormField, 'Name'), 'Test');

    // Work = 2 with unit minutes -> should become 120 seconds.
    final workField = find.widgetWithText(TextFormField, 'Work');
    await tester.enterText(workField, '2');
    // Open the first unit dropdown (Work) and pick minutes.
    await tester.tap(find.text('sec').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('min').last);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final captured = verify(() => repo.create(captureAny())).captured;
    expect(captured, isNotEmpty);
    final saved = captured.first as WorkoutTemplate;
    expect(saved.name, 'Test');
    expect(saved.workSeconds, 120);
  });

  testWidgets('accepts decimal minutes with comma: 1,2 mnt -> 72 detik',
      (tester) async {
    final repo = await pump(tester);

    await tester.enterText(find.widgetWithText(TextFormField, 'Name'), 'Test');

    final workField = find.widgetWithText(TextFormField, 'Work');
    await tester.enterText(workField, '1,2');
    await tester.tap(find.text('sec').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('min').last);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final saved = verify(() => repo.create(captureAny())).captured.first
        as WorkoutTemplate;
    // 1,2 menit = 72 detik. Sebelum fix, digitsOnly membuang koma -> 12 mnt.
    expect(saved.workSeconds, 72);
  });
}
