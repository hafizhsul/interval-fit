import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'timer_engine.dart' show WorkoutPhase;

abstract class Tts {
  Future<void> speak(String text);
  Future<void> stop();
  Future<void> initLocale();
}

abstract class BeepPlayer {
  Future<void> beep();
}

class FlutterTtsAdapter implements Tts {
  FlutterTtsAdapter([FlutterTts? tts]) : _tts = tts ?? FlutterTts();

  final FlutterTts _tts;
  @override
  Future<void> speak(String text) => _tts.speak(text);
  @override
  Future<void> stop() => _tts.stop();
  @override
  Future<void> initLocale() => _tts.setLanguage('en-US');
}

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
    audioFocus: AndroidAudioFocus.gainTransient,
    usageType: AndroidUsageType.media,
    contentType: AndroidContentType.speech,
  ),
);

class VoiceService {
  VoiceService({
    Tts? tts,
    BeepPlayer? beep,
    this._focusPlayer,
    bool enabled = true,
  })  : _tts = tts ?? FlutterTtsAdapter(),
        _beep = beep ?? AudioPlayerBeep() {
    _enabled = enabled;
    _focusPlayer?.setAudioContext(_audioDuck);
  }

  final Tts _tts;
  final BeepPlayer _beep;
  final AudioPlayer? _focusPlayer;
  bool _enabled = true;
  bool _useFallback = false;

  void setEnabled(bool enabled) => _enabled = enabled;

  Future<void> init() async {
    try {
      await _tts.initLocale();
    } catch (_) {
      _useFallback = true;
    }
  }

  Future<void> speakCountdown(int n) => _say(n.toString());

  Future<void> speakThirtySeconds() => _say('30 seconds remaining');

  Future<void> playCompleteSound() async {
    await _tts.stop();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await _beep.beep();
  }

  Future<void> speakPhaseCue(WorkoutPhase phase) {
    final text = _cueFor(phase);
    if (text == null) return Future<void>.value();
    return _say(text);
  }

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

  Future<void> speakGetReady() => _say('get ready');

  Future<void> _say(String text) async {
    if (!_enabled) return;
    if (_useFallback) {
      await _beep.beep();
      return;
    }
    // Request audio focus so YT Music ducks before TTS speaks
    final focus = _focusPlayer;
    if (focus != null) {
      try {
        await focus.setVolume(0.15);
        unawaited(focus.play(AssetSource('audio/beep.wav')));
        await Future<void>.delayed(const Duration(milliseconds: 20));
      } catch (_) {}
    }
    await _tts.speak(text);
    try {
      await _focusPlayer?.stop();
    } catch (_) {}
  }
}
