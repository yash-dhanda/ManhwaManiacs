import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:manhwamaniacs/skins/glass/soundscape/generator.dart';
import 'package:manhwamaniacs/skins/glass/soundscape/recipes.dart';

/// Exactly the calls the mixer needs of the audio engine. `flutter_soloud`'s FFI engine cannot run in `flutter test`, so the tests
/// pass a fake; [SoLoudSoundscapeAudio] forwards to `SoLoud.instance` (4.1.7 names).
abstract interface class SoundscapeAudio {
  bool get isReady;
  Future<dynamic> loadMem(String name, Uint8List bytes);
  Future<dynamic> loadFile(String path);
  dynamic play(dynamic source, {double volume = 1, double pan = 0, bool looping = false});
  void setVolume(dynamic handle, double v);
  void fadeVolume(dynamic handle, double to, Duration duration);
  void setPause(dynamic handle, bool paused);
  Future<void> stop(dynamic handle);
  Future<void> disposeSource(dynamic source);
  Duration getPosition(dynamic handle);

  /// The envelope of a recorded layer (`readSamplesFromFile`, averaged), or null when the engine cannot read it.
  Future<Float32List?> envelopeOfFile(String path, int samples);
}

class SoLoudSoundscapeAudio implements SoundscapeAudio {
  const SoLoudSoundscapeAudio();
  static SoLoud get _s => SoLoud.instance;

  @override
  bool get isReady => _s.isInitialized;

  @override
  Future<dynamic> loadMem(String name, Uint8List bytes) => _s.loadMem(name, bytes);

  @override
  Future<dynamic> loadFile(String path) => _s.loadFile(path);

  @override
  dynamic play(dynamic source, {double volume = 1, double pan = 0, bool looping = false}) =>
      _s.play(source as AudioSource, volume: volume, pan: pan, looping: looping);

  @override
  void setVolume(dynamic handle, double v) => _s.setVolume(handle as SoundHandle, v);

  @override
  void fadeVolume(dynamic handle, double to, Duration duration) => _s.fadeVolume(handle as SoundHandle, to, duration);

  @override
  void setPause(dynamic handle, bool paused) => _s.setPause(handle as SoundHandle, paused);

  @override
  Future<void> stop(dynamic handle) => _s.stop(handle as SoundHandle);

  @override
  Future<void> disposeSource(dynamic source) => _s.disposeSource(source as AudioSource);

  @override
  Duration getPosition(dynamic handle) => _s.getPosition(handle as SoundHandle);

  @override
  Future<Float32List?> envelopeOfFile(String path, int samples) async {
    try {
      final raw = await _s.readSamplesFromFile(path, samples, average: true);
      var peak = 1e-9;
      for (final v in raw) {
        peak = math.max(peak, v.abs());
      }
      return Float32List.fromList([for (final v in raw) v.abs() / peak]);
    } catch (_) {
      return null;
    }
  }
}

/// The fades of glass 9.4.2 Mixing rules.
abstract final class SoundscapeFades {
  static const fadeIn = Duration(seconds: 3), fadeOut = Duration(milliseconds: 1500);
  static const duck = Duration(milliseconds: 400), crossfade = Duration(seconds: 2), unmute = Duration(seconds: 1);
  static const edit = Duration(milliseconds: 80);
  static final double duckGain = dbToGain(-12);
}

/// The three layer levels, 0 to 1.
class MixLevels {
  const MixLevels({this.bed = 0.8, this.detail = 0.5, this.tone = 0.3});
  final double bed, detail, tone;

  double of(SoundLayer l) => switch (l) {
        SoundLayer.bed => bed,
        SoundLayer.detail => detail,
        SoundLayer.tone => tone,
      };

  MixLevels with_(SoundLayer l, double v) {
    final x = v.clamp(0.0, 1.0);
    return switch (l) {
      SoundLayer.bed => MixLevels(bed: x, detail: detail, tone: tone),
      SoundLayer.detail => MixLevels(bed: bed, detail: x, tone: tone),
      SoundLayer.tone => MixLevels(bed: bed, detail: detail, tone: x),
    };
  }

  @override
  bool operator ==(Object other) => other is MixLevels && other.bed == bed && other.detail == detail && other.tone == tone;
  @override
  int get hashCode => Object.hash(bed, detail, tone);
}

// ── Events ───────────────────────────────────────────────────────────────────────────────────────

class ScheduledEvent {
  const ScheduledEvent({required this.at, required this.bankIndex, required this.pan, required this.r});
  final Duration at;
  final int bankIndex;

  /// -0.8 to 0.8 for Rain droplets; 0 otherwise.
  final double pan;

