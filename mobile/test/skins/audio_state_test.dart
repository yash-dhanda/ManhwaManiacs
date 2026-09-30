import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/skin_audio_state.dart';

void main() {
  test('narration under a soundscape ducks it 12 dB over 400 ms; stopping restores the soundscape', () {
    var m = const AudioSessionModel(soundscape: true);
    final a = reduceAudio(m, AudioEvent.narrationStart);
    expect(a.model.owner, AudioOwner.narration);
    expect(a.transition.duckSoundscapeDb, -12);
    expect(a.transition.duckMs, 400);
    m = a.model;
    final b = reduceAudio(m, AudioEvent.narrationStop);
    expect(b.model.owner, AudioOwner.soundscape);
    expect(b.transition.restoreSoundscape, isTrue);
  });

  test('narration with no soundscape ducks nothing', () {
    final a = reduceAudio(const AudioSessionModel(), AudioEvent.narrationStart);
    expect(a.transition.duckSoundscapeDb, 0);
  });

  test('leaving the reader with neither playing returns to idle after the 1.5 s fade', () {
    final a = reduceAudio(const AudioSessionModel(), AudioEvent.readerLeft);
    expect(a.transition.owner, AudioOwner.idle);
    expect(a.transition.fadeSoundscapeMs, 1500);
    expect(reduceAudio(const AudioSessionModel(narrating: true), AudioEvent.readerLeft).transition.fadeSoundscapeMs, isNull);
  });

  test('focus loss pauses both and returns to idle; an interruption end resumes neither', () {
    final a = reduceAudio(const AudioSessionModel(narrating: true, soundscape: true), AudioEvent.focusLost);
    expect(a.model.owner, AudioOwner.idle);
    expect(a.transition.pauseAll, isTrue);
    final b = reduceAudio(const AudioSessionModel(narrating: true), AudioEvent.interruptionEnd);
    expect(b.transition.offerResume, isTrue);
    expect(b.model.narrating, isTrue);
  });

  test('on pause the soundscape alone fades over 1.5 s and returns on resume; UI sounds only in idle', () {
    final p = reduceAudio(const AudioSessionModel(soundscape: true), AudioEvent.appPaused);
    expect(p.transition.fadeSoundscapeMs, 1500);
    expect(p.model.soundscape, isFalse);
    final r = reduceAudio(p.model, AudioEvent.appResumed);
    expect(r.model.soundscape, isTrue);
    expect(r.transition.resumeSoundscape, isTrue);
    expect(const AudioSessionModel().uiSoundsAllowed, isTrue);
    expect(const AudioSessionModel(soundscape: true).uiSoundsAllowed, isFalse);
  });
}
