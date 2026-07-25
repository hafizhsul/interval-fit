import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'timer_engine.dart' show WorkoutPhase;

/// Abstraksi TTS tipis — supaya test bisa inject mock (mocktail).
abstract class Tts {
  Future<void> speak(String text);
  Future<void> initLocale();
}

/// Abstraksi beep fallback — dipakai saat TTS gagal init (PRD risk mitigation).
abstract class BeepPlayer {
  Future<void> beep();
}

/// Impl produksi: bungkus FlutterTts. Locale fixed en-US — app English-only.
class FlutterTtsAdapter implements Tts {
  FlutterTtsAdapter([FlutterTts? tts]) : _tts = tts ?? FlutterTts();
  final FlutterTts _tts;
  @override
  Future<void> speak(String text) => _tts.speak(text);
  @override
  Future<void> initLocale() => _tts.setLanguage('en-US');
}

/// Impl produksi: beep pakai audioplayers (nada pendek dari asset).
/// ponytail: pakai satu asset beep; upgrade ke beda nada per fase kalau diminta.
class AudioPlayerBeep implements BeepPlayer {
  AudioPlayerBeep([AudioPlayer? player]) : _player = player ?? AudioPlayer() {
    _player.setAudioContext(_audioDuck);
  }
  final AudioPlayer _player;
  @override
  Future<void> beep() => _player.play(AssetSource('audio/beep.wav'));
}

final _audioDuck = AudioContext(
  android: AudioContextAndroid(
    audioFocus: AndroidAudioFocus.gainTransientMayDuck,
    usageType: AndroidUsageType.voiceCommunication,
    contentType: AndroidContentType.speech,
  ),
);

/// Voice service — cue suara untuk countdown & transisi fase.
/// Logic terpisah dari UI (unit-testable). Wired ke callback TimerEngine
/// oleh layer di atas; service ini tidak tahu-menahu soal engine.
class VoiceService {
  VoiceService({Tts? tts, BeepPlayer? beep, bool enabled = true})
      : _tts = tts ?? FlutterTtsAdapter(),
        _beep = beep ?? AudioPlayerBeep() {
    _enabled = enabled;
  }

  final Tts _tts;
  final BeepPlayer _beep;
  bool _enabled = true;
  bool _useFallback = false;

  void setEnabled(bool enabled) => _enabled = enabled;

  /// Init TTS locale. Kalau gagal -> pakai beep fallback untuk semua cue berikutnya.
  Future<void> init() async {
    try {
      await _tts.initLocale();
    } catch (_) {
      _useFallback = true;
    }
  }

  Future<void> speakCountdown(int n) => _say(n.toString());

  Future<void> speakThirtySeconds() => _say('30 seconds remaining');

  Future<void> playCompleteSound() => _beep.beep();

  Future<void> speakPhaseCue(WorkoutPhase phase) {
    final text = _cueFor(phase);
    if (text == null) return Future<void>.value(); // no-op fase tanpa cue
    return _say(text);
  }

  /// null = no cue (warmup/cooldown/done are intentionally no-op, keep simple).
  String? _cueFor(WorkoutPhase phase) {
    switch (phase) {
      case WorkoutPhase.work:
        return 'start';
      case WorkoutPhase.rest:
        return 'rest';
      case WorkoutPhase.getReady:
      case WorkoutPhase.warmup:
      case WorkoutPhase.cooldown:
      case WorkoutPhase.done:
        return null;
    }
  }

  /// Cue spoken during the pre-start "get ready" countdown.
  Future<void> speakGetReady() => _say('get ready');

  Future<void> _say(String text) {
    if (!_enabled) return Future<void>.value(); // FR-8 silent mode
    return _useFallback ? _beep.beep() : _tts.speak(text);
  }
}
