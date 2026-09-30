/// The pure reducer of glass §6 "One audio session, one owner". The states are `idle` (`.ambient`, no focus), `soundscape`
/// (`.playback` + `.mixWithOthers`, no focus) and `narration` (speech, `AUDIOFOCUS_GAIN`). Skin-neutral: Glass never configures the
/// session itself; the shared `skin_audio.dart` applies what this returns.
enum AudioOwner { idle, soundscape, narration }

enum AudioEvent { narrationStart, narrationStop, soundscapeStart, soundscapeStop, readerLeft, focusLost, interruptionEnd, appPaused, appResumed }

class AudioTransition {
  const AudioTransition(this.owner, {this.duckSoundscapeDb = 0, this.duckMs = 0, this.fadeSoundscapeMs, this.offerResume = false, this.restoreSoundscape = false, this.resumeSoundscape = false, this.pauseAll = false});

  final AudioOwner owner;

  /// Narration starting under a soundscape ducks it by 12 dB over 400 ms.
  final double duckSoundscapeDb;
  final int duckMs;

  /// The soundscape alone fades out (on `paused`) or the session returns to idle after the fade (leaving the reader).
  final int? fadeSoundscapeMs;

  /// An interruption ended: neither resumes; the UI offers "Resume".
  final bool offerResume;
  final bool restoreSoundscape;
  final bool resumeSoundscape;
  final bool pauseAll;
}

class AudioSessionModel {
  const AudioSessionModel({this.narrating = false, this.soundscape = false, this.soundscapeWasPlayingOnPause = false});
  final bool narrating;
  final bool soundscape;
  final bool soundscapeWasPlayingOnPause;

  AudioOwner get owner => narrating ? AudioOwner.narration : (soundscape ? AudioOwner.soundscape : AudioOwner.idle);

  /// UI sounds play only in `idle` and never in the background.
  bool get uiSoundsAllowed => owner == AudioOwner.idle;
}

({AudioSessionModel model, AudioTransition transition}) reduceAudio(AudioSessionModel m, AudioEvent e) {
  switch (e) {
    case AudioEvent.narrationStart:
      final n = AudioSessionModel(narrating: true, soundscape: m.soundscape);
      return (model: n, transition: AudioTransition(AudioOwner.narration, duckSoundscapeDb: m.soundscape ? -12 : 0, duckMs: m.soundscape ? 400 : 0));
    case AudioEvent.narrationStop:
      final n = AudioSessionModel(soundscape: m.soundscape);
      return (model: n, transition: AudioTransition(n.owner, restoreSoundscape: m.soundscape));
    case AudioEvent.soundscapeStart:
      final n = AudioSessionModel(narrating: m.narrating, soundscape: true);
      return (model: n, transition: AudioTransition(n.owner));
    case AudioEvent.soundscapeStop:
      final n = AudioSessionModel(narrating: m.narrating);
      return (model: n, transition: AudioTransition(n.owner));
    case AudioEvent.readerLeft:
      if (m.narrating || m.soundscape) return (model: m, transition: AudioTransition(m.owner));
      return (model: m, transition: const AudioTransition(AudioOwner.idle, fadeSoundscapeMs: 1500));
    case AudioEvent.focusLost:
      return (model: const AudioSessionModel(), transition: const AudioTransition(AudioOwner.idle, pauseAll: true));
    case AudioEvent.interruptionEnd:
      // Neither resumes on its own.
      return (model: m, transition: AudioTransition(m.owner, offerResume: true));
    case AudioEvent.appPaused:
      return (
        model: AudioSessionModel(narrating: m.narrating, soundscapeWasPlayingOnPause: m.soundscape),
        transition: AudioTransition(m.narrating ? AudioOwner.narration : AudioOwner.idle, fadeSoundscapeMs: m.soundscape ? 1500 : null),
      );
    case AudioEvent.appResumed:
      final back = m.soundscapeWasPlayingOnPause;
      final n = AudioSessionModel(narrating: m.narrating, soundscape: back);
      return (model: n, transition: AudioTransition(n.owner, resumeSoundscape: back));
  }
}
