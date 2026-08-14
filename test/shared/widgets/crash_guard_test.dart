import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:interval_fit/shared/widgets/crash_guard.dart';

class _Throws extends StatelessWidget {
  const _Throws({this.message = 'boom'});

  final String message;

  @override
  Widget build(BuildContext context) => throw StateError(message);
}

void main() {
  testWidgets('swaps to fallback when child build throws', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CrashGuard(fallback: Text('recovered'), child: _Throws()),
      ),
    );

    // The build error was recorded by the framework...
    expect(tester.takeException(), isA<StateError>());

    // ...and the guard swapped to the fallback on the next frame.
    await tester.pump();
    expect(find.text('recovered'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('passes through when child builds fine', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CrashGuard(fallback: Text('recovered'), child: Text('ok')),
      ),
    );

    expect(find.text('ok'), findsOneWidget);
    expect(find.text('recovered'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('does not loop when the fallback itself throws', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CrashGuard(
          fallback: _Throws(message: 'second'),
          child: _Throws(message: 'first'),
        ),
      ),
    );
    expect(tester.takeException(), isA<StateError>());

    await tester.pump();
    // Fallback threw too — the error surfaces normally instead of the guard
    // catching it again and re-recovering forever.
    expect(tester.takeException(), isA<StateError>());

    // One more frame: still the error widget, no infinite rebuild loop.
    await tester.pump();
    expect(find.byType(ErrorWidget), findsOneWidget);
  });
}
