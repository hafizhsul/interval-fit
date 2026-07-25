import 'package:flutter/foundation.dart';

import '../../data/models/workout_session.dart';
import '../../data/models/workout_template.dart';
import '../../data/repositories/history_repository.dart';
import '../../core/background_service.dart';
import '../../core/timer_engine.dart';
import '../../core/voice_service.dart';

/// Menyatukan TimerEngine + VoiceService + penyimpanan sesi.
/// Ini glue paling rawan (lead-written): pastikan sesi tersimpan sekali saja,
/// baik selesai penuh maupun stop di tengah (FR-6), dengan durasi aktif akurat.
class ActiveWorkoutController {
  ActiveWorkoutController({
    required WorkoutTemplate template,
    required VoiceService voice,
    required HistoryRepository history,
    ElapsedClock? clock,
  })  : _template = template,
        // ignore: prefer_initializing_formals — field private + named param, tak bisa formal
        _voice = voice,
        // ignore: prefer_initializing_formals
        _history = history,
        _startedAtMs = DateTime.now().millisecondsSinceEpoch {
    _engine = TimerEngine(
      config: WorkoutConfig(
        sets: template.sets,
        workSeconds: template.workSeconds,
        restSeconds: template.restSeconds,
        warmupSeconds: template.warmupSeconds,
        cooldownSeconds: template.cooldownSeconds,
        getReadySeconds: 3, // pre-start "get ready" 3-2-1 countdown
      ),
      clock: clock,
      onCountdown: (n) => _voice.speakCountdown(n),
      onPhaseChange: _onPhaseChange,
      onThirtySeconds: _voice.speakThirtySeconds,
      onComplete: _voice.playCompleteSound,
    );
    _engine.state.addListener(_onState);
  }

  final WorkoutTemplate _template;
  final VoiceService _voice;
  final HistoryRepository _history;
  final int _startedAtMs;

  late final TimerEngine _engine;
  ValueListenable<TimerState> get state => _engine.state;

  /// Future save sesi (null sebelum save dimulai). Screen await ini sebelum
  /// pop supaya DB insert tuntas walau device lambat — cegah save hilang kalau
  /// app di-kill dalam jendela 1s antara done → pop → dispose.
  Future<void>? _saveFuture;
  Future<void>? get saveFuture => _saveFuture;

  void start() {
    BackgroundKeepAlive.start(); // FGS: timer+voice hidup saat layar terkunci (FR-4)
    // Cue "get ready" untuk fase pre-start; 3-2-1 menyusul via onCountdown,
    // lalu "start" saat transisi ke work. Fase getReady tak punya transisi
    // masuk (ia segmen pertama), jadi cue-nya diucap manual di sini.
    if (_engine.state.value.phase == WorkoutPhase.getReady) {
      _voice.speakGetReady();
    }
    _engine.start();
  }

  void pause() => _engine.pause();
  void resume() => _engine.resume();
  void skip() => _engine.skip();

  /// Stop manual — simpan progress parsial lalu emit finished (FR-6).
  Future<void> stop() async {
    _engine.stop();
    await _save(completed: false);
  }

  void _onPhaseChange(WorkoutPhase from, WorkoutPhase to) {
    // Cue transisi (mulai/istirahat). Engine sudah fire 3,2,1 sebelum ini.
    _voice.speakPhaseCue(to);
  }

  void _onState() {
    // Auto-save saat sesi selesai alami (semua fase habis -> done/finished).
    final s = _engine.state.value;
    if (s.phase == WorkoutPhase.done && s.status == TimerStatus.finished) {
      _save(completed: true);
    }
  }

  /// Guard against rapid duplicate saves from lifecycle events (lock/unlock).
  int _lastSaveProgressMs = 0;

  /// Save current progress without stopping the engine.
  /// Called when app lifecycle indicates potential termination.
  Future<void> saveProgress() async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    if (nowMs - _lastSaveProgressMs < 5000) return;
    _lastSaveProgressMs = nowMs;
    final s = _engine.state.value;
    if (s.phase == WorkoutPhase.done) return;
    final setsCompleted = s.phase == WorkoutPhase.rest
        ? s.currentSet
        : (s.currentSet > 0 ? s.currentSet - 1 : 0);
    await _history.insertSession(WorkoutSession(
      templateId: _template.id,
      templateName: _template.name,
      exerciseType: _template.exerciseType,
      startedAt: _startedAtMs,
      durationSeconds: s.totalElapsedSeconds,
      setsPlanned: _template.sets,
      setsCompleted: setsCompleted,
      completed: false,
    ));
  }

  /// Idempoten: pemanggilan kedua return Future yang sama. `_saveFuture` sebagai
  /// guard sekaligus handle yang ditunggu screen sebelum pop (cegah race pop vs save).
  Future<void> _save({required bool completed}) {
    final existing = _saveFuture;
    if (existing != null) return existing;
    final f = _doSave(completed: completed);
    _saveFuture = f;
    return f;
  }

  Future<void> _doSave({required bool completed}) async {
    BackgroundKeepAlive.stop(); // sesi berakhir (selesai/stop) -> matikan FGS
    final s = _engine.state.value;
    // Set selesai: fase done => semua set; kalau stop di tengah pakai currentSet-1
    // untuk set yang belum tuntas, minimal 0.
    // Saat stop di fase rest set N, work set N sudah selesai → setsCompleted = N
    // (bukan N-1). Hanya fase work yang diistimewakan: stop di work N = N-1 tuntas.
    final setsCompleted = completed
        ? _template.sets
        : (s.phase == WorkoutPhase.rest
            ? s.currentSet
            : (s.currentSet > 0 ? s.currentSet - 1 : 0));
    await _history.insertSession(WorkoutSession(
      templateId: _template.id,
      templateName: _template.name,
      exerciseType: _template.exerciseType,
      startedAt: _startedAtMs,
      durationSeconds: s.totalElapsedSeconds,
      setsPlanned: _template.sets,
      setsCompleted: setsCompleted,
      completed: completed,
    ));
  }

  void dispose() {
    _engine.state.removeListener(_onState);
    _engine.dispose();
  }
}
