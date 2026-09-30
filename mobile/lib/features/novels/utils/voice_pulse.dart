/// The voice pulse (cinematic 4.5): the highlighter band behind a playing sample's name breathes
/// with its loudness. RMS of the latest samples, smoothed with attack 80 ms and release 240 ms.
library;

import 'dart:math' as math;

const Duration kPulseAttack = Duration(milliseconds: 80);
const Duration kPulseRelease = Duration(milliseconds: 240);

/// RMS of [samples] (typically 256 floats in -1..1), 0-1.
double rms(Iterable<double> samples) {
  var sum = 0.0;
  var n = 0;
  for (final s in samples) {
    sum += s * s;
    n++;
  }
  return n == 0 ? 0 : math.min(1.0, math.sqrt(sum / n));
}

/// A one-pole smoother: `a = 1 - exp(-dt / tau)`, tau being the attack when the input rises and
/// the release when it falls.
class VoicePulse {
  double _value = 0;
  double get value => _value;

  double step(double input, Duration dt) {
    final tau = input > _value ? kPulseAttack : kPulseRelease;
    final a = 1 - math.exp(-dt.inMicroseconds / tau.inMicroseconds);
    _value += (input - _value) * a;
    return _value;
  }

  void reset() => _value = 0;
}

/// The band's alpha for a pulse [value]: `0.08 + 0.24 x RMS`; under reduced motion a static 0.20.
double pulseAlpha(double value, {required bool reduced}) => reduced ? 0.20 : 0.08 + 0.24 * value.clamp(0.0, 1.0);
