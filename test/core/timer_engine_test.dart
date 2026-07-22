import 'package:flutter_test/flutter_test.dart';
import 'package:interval_fit/core/timer_engine.dart';

/// Clock fake: waktu dikontrol manual, pause/resume ditiru seperti Stopwatch.
class FakeClock implements ElapsedClock {
  int _ms = 0;
  bool _running = false;

  /// Majukan waktu hanya kalau sedang running (meniru Stopwatch: pause = beku).
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

/// Engine tanpa Timer.periodic auto: kita panggil tick() manual tiap advance.
TimerEngine _engine(
  WorkoutConfig config, {
  FakeClock? clock,
  void Function(int)? onCountdown,
  void Function(WorkoutPhase, WorkoutPhase)? onPhaseChange,
  bool dropLastRest = true,
}) {
  return TimerEngine(
    config: config,
    clock: clock ?? FakeClock(),
    onCountdown: onCountdown,
    onPhaseChange: onPhaseChange,
    dropLastRest: dropLastRest,
  );
}

void main() {
  test('urutan fase benar: warmup -> (work,rest)xN -> cooldown, drop rest terakhir', () {
    final transitions = <String>[];
    final clock = FakeClock();
    final e = _engine(
      const WorkoutConfig(
        sets: 2,
        workSeconds: 10,
        restSeconds: 5,
        warmupSeconds: 3,
        cooldownSeconds: 4,
      ),
      clock: clock,
      onPhaseChange: (f, t) => transitions.add(t.name),
    );
    e.start();
    // Advance melewati seluruh sesi dalam step 1s.
    for (var i = 0; i < 40; i++) {
      clock.advance(const Duration(seconds: 1));
      e.tick();
    }
    // warmup(3) work(10) rest(5) work(10) [rest drop] cooldown(4) = 32s
    expect(transitions, ['work', 'rest', 'work', 'cooldown', 'done']);
    expect(e.state.value.phase, WorkoutPhase.done);
    expect(e.state.value.status, TimerStatus.finished);
    e.dispose();
  });

  test('remaining tepat & transisi saat remaining<=0', () {
    final clock = FakeClock();
    final e = _engine(
      const WorkoutConfig(sets: 1, workSeconds: 5, restSeconds: 0),
      clock: clock,
    );
    e.start();
    expect(e.state.value.phase, WorkoutPhase.work);
    expect(e.state.value.phaseRemainingSeconds, 5);

    clock.advance(const Duration(seconds: 2));
    e.tick();
    expect(e.state.value.phaseRemainingSeconds, 3);

    clock.advance(const Duration(seconds: 3));
    e.tick();
    // work habis (1 set, no rest) -> done
    expect(e.state.value.phase, WorkoutPhase.done);
    e.dispose();
  });

  test('countdown fire tepat sekali di 3,2,1', () {
    final fired = <int>[];
    final clock = FakeClock();
    final e = _engine(
      const WorkoutConfig(sets: 1, workSeconds: 10, restSeconds: 0),
      clock: clock,
      onCountdown: fired.add,
    );
    e.start();
    // tick tiap 500ms sampai fase habis
    for (var i = 0; i < 22; i++) {
      clock.advance(const Duration(milliseconds: 500));
      e.tick();
    }
    expect(fired, [3, 2, 1]);
    e.dispose();
  });

  test('pause/resume tidak menggeser total elapsed', () {
    final clock = FakeClock();
    final e = _engine(
      const WorkoutConfig(sets: 1, workSeconds: 20, restSeconds: 0),
      clock: clock,
    );
    e.start();
    clock.advance(const Duration(seconds: 5));
    e.tick();
    expect(e.state.value.phaseRemainingSeconds, 15);

    e.pause();
    clock.advance(const Duration(seconds: 100)); // waktu pause tidak terhitung
    e.tick();
    expect(e.state.value.phaseRemainingSeconds, 15); // tak berubah
    expect(e.state.value.status, TimerStatus.paused);

    e.resume();
    clock.advance(const Duration(seconds: 5));
    e.tick();
    expect(e.state.value.phaseRemainingSeconds, 10);
    e.dispose();
  });

  test('skip loncat ke fase berikut', () {
    final clock = FakeClock();
    final e = _engine(
      const WorkoutConfig(sets: 2, workSeconds: 30, restSeconds: 10),
      clock: clock,
    );
    e.start();
    clock.advance(const Duration(seconds: 5));
    e.tick();
    expect(e.state.value.phase, WorkoutPhase.work);
    expect(e.state.value.currentSet, 1);

    e.skip();
    expect(e.state.value.phase, WorkoutPhase.rest);
    expect(e.state.value.currentSet, 1);
    // Regresi: fase baru setelah skip harus mulai penuh dari durasinya sendiri
    // (sisa waktu fase lama dibuang), BUKAN nseg+prevSeg. Bug lama: skip bikin
    // rest tampil 40s (10+30) karena _segmentStartMs digeser ke masa depan.
    expect(e.state.value.phaseRemainingSeconds, 10);
    expect(e.state.value.phaseTotalSeconds, 10);

    // Skip lagi ke work#2 — juga harus penuh 30s, offset tak boleh terakumulasi.
    e.skip();
    expect(e.state.value.phase, WorkoutPhase.work);
    expect(e.state.value.currentSet, 2);
    expect(e.state.value.phaseRemainingSeconds, 30);
    e.dispose();
  });

  test('presisi: sesi 60 menit, deviasi <= 0.1s (tick 80ms tak-rata)', () {
    final clock = FakeClock();
    // 60 set x (30s work + 30s rest) = 60 menit. drop rest terakhir -> 3570s.
    final e = _engine(
      const WorkoutConfig(sets: 60, workSeconds: 30, restSeconds: 30),
      clock: clock,
    );
    e.start();
    // Tick 80ms — tidak selaras batas detik, uji akumulasi drift.
    const totalMs = 3570 * 1000;
    for (var t = 0; t < totalMs + 2000; t += 80) {
      clock.advance(const Duration(milliseconds: 80));
      e.tick();
    }
    expect(e.state.value.phase, WorkoutPhase.done);
    // elapsed engine harus == waktu real dalam <=100ms
    final expectedMs = 3570 * 1000;
    final actualMs = clock.elapsed.inMilliseconds;
    expect((actualMs - expectedMs).abs() <= 80, isTrue,
        reason: 'akhir sesi dalam 1 tick dari target');
    e.dispose();
  });
}
