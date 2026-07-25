import 'dart:async';

import 'package:flutter/foundation.dart';

/// Fase dalam satu sesi interval.
/// getReady = hitung mundur "bersiap" sebelum sesi benar-benar mulai.
enum WorkoutPhase { getReady, warmup, work, rest, cooldown, done }

/// Status runtime engine.
enum TimerStatus { idle, running, paused, finished }

/// Konfigurasi sesi — dibangun dari workout_template.
/// Semua durasi dalam detik (lihat skema DB: durasi disimpan detik).
@immutable
class WorkoutConfig {
  final int sets;
  final int workSeconds;
  final int restSeconds;
  final int warmupSeconds; // 0 = tidak ada
  final int cooldownSeconds; // 0 = tidak ada
  final int getReadySeconds; // 0 = tidak ada; hitung mundur bersiap di awal

  const WorkoutConfig({
    required this.sets,
    required this.workSeconds,
    required this.restSeconds,
    this.warmupSeconds = 0,
    this.cooldownSeconds = 0,
    this.getReadySeconds = 0,
  }) : assert(sets > 0),
       assert(workSeconds > 0);
}

/// Satu segmen waktu dalam urutan sesi.
@immutable
class _Segment {
  final WorkoutPhase phase;
  final int seconds;
  final int setNumber; // 1-based untuk work/rest; 0 untuk warmup/cooldown
  const _Segment(this.phase, this.seconds, this.setNumber);
}

/// Snapshot state untuk UI.
@immutable
class TimerState {
  final WorkoutPhase phase;
  final TimerStatus status;
  final int currentSet; // 1-based; 0 saat warmup/cooldown/done
  final int totalSets;
  final int phaseRemainingSeconds; // ceil sisa detik fase berjalan
  final int phaseTotalSeconds; // durasi penuh fase berjalan (untuk progress ring)
  final int totalElapsedSeconds; // waktu aktif (exclude pause)

  const TimerState({
    required this.phase,
    required this.status,
    required this.currentSet,
    required this.totalSets,
    required this.phaseRemainingSeconds,
    required this.phaseTotalSeconds,
    required this.totalElapsedSeconds,
  });

  /// Fraksi fase yang sudah berlalu (0..1) — untuk progress ring (FR-2).
  double get phaseProgress {
    if (phaseTotalSeconds <= 0) return 0;
    final done = phaseTotalSeconds - phaseRemainingSeconds;
    return (done / phaseTotalSeconds).clamp(0.0, 1.0);
  }

  static const idle = TimerState(
    phase: WorkoutPhase.warmup,
    status: TimerStatus.idle,
    currentSet: 0,
    totalSets: 0,
    phaseRemainingSeconds: 0,
    phaseTotalSeconds: 0,
    totalElapsedSeconds: 0,
  );

  TimerState _copy({
    WorkoutPhase? phase,
    TimerStatus? status,
    int? currentSet,
    int? totalSets,
    int? phaseRemainingSeconds,
    int? phaseTotalSeconds,
    int? totalElapsedSeconds,
  }) => TimerState(
    phase: phase ?? this.phase,
    status: status ?? this.status,
    currentSet: currentSet ?? this.currentSet,
    totalSets: totalSets ?? this.totalSets,
    phaseRemainingSeconds: phaseRemainingSeconds ?? this.phaseRemainingSeconds,
    phaseTotalSeconds: phaseTotalSeconds ?? this.phaseTotalSeconds,
    totalElapsedSeconds: totalElapsedSeconds ?? this.totalElapsedSeconds,
  );
}

/// Sumber waktu aktif monotonic. Pause = stop, resume = start —
/// durasi pause otomatis tidak terhitung. Diinject supaya test bisa
/// fast-forward tanpa wall-clock (kunci unit test presisi).
abstract class ElapsedClock {
  Duration get elapsed;
  void start();
  void stop();
  void reset();
}

/// Prod: bungkus `Stopwatch` (monotonic, tahan perubahan jam sistem —
/// PRD sec 9: pakai referensi absolut, bukan hitung dari tick count).
class StopwatchClock implements ElapsedClock {
  final Stopwatch _sw = Stopwatch();
  @override
  Duration get elapsed => _sw.elapsed;
  @override
  void start() => _sw.start();
  @override
  void stop() => _sw.stop();
  @override
  void reset() => _sw.reset();
}

/// Engine timer interval — logic inti, terpisah total dari UI (bisa
/// di-unit-test tanpa render). Voice TIDAK dipanggil di sini; engine hanya
/// expose callback supaya IO/TTS terpisah dan testable.
class TimerEngine {
  TimerEngine({
    required WorkoutConfig config,
    ElapsedClock? clock,
    this.tickInterval = const Duration(milliseconds: 80),
    this.onCountdown,
    this.onThirtySeconds,
    this.onPhaseChange,
    this.onComplete,
    bool dropLastRest = true,
  }) : _clock = clock ?? StopwatchClock(),
       _segments = _buildSegments(config, dropLastRest),
       _totalSets = config.sets {
    final first = _segments.first;
    _state = ValueNotifier(TimerState(
      phase: first.phase,
      status: TimerStatus.idle,
      currentSet: first.setNumber,
      totalSets: config.sets,
      phaseRemainingSeconds: first.seconds,
      phaseTotalSeconds: first.seconds,
      totalElapsedSeconds: 0,
    ));
  }

  final ElapsedClock _clock;
  final Duration tickInterval;
  final List<_Segment> _segments;
  final int _totalSets;

  /// Dipanggil tepat sekali saat sisa fase melewati 3, 2, 1 detik.
  final void Function(int secondsLeft)? onCountdown;

  /// Dipanggil tepat sekali saat sisa fase melewati 30 detik (reminder).
  final void Function()? onThirtySeconds;