  /// 0 to 1: the event's volume is `layerGain x (0.6 + 0.4 r)`.
  final double r;
}

/// Poisson arrivals from a seeded `Random`, drawn every 20 ms. Event timing is quantised to that tick, which is inaudible for random
/// textures. Never yields an event before [startAt].
class EventScheduler {
  EventScheduler({required this.rate, required this.bank, int seed = 5, this.panRange = 0, this.walk = false, this.startAt = Duration.zero})
      : _r = math.Random(seed),
        _rate = rate;

  static const Duration tick = Duration(milliseconds: 20);

  final double rate;
  final int bank;
  final double panRange;

  /// Rain: the rate wanders between 8 and 20 per second on a 0.1 Hz random walk.
  final bool walk;
  final Duration startAt;
  final math.Random _r;
  double _rate;
  Duration _last = Duration.zero;

  double get currentRate => _rate;

  /// The events due in the ticks up to [now].
  List<ScheduledEvent> advance(Duration now) {
    final out = <ScheduledEvent>[];
    while (_last + tick <= now) {
      _last += tick;
      final dt = tick.inMicroseconds / 1e6;
      if (walk) {
        // 0.1 Hz: the walk's correlation time is 10 s, so a step of sigma ~ sqrt(2 dt / 10) x span keeps it wandering that slowly.
        _rate = (_rate + (_r.nextDouble() * 2 - 1) * math.sqrt(2 * dt / 10) * 12 * 1.7).clamp(8.0, 20.0);
      }
      if (_last < startAt) continue;
      // Poisson(lambda dt): the count of arrivals in one tick.
      var k = 0;
      final l = math.exp(-_rate * dt);
      var p = _r.nextDouble();
      while (p > l && k < 4) {
        k++;
        p *= _r.nextDouble();
      }
      for (var i = 0; i < k; i++) {
        out.add(ScheduledEvent(
          at: _last,
          bankIndex: _r.nextInt(bank),
          pan: panRange == 0 ? 0 : (_r.nextDouble() * 2 - 1) * panRange,
          r: _r.nextDouble(),
        ),);
      }
    }
    return out;
  }
}

// ── Level bars ───────────────────────────────────────────────────────────────────────────────────

/// 8 bars: 1-3 the Bed, 4-6 the Detail, 7-8 the Tone. Each is `clamp(level x (0.7 + 0.3 j), 0, 1)`, `j` redrawn per frame from a
/// seeded `Random` and smoothed with alpha 0.3 (glass 9.4.2 Level bars).
class LevelMeter {
  LevelMeter({int seed = 3}) : _r = math.Random(seed);
  final math.Random _r;
  final List<double> _j = List.filled(8, 0.5);
  static const List<SoundLayer> layerOfBar = [SoundLayer.bed, SoundLayer.bed, SoundLayer.bed, SoundLayer.detail, SoundLayer.detail, SoundLayer.detail, SoundLayer.tone, SoundLayer.tone];

  /// [level] is each layer's envelope value times its mix.
  List<double> frame(double Function(SoundLayer) level) {
    final out = List<double>.filled(8, 0);
    for (var i = 0; i < 8; i++) {
      _j[i] += 0.3 * (_r.nextDouble() - _j[i]);
      out[i] = (level(layerOfBar[i]) * (0.7 + 0.3 * _j[i])).clamp(0.0, 1.0);
    }
    return out;
  }
}

/// The envelope value of a loop at a play position (30 Hz, wrapping at 30 s).
double envelopeAt(Float32List? env, Duration position) {
  if (env == null || env.isEmpty) return 0;
  final i = (position.inMicroseconds / 1e6 * kEnvelopeHz).floor();
  return env[i % env.length];
}

// ── The mixer ────────────────────────────────────────────────────────────────────────────────────

/// What a scene needs to sound: its loop WAVs and its event banks.
class SceneAssets {
  const SceneAssets({required this.loops, required this.banks, required this.envelopes});
  final Map<SoundLayer, Uint8List> loops;
  final Map<SoundLayer, List<Uint8List>> banks;
  final Map<SoundLayer, Float32List> envelopes;
}

class _Slot {
  _Slot(this.layer, this.kind);
  final SoundLayer layer;
  final LayerKind kind;
  dynamic source, handle;
  bool recorded = false;
  EventScheduler? scheduler;
  final List<dynamic> bank = [];
  Float32List? envelope;

  /// Event layers: adds each event's volume, decays by `exp(-dt / 80 ms)`.
  double accumulator = 0;
  bool get audible => handle != null || scheduler != null;
}

