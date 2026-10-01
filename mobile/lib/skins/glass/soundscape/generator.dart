import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:manhwamaniacs/skins/glass/soundscape/recipes.dart';

/// The built-in loops (glass 9.4.2 "Phones"): 30 s, mono, 32 kHz, rendered in a background isolate and handed to `SoLoud.loadMem` as WAV
/// bytes. Everything here is pure Dart over `Float64List`, so it runs under `flutter test`.
const int kSampleRate = 32000;
const int kLoopSeconds = 30;
const int kLoopSamples = kSampleRate * kLoopSeconds; // 960,000
const int kFadeSamples = kSampleRate * 2; // the equal-power seam
const int kEnvelopeHz = 30;
const int kEnvelopeLength = kLoopSeconds * kEnvelopeHz; // 900

class RenderedLoop {
  const RenderedLoop(this.wav, this.envelope);
  final Uint8List wav;

  /// RMS at 30 Hz, 0 to 1: drives the level bars.
  final Float32List envelope;
}

// ── Noise ────────────────────────────────────────────────────────────────────────────────────────

class _Noise {
  _Noise(int seed) : _r = math.Random(seed);
  final math.Random _r;
  double _b0 = 0, _b1 = 0, _b2 = 0, _b3 = 0, _b4 = 0, _b5 = 0, _b6 = 0, _brown = 0;

  double white() => _r.nextDouble() * 2 - 1;

  /// Paul Kellet's refined filter over white.
  double pink() {
    final w = white();
    _b0 = 0.99886 * _b0 + w * 0.0555179;
    _b1 = 0.99332 * _b1 + w * 0.0750759;
    _b2 = 0.96900 * _b2 + w * 0.1538520;
    _b3 = 0.86650 * _b3 + w * 0.3104856;
    _b4 = 0.55000 * _b4 + w * 0.5329522;
    _b5 = -0.7616 * _b5 - w * 0.0168980;
    final out = _b0 + _b1 + _b2 + _b3 + _b4 + _b5 + _b6 + w * 0.5362;
    _b6 = w * 0.115926;
    return out * 0.11;
  }

  /// The leaky integrator `b = (b + 0.02 w) / 1.02`, times 3.5.
  double brown() {
    _brown = (_brown + 0.02 * white()) / 1.02;
    return _brown * 3.5;
  }
}

// ── Filters (RBJ cookbook) ───────────────────────────────────────────────────────────────────────

enum _Kind { lowpass, highpass, bandpass }

class Biquad {
  Biquad.lowpass(double f, [double q = 0.7071]) : _kind = _Kind.lowpass {
    set(f, q);
  }
  Biquad.highpass(double f, [double q = 0.7071]) : _kind = _Kind.highpass {
    set(f, q);
  }

  /// Constant 0 dB peak gain.
  Biquad.bandpass(double f, double q) : _kind = _Kind.bandpass {
    set(f, q);
  }

  final _Kind _kind;
  double _b0 = 0, _b1 = 0, _b2 = 0, _a1 = 0, _a2 = 0, _z1 = 0, _z2 = 0;

  void set(double f, double q) {
    final w0 = 2 * math.pi * f.clamp(10.0, kSampleRate / 2 - 100) / kSampleRate;
    final cw = math.cos(w0), alpha = math.sin(w0) / (2 * q);
    final a0 = 1 + alpha;
    switch (_kind) {
      case _Kind.lowpass:
        _b0 = (1 - cw) / 2 / a0;
        _b1 = (1 - cw) / a0;
        _b2 = _b0;
      case _Kind.highpass:
        _b0 = (1 + cw) / 2 / a0;
        _b1 = -(1 + cw) / a0;
        _b2 = _b0;
      case _Kind.bandpass:
        _b0 = alpha / a0;
        _b1 = 0;
        _b2 = -alpha / a0;
    }
    _a1 = -2 * cw / a0;
    _a2 = (1 - alpha) / a0;
  }

  double process(double x) {
    final y = _b0 * x + _z1;
    _z1 = _b1 * x - _a1 * y + _z2;
    _z2 = _b2 * x - _a2 * y;
    return y;
  }
}

/// `g(t) = 1 - depth x (0.5 + 0.5 sin(2 pi f t + phase))`: between `1 - depth` and 1.
double lfoGain(double t, double hz, double depth, [double phase = 0]) => 1 - depth * (0.5 + 0.5 * math.sin(2 * math.pi * hz * t + phase));

// ── Measuring ────────────────────────────────────────────────────────────────────────────────────

double rms(Float64List s, [int from = 0, int? to]) {
  final end = to ?? s.length;
  var acc = 0.0;
  for (var i = from; i < end; i++) {
    acc += s[i] * s[i];
  }
  return math.sqrt(acc / math.max(1, end - from));
}

