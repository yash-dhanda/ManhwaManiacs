import 'dart:math' as math;
import 'dart:ui';

/// A colour in OKLCH: lightness 0..1, chroma ~0..0.4, hue in degrees.
class Oklch {
  const Oklch(this.l, this.c, this.h);
  final double l;
  final double c;
  final double h;

  Oklch copyWith({double? l, double? c, double? h}) => Oklch(l ?? this.l, c ?? this.c, h ?? this.h);

  @override
  String toString() => 'Oklch($l, $c, $h)';
}

double _toLinear(double v) => v <= 0.04045 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
double _fromLinear(double v) => v <= 0.0031308 ? v * 12.92 : 1.055 * math.pow(v, 1 / 2.4).toDouble() - 0.055;

/// sRGB channel values (0..1, gamma encoded) to OKLab (l, a, b).
(double, double, double) srgbToOklab(double r, double g, double b) {
  final lr = _toLinear(r), lg = _toLinear(g), lb = _toLinear(b);
  final l = math.pow(0.4122214708 * lr + 0.5363325363 * lg + 0.0514459929 * lb, 1 / 3).toDouble();
  final m = math.pow(0.2119034982 * lr + 0.6806995451 * lg + 0.1073969566 * lb, 1 / 3).toDouble();
  final s = math.pow(0.0883024619 * lr + 0.2817188376 * lg + 0.6299787005 * lb, 1 / 3).toDouble();
  return (
    0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s,
    1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s,
    0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s,
  );
}

/// OKLab to linear sRGB (unclamped).
(double, double, double) _oklabToLinear(double L, double a, double b) {
  final l = math.pow(L + 0.3963377774 * a + 0.2158037573 * b, 3).toDouble();
  final m = math.pow(L - 0.1055613458 * a - 0.0638541728 * b, 3).toDouble();
  final s = math.pow(L - 0.0894841775 * a - 1.2914855480 * b, 3).toDouble();
  return (
    4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s,
    -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s,
    -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s,
  );
}

Oklch oklchFromColor(Color c) {
  final (l, a, b) = srgbToOklab(c.r, c.g, c.b);
  final chroma = math.sqrt(a * a + b * b);
  var h = math.atan2(b, a) * 180 / math.pi;
  if (h < 0) h += 360;
  return Oklch(l, chroma, chroma < 1e-6 ? 0 : h);
}

bool _inGamut((double, double, double) rgb) {
  const e = 1e-6;
  return rgb.$1 >= -e && rgb.$1 <= 1 + e && rgb.$2 >= -e && rgb.$2 <= 1 + e && rgb.$3 >= -e && rgb.$3 <= 1 + e;
}

/// Converts back to sRGB, reducing chroma until the colour is in gamut (hue and lightness are kept).
Color colorFromOklch(Oklch o, {double alpha = 1}) {
  (double, double, double) at(double c) {
    final hr = o.h * math.pi / 180;
    return _oklabToLinear(o.l, c * math.cos(hr), c * math.sin(hr));
  }

  var rgb = at(o.c);
  if (!_inGamut(rgb)) {
    var lo = 0.0, hi = o.c;
    for (var i = 0; i < 24; i++) {
      final mid = (lo + hi) / 2;
      if (_inGamut(at(mid))) {
        lo = mid;
      } else {
        hi = mid;
      }
    }
    rgb = at(lo);
  }
  double enc(double v) => _fromLinear(v.clamp(0.0, 1.0));
  return Color.from(alpha: alpha, red: enc(rgb.$1), green: enc(rgb.$2), blue: enc(rgb.$3));
}

/// Mixes two colours in OKLab (perceptual, no grey dip).
Color mixOklab(Color a, Color b, double t) {
  final (l1, a1, b1) = srgbToOklab(a.r, a.g, a.b);
  final (l2, a2, b2) = srgbToOklab(b.r, b.g, b.b);
  final L = l1 + (l2 - l1) * t, A = a1 + (a2 - a1) * t, B = b1 + (b2 - b1) * t;
  final rgb = _oklabToLinear(L, A, B);
  double enc(double v) => _fromLinear(v.clamp(0.0, 1.0));
  return Color.from(alpha: a.a + (b.a - a.a) * t, red: enc(rgb.$1), green: enc(rgb.$2), blue: enc(rgb.$3));
}

/// WCAG relative luminance of an sRGB colour, 0..1.
double relativeLuminance(Color c) => 0.2126 * _toLinear(c.r) + 0.7152 * _toLinear(c.g) + 0.0722 * _toLinear(c.b);