/// Three layers per scene (glass 9.4.2): a looping voice per loop layer, the event scheduler per event layer, ducking, muting, pausing,
/// the 2 s cross-fade to a recorded layer. Volume of a layer is `mix[layer] x master x duck x mute`; every change is a `fadeVolume`.
class SoundscapeMixer {
  SoundscapeMixer(this.audio, {int seed = 5}) : _seed = seed;

  final SoundscapeAudio audio;
  final int _seed;
  final LevelMeter _meter = LevelMeter();
  final Map<SoundLayer, _Slot> _slots = {};
  Timer? _tick, _afterFade;
  final Stopwatch _clock = Stopwatch();

  SoundScene? scene;
  MixLevels mix = const MixLevels();
  double masterDb = -12;
  bool ducked = false, muted = false, paused = false;
  bool _stopped = true;

  bool get playing => !_stopped;

  double gainOf(SoundLayer l) => mix.of(l) * dbToGain(masterDb) * (ducked ? SoundscapeFades.duckGain : 1) * (muted ? 0 : 1);

  /// Layers that play a recorded file now.
  Set<SoundLayer> get recordedLayers => {for (final s in _slots.values) if (s.recorded) s.layer};

  /// Layers that make sound in the built-in version.
  Set<SoundLayer> get builtinLayers => {for (final e in kRecipes[scene]!.entries) if (e.value != LayerKind.silent) e.key};

  /// Starts [s]: loops begin at volume 0 and the master fades in over 3 s, the event schedulers start at once.
  Future<void> start(SoundScene s, SceneAssets assets, {required MixLevels mix, required double masterDb, bool muted = false}) async {
    await _release(immediate: true);
    scene = s;
    this.mix = mix;
    this.masterDb = masterDb;
    this.muted = muted;
    ducked = false;
    paused = false;
    _stopped = false;
    _clock
      ..reset()
      ..start();
    for (final layer in SoundLayer.values) {
      final kind = kRecipes[s]![layer]!;
      final slot = _slots[layer] = _Slot(layer, kind);
      slot.envelope = assets.envelopes[layer];
      if (kind == LayerKind.loop) {
        slot.source = await audio.loadMem('glass-${s.name}-${layer.name}', assets.loops[layer]!);
        slot.handle = audio.play(slot.source, volume: 0, looping: true);
        audio.fadeVolume(slot.handle, gainOf(layer), SoundscapeFades.fadeIn);
      } else if (kind == LayerKind.events) {
        var i = 0;
        for (final b in assets.banks[layer]!) {
          slot.bank.add(await audio.loadMem('glass-${s.name}-${layer.name}-${i++}', b));
        }
        final rate = kEventRates[s]!;
        slot.scheduler = EventScheduler(
          rate: rate.rate,
          bank: slot.bank.length,
          seed: _seed + layer.index,
          panRange: s == SoundScene.rain ? 0.8 : 0,
          walk: s == SoundScene.rain,
        );
      }
    }
    _tick = Timer.periodic(EventScheduler.tick, (_) => _onTick());
  }

  void _onTick() {
    if (paused) return;
    final now = _clock.elapsed;
    for (final slot in _slots.values) {
      final sch = slot.scheduler;
      if (sch == null) continue;
      slot.accumulator *= math.exp(-EventScheduler.tick.inMicroseconds / 1e3 / 80);
      for (final e in sch.advance(now)) {
        final v = gainOf(slot.layer) * (0.6 + 0.4 * e.r);
        if (v <= 0) continue;
        audio.play(slot.bank[e.bankIndex], volume: v, pan: e.pan);
        slot.accumulator += v;
      }
    }
  }

  /// The 8 level-bar values for this frame.
  List<double> levels() => _meter.frame((l) {
        final s = _slots[l];
        if (s == null || muted || paused) return 0;
        final raw = s.handle != null ? envelopeAt(s.envelope, audio.getPosition(s.handle)) : s.scheduler != null ? s.accumulator.clamp(0.0, 1.0) : 0.0;
        return (raw * mix.of(l)).clamp(0.0, 1.0);
      });

  void _fadeAll(Duration d) {
    for (final s in _slots.values) {
      final h = s.handle;
      if (h != null) audio.fadeVolume(h, gainOf(s.layer), d);
    }
  }

  void setMix(SoundLayer l, double v) {
    mix = mix.with_(l, v);
    final h = _slots[l]?.handle;
    if (h != null) audio.fadeVolume(h, gainOf(l), SoundscapeFades.edit);
  }

  void setMasterDb(double db) {
    masterDb = db.clamp(-30.0, 0.0);
    _fadeAll(SoundscapeFades.edit);
  }

