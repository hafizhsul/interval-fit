import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:interval_fit/core/providers.dart';
import 'package:interval_fit/features/home/home_screen.dart';

void main() {
  testWidgets('App shell renders HomeScreen with app title', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          templateListProvider.overrideWith((ref) async => []),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('INTERVALFIT'), findsOneWidget);
  });
}
