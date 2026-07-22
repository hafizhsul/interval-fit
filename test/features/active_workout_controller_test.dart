import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:interval_fit/core/timer_engine.dart';
import 'package:interval_fit/core/voice_service.dart';
import 'package:interval_fit/data/models/workout_session.dart';
import 'package:interval_fit/data/models/workout_template.dart';
import 'package:interval_fit/data/repositories/history_repository.dart';
import 'package:interval_fit/features/active_workout/active_workout_controller.dart';

class _FakeTts implements Tts {
  final spoken = <String>[];
  @override
  Future<void> speak(String text) async => spoken.add(text);
  @override
  Future<void> initLocale() async {}
}

class _NoBeep implements BeepPlayer {
  @override
  Future<void> beep() async {}
}

class FakeClock implements ElapsedClock {
  int _ms = 0;
  bool _running = false;
  void advance(Duration d) {
    if (_running) _ms += d.inMilliseconds;
  }

  @override
  Duration get elapsed => Duration(milliseconds: _ms);
  @override
  void start() => _running = true;
  @override
  void stop() => _running = false;
  @override
  void reset() => _ms = 0;
}

class MockHistory extends Mock implements HistoryRepository {}

class FakeSession extends Fake implements WorkoutSession {}

WorkoutTemplate _tpl() => WorkoutTemplate(
      id: 1,
      name: 'Test',
      exerciseType: 'skipping',
      sets: 2,
      workSeconds: 10,
      restSeconds: 5,
      createdAt: 0,
    );

void main() {
  setUpAll(() => registerFallbackValue(FakeSession()));

  late MockHistory history;
  late FakeClock clock;

  setUp(() {
    history = MockHistory();
    clock = FakeClock();
    when(() => history.insertSession(any())).thenAnswer(
      (i) async => i.positionalArguments[0] as WorkoutSession,
    );
  });

  ActiveWorkoutController build() => ActiveWorkoutController(
        template: _tpl(),
        voice: VoiceService(tts: _FakeTts(), beep: _NoBeep()),
        history: history,
        clock: clock,
      );

  test('sesi selesai penuh tersimpan completed=true, sekali saja', () async {
    final c = build();
    c.start();
    // Skip semua fase sampai done (skip() memanggil tick internal).
    while (c.state.value.phase != WorkoutPhase.done) {
      c.skip();
    }
    await Future<void>.delayed(Duration.zero);

    final captured =
        verify(() => history.insertSession(captureAny())).captured;
    expect(captured.length, 1);
    final s = captured.first as WorkoutSession;
    expect(s.completed, true);
    expect(s.setsCompleted, 2);
    expect(s.setsPlanned, 2);
    c.dispose();
  });

  test('stop di tengah tersimpan completed=false dengan set parsial', () async {
    final c = build();
    c.start();
    // masih di set 1 work
    await c.stop();

    final captured =
        verify(() => history.insertSession(captureAny())).captured;
    expect(captured.length, 1);
    final s = captured.first as WorkoutSession;
    expect(s.completed, false);
    expect(s.setsCompleted, 0); // belum ada set tuntas
    expect(s.setsPlanned, 2);
    c.dispose();
  });

  test('stop di fase rest set N → setsCompleted = N (work set N sudah tuntas)',
      () async {
    // Bug lama: stop di rest N menghitung N-1 (currentSet-1). Padahal work set N
    // sudah selesai saat rest N jalan → harusnya N.
    final c = build();
    c.start();
    // Segmen: getReady(3) → work set 1(10) → rest set 1(5) → work set 2(10) → done
    c.skip(); // getReady → work set 1
    c.skip(); // work set 1 → rest set 1
    expect(c.state.value.phase, WorkoutPhase.rest);
    expect(c.state.value.currentSet, 1);
    await c.stop();

    final captured =
        verify(() => history.insertSession(captureAny())).captured;
    final s = captured.first as WorkoutSession;
    expect(s.completed, false);
    expect(s.setsCompleted, 1); // work set 1 tuntas; stop di rest set 1
    c.dispose();
  });

  test('saveFuture await sebelum pop — cegah race pop vs save', () async {
    final c = build();
    c.start();
    while (c.state.value.phase != WorkoutPhase.done) {
      c.skip();
    }
    // Controller _onState fire _save async; saveFuture harus ter-set &
    // resolve sebelum screen pop. Pastikan getter ini exposed & completed.
    expect(c.saveFuture, isNotNull);
    await c.saveFuture;
    verify(() => history.insertSession(any())).called(1);
    c.dispose();
  });
}
