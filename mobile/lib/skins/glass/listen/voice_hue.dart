import 'dart:math' as math;
import 'dart:ui' show Color;

import 'package:manhwamaniacs/core/color/oklch.dart';

/// A voice's colour (glass 8.16; the web twin's rule): OKLCH L 0.80, C 0.12, hue 250 degrees at 80 Hz (deep, blue-violet) to 40 degrees at
/// 300 Hz (bright, warm), chroma reduced in 0.01 steps until the colour is in sRGB.
Color voiceHue(double pitchHz) {
  final hz = pitchHz.isNaN ? 150.0 : pitchHz.clamp(80.0, 300.0);
  final h = 250 - (hz - 80) / 220 * 210;
  for (var c = 0.12; c > 0; c = (c - 0.01).clamp(0.0, 1.0)) {
    if (_inGamut(0.80, c, h)) return colorFromOklch(Oklch(0.80, c, h));
    if (c < 0.011) break;
  }
  return colorFromOklch(Oklch(0.80, 0, h));
}

bool _inGamut(double l, double c, double h) {
  final hr = h * math.pi / 180;
  final l_ = l + 0.3963377774 * c * math.cos(hr) + 0.2158037573 * c * math.sin(hr);
  final m_ = l - 0.1055613458 * c * math.cos(hr) - 0.0638541728 * c * math.sin(hr);
  final s_ = l - 0.0894841775 * c * math.cos(hr) - 1.2914855480 * c * math.sin(hr);
  final lc = l_ * l_ * l_, mc = m_ * m_ * m_, sc = s_ * s_ * s_;
  final r = 4.0767416621 * lc - 3.3077115913 * mc + 0.2309699292 * sc;
  final g = -1.2684380046 * lc + 2.6097574011 * mc - 0.3413193965 * sc;
  final b = -0.0041960863 * lc - 0.7034186147 * mc + 1.7076147010 * sc;
  const e = 1e-6;
  return r >= -e && r <= 1 + e && g >= -e && g <= 1 + e && b >= -e && b <= 1 + e;
}