  /// Dipanggil tepat sekali saat sesi selesai (semua fase habis).
  final void Function()? onComplete;

  /// Dipanggil saat transisi fase (untuk cue "istirahat"/"mulai").
  final void Function(WorkoutPhase from, WorkoutPhase to)? onPhaseChange;

  late final ValueNotifier<TimerState> _state;
  ValueListenable<TimerState> get state => _state;

  Timer? _ticker;
  int _index = 0;
  // Elapsed (ms) di mana segmen berjalan dimulai. Carry-over eksak: bukan
  // di-reset ke `now`, tapi ditambah durasi segmen -> drift tidak akumulasi.
  int _segmentStartMs = 0;
  final Set<int> _countdownFired = {};
  final Set<int> _thirtyFired = {};

  static List<_Segment> _buildSegments(WorkoutConfig c, bool dropLastRest) {
    final segs = <_Segment>[];
    if (c.getReadySeconds > 0) {
      segs.add(_Segment(WorkoutPhase.getReady, c.getReadySeconds, 0));
    }
    if (c.warmupSeconds > 0) {
      segs.add(_Segment(WorkoutPhase.warmup, c.warmupSeconds, 0));
    }
    for (var set = 1; set <= c.sets; set++) {
      segs.add(_Segment(WorkoutPhase.work, c.workSeconds, set));
      final isLast = set == c.sets;
      if (c.restSeconds > 0 && !(isLast && dropLastRest)) {
        segs.add(_Segment(WorkoutPhase.rest, c.restSeconds, set));
      }
    }
    if (c.cooldownSeconds > 0) {
      segs.add(_Segment(WorkoutPhase.cooldown, c.cooldownSeconds, 0));
    }
    return segs;
  }

  void start() {
    if (_state.value.status == TimerStatus.running) return;
    _clock.start();
    _state.value = _state.value._copy(status: TimerStatus.running);
    _ticker ??= Timer.periodic(tickInterval, (_) => tick());
    tick();
  }

  void pause() {
    if (_state.value.status != TimerStatus.running) return;
    _clock.stop();
    _state.value = _state.value._copy(status: TimerStatus.paused);
  }

  void resume() {
    if (_state.value.status != TimerStatus.paused) return;
    _clock.start();
    _state.value = _state.value._copy(status: TimerStatus.running);
  }

  /// Loncat ke segmen berikut, sisa waktu dibuang.
  void skip() {
    if (_index >= _segments.length) return;
    // Advance dulu (menaikkan _index + carry-over internal), lalu ANCHOR segmen
    // baru ke waktu sekarang. Urutan ini penting: _advance() menambah durasi
    // segmen berjalan ke _segmentStartMs (benar untuk transisi alami), tapi untuk
    // skip kita buang sisa waktu -> segmen baru harus mulai dari `now`, bukan
    // now + durasi segmen sebelumnya. Bug lama: set now SEBELUM _advance() bikin
    // fase berikutnya mulai 1 segmen di masa depan (remaining jadi dobel).
    _advance();
    _segmentStartMs = _clock.elapsed.inMilliseconds;
    tick();
  }

  void stop() {
    _ticker?.cancel();
    _ticker = null;
    _clock.stop();
    _state.value = _state.value._copy(status: TimerStatus.finished);
  }

  void dispose() {
    _ticker?.cancel();
    _ticker = null;
    _state.dispose();
  }

  /// Advance ke segmen berikut dengan carry-over eksak.
  /// Return false kalau sudah habis (done).
  bool _advance() {
    final prev = _segments[_index].phase;
    _segmentStartMs += _segments[_index].seconds * 1000;
    _index++;
    _countdownFired.clear();
    _thirtyFired.clear();
    if (_index >= _segments.length) {
      _ticker?.cancel();
      _ticker = null;
      _clock.stop();
      _state.value = _state.value._copy(
        phase: WorkoutPhase.done,
        status: TimerStatus.finished,
        currentSet: 0,
        phaseRemainingSeconds: 0,
      );
      onPhaseChange?.call(prev, WorkoutPhase.done);
      onComplete?.call();
      return false;
    }
    onPhaseChange?.call(prev, _segments[_index].phase);
    return true;
  }

  /// Satu langkah waktu. Dipanggil Timer.periodic (prod) atau langsung (test).
  void tick() {
    final status = _state.value.status;
    if (status != TimerStatus.running) return;
    if (_index >= _segments.length) return;

    final nowMs = _clock.elapsed.inMilliseconds;

    // Bisa lewati >1 segmen kalau tick besar (segmen pendek).
    while (_index < _segments.length) {
      final seg = _segments[_index];
      final inSegMs = nowMs - _segmentStartMs;
      final remainingMs = seg.seconds * 1000 - inSegMs;

      if (remainingMs <= 0) {
        if (!_advance()) return; // done
        continue;
      }

      // Countdown 3,2,1 — fire sekali per nilai, guard set.
      for (final n in const [3, 2, 1]) {
        if (remainingMs <= n * 1000 && _countdownFired.add(n)) {
          onCountdown?.call(n);
        }
      }

      // 30-second reminder during work phase only.
      if (remainingMs <= 30 * 1000 && _thirtyFired.add(seg.seconds) && seg.phase == WorkoutPhase.work) {
        onThirtySeconds?.call();
      }

      _state.value = _state.value._copy(
        phase: seg.phase,
        currentSet: seg.setNumber,
        totalSets: _totalSets,
        phaseRemainingSeconds: (remainingMs / 1000).ceil(),
        phaseTotalSeconds: seg.seconds,
        totalElapsedSeconds: (nowMs / 1000).floor(),
      );
      return;
    }
  }
}