double rmsDb(Float64List s) => 20 * math.log(math.max(rms(s), 1e-12)) / math.ln10;

void _normalise(Float64List s, double db) {
  final g = dbToGain(db) / math.max(rms(s), 1e-12);
  for (var i = 0; i < s.length; i++) {
    s[i] *= g;
  }
}

// ── The recipes (glass 9.4.2 procedural column), 32 s long before the seam ───────────────────────

const int _rawSamples = kSampleRate * (kLoopSeconds + 2);

Float64List _rain(SoundLayer l, _Noise n) {
  final out = Float64List(_rawSamples);
  if (l == SoundLayer.bed) {
    final hp = Biquad.highpass(400), lp = Biquad.lowpass(6000);
    for (var i = 0; i < out.length; i++) {
      out[i] = lp.process(hp.process(n.pink()));
    }
  } else {
    final lp = Biquad.lowpass(200);
    for (var i = 0; i < out.length; i++) {
      out[i] = lp.process(n.brown());
    }
  }
  return out;
}

Float64List _wind(_Noise n) {
  final out = Float64List(_rawSamples);
  final bp = Biquad.bandpass(300, 0.7);
  for (var i = 0; i < out.length; i++) {
    final t = i / kSampleRate;
    if (i % 32 == 0) bp.set(300 + 150 * math.sin(2 * math.pi * 0.08 * t), 0.7);
    out[i] = bp.process(n.brown()) * lfoGain(t, 0.05, 0.4);
  }
  return out;
}

Float64List _ocean(SoundLayer l, _Noise n) {
  final out = Float64List(_rawSamples);
  if (l == SoundLayer.bed) {
    final lp = Biquad.lowpass(900);
    for (var i = 0; i < out.length; i++) {
      out[i] = lp.process(n.brown()) * lfoGain(i / kSampleRate, 0.1, 0.7);
    }
  } else {
    // The same swell delayed 1.5 s: 0.1 Hz x 1.5 s = 54 degrees.
    final hp = Biquad.highpass(2000);
    for (var i = 0; i < out.length; i++) {
      out[i] = hp.process(n.white()) * lfoGain(i / kSampleRate, 0.1, 0.7, -54 * math.pi / 180);
    }
  }
  return out;
}

Float64List _hearth(_Noise n) {
  final out = Float64List(_rawSamples);
  final lp = Biquad.lowpass(1200);
  for (var i = 0; i < out.length; i++) {
    out[i] = lp.process(n.brown());
  }
  return out;
}

Float64List _stream(_Noise n) {
  final out = Float64List(_rawSamples);
  final bp = Biquad.bandpass(1800, 1.2);
  for (var i = 0; i < out.length; i++) {
    out[i] = bp.process(n.pink()) * lfoGain(i / kSampleRate, 7, 0.15);
  }
  return out;
}

Float64List _deep(_Noise n) {
  final sines = Float64List(_rawSamples), noise = Float64List(_rawSamples);
  var p1 = 0.0, p2 = 0.0;
  final lp = Biquad.lowpass(300);
  for (var i = 0; i < _rawSamples; i++) {
    final t = i / kSampleRate;
    final detune = math.pow(2, (4 / 1200) * math.sin(2 * math.pi * 0.03 * t)).toDouble();
    p1 += 2 * math.pi * 55.0 * detune / kSampleRate;
    p2 += 2 * math.pi * 82.41 * detune / kSampleRate;
    sines[i] = (math.sin(p1) + math.sin(p2)) / 2;
    noise[i] = lp.process(n.pink());
  }
  // The pink noise sits 18 dB under the sines' combined RMS.
  final g = rms(sines) * dbToGain(-18) / math.max(rms(noise), 1e-12);
  for (var i = 0; i < _rawSamples; i++) {
    sines[i] += noise[i] * g;
  }
  return sines;
}

/// One loop layer as 960,000 samples: rendered 32 s long, then the last 2 s cross-faded equal-power into the first 2 s, then normalised.
Float64List renderLoopSamples(SoundScene scene, SoundLayer layer, {int seed = 7}) {
  assert(kRecipes[scene]![layer] == LayerKind.loop, '$scene $layer is not a loop');
  final n = _Noise(seed + scene.index * 31 + layer.index * 7);
  final sig = switch (scene) {
    SoundScene.rain => _rain(layer, n),
    SoundScene.wind => _wind(n),
    SoundScene.ocean => _ocean(layer, n),
    SoundScene.hearth => _hearth(n),
    SoundScene.stream => _stream(n),
    SoundScene.deep => _deep(n),
  };
  final out = Float64List(kLoopSamples);
  for (var i = 0; i < kLoopSamples; i++) {
    if (i < kFadeSamples) {
      final a = math.pi / 2 * i / kFadeSamples;
      out[i] = sig[i] * math.sin(a) + sig[kLoopSamples + i] * math.cos(a);
    } else {
      out[i] = sig[i];
    }
  }
  _normalise(out, loopTargetDb(scene, layer));
  return out;
}

