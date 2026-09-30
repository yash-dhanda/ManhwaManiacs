import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:manhwamaniacs/features/reader/providers/reader_profile_settings.dart';
import 'package:manhwamaniacs/features/reader/services/soundscape_files.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/skin_audio.dart';

/// The one player surface the house sound needs; a fake records the volume ramps in tests.
abstract interface class LoopPlayer {
  Future<void> load(File file);
  Future<void> play();
  Future<void> pause();
  Future<void> setVolume(double v);
  Future<void> dispose();
}

/// A second `just_audio` player that requests no audio focus and never touches the session
/// (`handleAudioSessionActivation: false`), looping the file.
class JustAudioLoopPlayer implements LoopPlayer {
  final AudioPlayer _p = AudioPlayer(handleAudioSessionActivation: false);

  @override
  Future<void> load(File file) async {
    await _p.setFilePath(file.path);
    await _p.setLoopMode(LoopMode.one);
  }

  @override
  Future<void> play() => _p.play();
  @override
  Future<void> pause() => _p.pause();
  @override
  Future<void> setVolume(double v) => _p.setVolume(v);
  @override
  Future<void> dispose() => _p.dispose();
}

const Duration kFadeIn = Duration(milliseconds: 2000);
const Duration kFadeOut = Duration(milliseconds: 600);
const Duration kDuckRamp = Duration(milliseconds: 300);
const double kDuckLevel = 0.30;
const Duration kHearLength = Duration(seconds: 5);
const Duration _tick = Duration(milliseconds: 16);

/// A linear ramp of a value, stepped by a periodic timer (fake-time friendly).
class _Ramp {
  _Ramp(this.value);
  double value;
  Timer? _timer;
  Completer<void>? _done;

  Future<void> to(double target, Duration d, void Function() onStep) {
    _timer?.cancel();
    if (_done != null && !_done!.isCompleted) _done!.complete();
    final done = _done = Completer<void>();
    final from = value;
    if (d == Duration.zero || from == target) {
      value = target;
      onStep();
      done.complete();
      return done.future;
    }
    var elapsed = Duration.zero;
    _timer = Timer.periodic(_tick, (t) {
      elapsed += _tick;
      final f = (elapsed.inMicroseconds / d.inMicroseconds).clamp(0.0, 1.0);
      value = from + (target - from) * f;
      onStep();
      if (f >= 1) {
        t.cancel();
        if (!done.isCompleted) done.complete();
      }
    });
    return done.future;
  }

  void cancel() => _timer?.cancel();
}

/// The house sound: one looping file at a device volume, faded in over 2000 ms, out over 600 ms,
/// ducked to 30 % under narration. Skin-independent apart from the [SkinAudio] cue suppression.
class HouseSound extends ChangeNotifier {
  HouseSound({
    required this.files,
    LoopPlayer Function()? playerFactory,
    SkinAudio? audio,
  })  : _factory = playerFactory ?? JustAudioLoopPlayer.new,
        _audio = audio ?? SkinAudio.instance;

  final SoundscapeFiles files;
  final LoopPlayer Function() _factory;
  final SkinAudio _audio;

  LoopPlayer? _player;
  final _fade = _Ramp(0);
  final _duckRamp = _Ramp(1);
  double _volume = 0.4;
  String? _loop;
  bool _playing = false;
  bool _paused = false;
  bool _previewing = false;
  int _gen = 0;

  String? get loopId => _loop;
  bool get playing => _playing;
  bool get previewing => _previewing;
  bool get ducked => _duckRamp.value < 1;

  Future<void> _apply() async {
    final v = (_volume * _fade.value * _duckRamp.value).clamp(0.0, 1.0);
    await _player?.setVolume(v);
  }

  void _step() => unawaited(_apply());