  /// Under narration: 12 dB down over 400 ms, back over 400 ms.
  void duck(bool on) {
    if (ducked == on) return;
    ducked = on;
    _fadeAll(SoundscapeFades.duck);
  }

  /// Your own music is playing: the scene starts muted and the toast unmutes over 1 s.
  void setMuted(bool on, {Duration? over}) {
    if (muted == on) return;
    muted = on;
    _fadeAll(over ?? (on ? SoundscapeFades.duck : SoundscapeFades.unmute));
  }

  /// Fade out over 1.5 s, then pause the voices (leaving the reader, the background, narration with "Lower under narration" off).
  void pause() {
    if (paused || _stopped) return;
    paused = true;
    for (final s in _slots.values) {
      final h = s.handle;
      if (h != null) audio.fadeVolume(h, 0, SoundscapeFades.fadeOut);
    }
    _afterFade?.cancel();
    _afterFade = Timer(SoundscapeFades.fadeOut, () {
      if (!paused) return;
      for (final s in _slots.values) {
        final h = s.handle;
        if (h != null) audio.setPause(h, true);
      }
    });
  }

  /// Unpauses and fades in over 3 s.
  void resume() {
    if (!paused || _stopped) return;
    _afterFade?.cancel();
    paused = false;
    for (final s in _slots.values) {
      final h = s.handle;
      if (h == null) continue;
      audio.setPause(h, false);
      audio.fadeVolume(h, gainOf(s.layer), SoundscapeFades.fadeIn);
    }
  }

  /// Plays [path] as the recorded layer: it fades up over 2 s while its procedural counterpart fades down, then the procedural voice (or
  /// event scheduler) is stopped and disposed. Returns false when the engine cannot load the file (the procedural layer keeps playing).
  Future<bool> attachRecorded(SoundLayer l, String path) async {
    final slot = _slots[l];
    if (slot == null || _stopped || slot.recorded) return false;
    dynamic src;
    dynamic h;
    try {
      src = await audio.loadFile(path);
      if (_stopped || _slots[l] != slot) {
        unawaited(audio.disposeSource(src));
        return false;
      }
      h = audio.play(src, volume: 0, looping: true);
    } catch (_) {
      return false;
    }
    if (paused) audio.setPause(h, true);
    final target = paused ? 0.0 : gainOf(l);
    audio.fadeVolume(h, target, SoundscapeFades.crossfade);
    final oldHandle = slot.handle, oldSource = slot.source, oldBank = List<dynamic>.of(slot.bank);
    if (oldHandle != null) audio.fadeVolume(oldHandle, 0, SoundscapeFades.crossfade);
    slot.scheduler = null;
    slot.handle = h;
    slot.source = src;
    slot.recorded = true;
    unawaited(audio.envelopeOfFile(path, kEnvelopeLength * 3).then((e) {
      if (e != null && _slots[l] == slot) slot.envelope = e;
    }),);
    Timer(SoundscapeFades.crossfade, () {
      if (oldHandle != null) unawaited(audio.stop(oldHandle).catchError((_) {}));
      if (oldSource != null) unawaited(audio.disposeSource(oldSource).catchError((_) {}));
      for (final b in oldBank) {
        unawaited(audio.disposeSource(b).catchError((_) {}));
      }
    });
    slot.bank.clear();
    return true;
  }

  /// Fades out over 1.5 s and releases everything (or releases at once).
  Future<void> stop({bool immediate = false, Duration? fade}) => _release(immediate: immediate, fade: fade ?? SoundscapeFades.fadeOut);

  Future<void> _release({required bool immediate, Duration fade = SoundscapeFades.fadeOut}) async {
    if (_slots.isEmpty) {
      _stopped = true;
      return;
    }
    _stopped = true;
    _tick?.cancel();
    _afterFade?.cancel();
    final slots = _slots.values.toList();
    _slots.clear();
    if (!immediate) {
      for (final s in slots) {
        final h = s.handle;
        if (h != null && !paused) audio.fadeVolume(h, 0, fade);
      }
      await Future<void>.delayed(fade);
    }
    for (final s in slots) {
      final h = s.handle;
      if (h != null) unawaited(audio.stop(h).catchError((_) {}));
      if (s.source != null) unawaited(audio.disposeSource(s.source).catchError((_) {}));
      for (final b in s.bank) {
        unawaited(audio.disposeSource(b).catchError((_) {}));
      }
    }
    paused = false;
  }

  Future<void> dispose() => _release(immediate: true);
}

/// Convenience for the controller: whether [path] is a readable file.
bool fileReadable(String path) {
  try {
    return File(path).existsSync();
  } catch (_) {
    return false;
  }
}
