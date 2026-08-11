import 'package:flutter_test/flutter_test.dart';
import 'package:interval_fit/core/timer_engine.dart';
import 'package:interval_fit/core/voice_service.dart';
import 'package:mocktail/mocktail.dart';

class MockTts extends Mock implements Tts {}

class MockBeep extends Mock implements BeepPlayer {}

void main() {
  late MockTts tts;
  late MockBeep beep;

  setUp(() {
    tts = MockTts();
    beep = MockBeep();
    when(
      () => tts.speak(any(), focus: any(named: 'focus')),
    ).thenAnswer((_) async {});
    when(() => tts.initLocale()).thenAnswer((_) async {});
    when(() => beep.beep()).thenAnswer((_) async {});
  });

  VoiceService svc({bool enabled = true}) =>
      VoiceService(tts: tts, beep: beep, enabled: enabled);

  test('countdown speaks the number when enabled', () async {
    final s = svc();
    await s.speakCountdown(3);
    verify(() => tts.speak('3', focus: true)).called(1);
    verifyNever(() => beep.beep());
  });

  test('phase cue: rest -> rest', () async {
    final s = svc();
    await s.speakPhaseCue(WorkoutPhase.rest);
    verify(() => tts.speak('rest', focus: true)).called(1);
  });

  test('phase cue: work -> start', () async {
    final s = svc();
    await s.speakPhaseCue(WorkoutPhase.work);
    verify(() => tts.speak('start', focus: true)).called(1);
  });

  test('speakGetReady speaks the get-ready cue', () async {
    final s = svc();
    await s.speakGetReady();
    verify(() => tts.speak('get ready', focus: true)).called(1);
  });

  test('warmup/cooldown/done are no-op cues', () async {
    final s = svc();
    await s.speakPhaseCue(WorkoutPhase.warmup);
    await s.speakPhaseCue(WorkoutPhase.cooldown);
    await s.speakPhaseCue(WorkoutPhase.done);
    verifyNever(
      () => tts.speak(any(), focus: any(named: 'focus')),
    );
    verifyNever(() => beep.beep());
  });

  test('disabled -> no speak/beep at all', () async {
    final s = svc(enabled: false);
    await s.speakCountdown(2);
    await s.speakPhaseCue(WorkoutPhase.work);
    verifyNever(
      () => tts.speak(any(), focus: any(named: 'focus')),
    );
    verifyNever(() => beep.beep());
  });

  test('setEnabled(false) silences subsequent calls', () async {
    final s = svc();
    s.setEnabled(false);
    await s.speakCountdown(1);
    verifyNever(
      () => tts.speak(any(), focus: any(named: 'focus')),
    );
  });

  test('init TTS throws -> subsequent cues beep, not speak', () async {
    when(() => tts.initLocale()).thenThrow(Exception('tts unavailable'));
    final s = svc();
    await s.init();
    await s.speakCountdown(3);
    await s.speakPhaseCue(WorkoutPhase.rest);
    verify(() => beep.beep()).called(2);
    verifyNever(
      () => tts.speak(any(), focus: any(named: 'focus')),
    );
  });
}