  /// Starts [id] (fading in over 2000 ms), cross-fading out of the current loop over 600 ms;
  /// null fades out and stops.
  Future<void> setLoop(String? id) async {
    if (id == _loop && (id == null || _playing || _paused)) return;
    final gen = ++_gen;
    if (_playing) {
      await _fade.to(0, kFadeOut, _step);
      if (gen != _gen) return;
      await _player?.pause();
    }
    _loop = id;
    if (id == null) {
      _playing = false;
      _paused = false;
      _audio.setSoundscapeActive(false);
      notifyListeners();
      return;
    }
    final file = await files.soundscapeFile(id);
    if (gen != _gen) return;
    _player ??= _factory();
    await _player!.load(file);
    if (gen != _gen) return;
    _fade.value = 0;
    await _apply();
    await _player!.play();
    _playing = true;
    _paused = false;
    _audio.setSoundscapeActive(true);
    notifyListeners();
    await _fade.to(1, kFadeIn, _step);
  }

  Future<void> setVolume(double v) async {
    _volume = v.clamp(0.0, 1.0);
    await _apply();
  }

  /// Ramps to 30 % of the volume (or back) over 300 ms.
  Future<void> duck(bool on) async {
    await _duckRamp.to(on ? kDuckLevel : 1, kDuckRamp, _step);
    notifyListeners();
  }

  /// Fades out over 600 ms and pauses the player.
  Future<void> pause() async {
    if (!_playing) return;
    _playing = false;
    _paused = true;
    await _fade.to(0, kFadeOut, _step);
    await _player?.pause();
    notifyListeners();
  }

  /// Resumes with the 2000 ms fade in.
  Future<void> resume() async {
    if (!_paused || _loop == null) return;
    _paused = false;
    _playing = true;
    await _player?.play();
    notifyListeners();
    await _fade.to(1, kFadeIn, _step);
  }

  /// Leaving the reader or backgrounding: out over 600 ms, ready to resume.
  Future<void> fadeOutForExit() => pause();

  /// `Hear`: pauses the running loop, plays 5 s of [id] in the Voice-sample state (300 ms in, out
  /// over the last 600 ms), restores the previous state and resumes the loop. One at a time.
  Future<void> hear(String id) async {
    if (_previewing) return;
    _previewing = true;
    notifyListeners();
    final wasPlaying = _playing;
    LoopPlayer? p;
    try {
      if (wasPlaying) await pause();
      final file = await files.soundscapeFile(id);
      await _audio.beginVoiceSample();
      p = _factory();
      await p.load(file);
      await p.setVolume(0);
      await p.play();
      final ramp = _Ramp(0);
      final pl = p;
      void step() => unawaited(pl.setVolume(_volume * ramp.value));
      await ramp.to(1, const Duration(milliseconds: 300), step);
      await Future<void>.delayed(kHearLength - const Duration(milliseconds: 300) - kFadeOut);
      await ramp.to(0, kFadeOut, step);
      await p.pause();
    } finally {
      await p?.dispose();
      await _audio.endVoiceSample();
      _previewing = false;
      notifyListeners();
      if (wasPlaying) await resume();
    }
  }

  @override
  void dispose() {
    _fade.cancel();
    _duckRamp.cancel();
    _audio.setSoundscapeActive(false);
    unawaited(_player?.dispose());
    super.dispose();
  }
}

final soundscapeFilesProvider = Provider<SoundscapeFiles>((ref) => SoundscapeFiles(ref.watch(dioProvider)), name: 'soundscapeFiles');

/// One [HouseSound] per app, shared by both readers and Settings -> Ambient.
final houseSoundProvider = ChangeNotifierProvider<HouseSound>((ref) {
  final h = HouseSound(files: ref.watch(soundscapeFilesProvider));
  unawaited(h.setVolume(ref.read(soundscapeVolumeProvider)));
  ref.listen<double>(soundscapeVolumeProvider, (_, v) => unawaited(h.setVolume(v)));
  ref.onDispose(h.dispose);
  return h;
}, name: 'houseSound');