/// RMS at 30 Hz, scaled so the loudest window is 1.
Float32List envelopeOf(Float64List s) {
  final win = s.length ~/ kEnvelopeLength;
  final e = Float32List(kEnvelopeLength);
  var peak = 1e-12;
  for (var i = 0; i < kEnvelopeLength; i++) {
    final v = rms(s, i * win, (i + 1) * win);
    e[i] = v;
    if (v > peak) peak = v;
  }
  for (var i = 0; i < kEnvelopeLength; i++) {
    e[i] = e[i] / peak;
  }
  return e;
}

/// A 16-bit little-endian mono PCM WAV: the 44-byte header (`RIFF`/`WAVE`, `fmt ` PCM, `data`) then the samples.
Uint8List wavBytes(Float64List mono, {int sampleRate = kSampleRate}) {
  final data = mono.length * 2;
  final b = ByteData(44 + data);
  void tag(int at, String s) {
    for (var i = 0; i < s.length; i++) {
      b.setUint8(at + i, s.codeUnitAt(i));
    }
  }

  tag(0, 'RIFF');
  b.setUint32(4, 36 + data, Endian.little);
  tag(8, 'WAVE');
  tag(12, 'fmt ');
  b.setUint32(16, 16, Endian.little);
  b.setUint16(20, 1, Endian.little);
  b.setUint16(22, 1, Endian.little);
  b.setUint32(24, sampleRate, Endian.little);
  b.setUint32(28, sampleRate * 2, Endian.little);
  b.setUint16(32, 2, Endian.little);
  b.setUint16(34, 16, Endian.little);
  tag(36, 'data');
  b.setUint32(40, data, Endian.little);
  for (var i = 0; i < mono.length; i++) {
    b.setInt16(44 + i * 2, (mono[i].clamp(-1.0, 1.0) * 32767).round(), Endian.little);
  }
  return b.buffer.asUint8List();
}

RenderedLoop renderLoop(SoundScene scene, SoundLayer layer, {int seed = 7}) {
  final s = renderLoopSamples(scene, layer, seed: seed);
  return RenderedLoop(wavBytes(s), envelopeOf(s));
}

/// Renders in a background isolate; the bytes cross back as one copy.
Future<RenderedLoop> renderLoopInIsolate(SoundScene scene, SoundLayer layer, {int seed = 7}) =>
    Isolate.run(() => renderLoop(scene, layer, seed: seed));

// ── Event banks ──────────────────────────────────────────────────────────────────────────────────

/// Rain droplets (12 ticks at 2000 + 2000 k/11 Hz, 4 ms, 1 ms attack, exponential decay), Wind bursts (40 to 120 ms), Hearth crackles
/// (12 of 3 to 8 ms). Each is one short WAV that `loadMem` takes.
List<Float64List> renderEventBank(SoundScene scene, {int seed = 11}) {
  final n = _Noise(seed);
  switch (scene) {
    case SoundScene.rain:
      return [
        for (var k = 0; k < 12; k++) () {
          final f = 2000 + 2000 * k / 11;
          const len = kSampleRate * 4 ~/ 1000, attack = kSampleRate ~/ 1000;
          final o = Float64List(len);
          for (var i = 0; i < len; i++) {
            final env = i < attack ? i / attack : math.exp(-(i - attack) / (kSampleRate * 0.001));
            o[i] = 0.6 * env * math.sin(2 * math.pi * f * i / kSampleRate);
          }
          return o;
        }(),
      ];
    case SoundScene.wind:
      return [
        for (final ms in const [40, 56, 72, 88, 104, 120]) () {
          final len = kSampleRate * ms ~/ 1000;
          final bp = Biquad.bandpass(1200, 1);
          final o = Float64List(len);
          for (var i = 0; i < len; i++) {
            o[i] = bp.process(n.white()) * math.sin(math.pi * i / len);
          }
          return _peak(o, 0.6);
        }(),
      ];
    case SoundScene.hearth:
      return [
        for (var k = 0; k < 12; k++) () {
          final len = (kSampleRate * (3 + 5 * k / 11) / 1000).round();
          final bp = Biquad.bandpass(3000, 2);
          final o = Float64List(len);
          for (var i = 0; i < len; i++) {
            o[i] = bp.process(n.white()) * math.exp(-4.0 * i / len);
          }
          return _peak(o, 0.8);
        }(),
      ];
    default:
      return const [];
  }
}

Float64List _peak(Float64List s, double to) {
  var p = 1e-12;
  for (final v in s) {
    p = math.max(p, v.abs());
  }
  for (var i = 0; i < s.length; i++) {
    s[i] *= to / p;
  }
  return s;
}
