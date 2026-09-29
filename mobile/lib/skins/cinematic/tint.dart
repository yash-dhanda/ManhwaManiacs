import 'dart:math' as math;

import 'package:flutter/painting.dart';
import 'package:manhwamaniacs/core/utils/contrast.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

Color _hls(double h, double l, double s) => HSLColor.fromAHSL(1, h % 360, s.clamp(0.0, 1.0), l.clamp(0.0, 1.0)).toColor();

const _black = Color(0xFF000000);

/// The three runtime colours of a series (cinematic 2.1.5); the backend owns the real `ambient`.
class AmbientRoles {
  const AmbientRoles({required this.duo, required this.tint, required this.ink});
  final Color duo, tint, ink;
}

/// The Issue stock: page, ink and muted ink.
class StockColours {
  const StockColours({required this.page, required this.ink, required this.muted});
  final Color page, ink, muted;
}

Color pageTint(double h, double s) => _hls(h, 0.06, math.min(s, 0.35));

Color pageLight(double h, double s) {
  var l = 0.75;
  final sat = s.clamp(0.35, 0.70);
  var c = _hls(h, l, sat);
  while (contrastRatio(c, _black) < 4.5 && l < 1) {
    l += 0.02;
    c = _hls(h, l, sat);
  }
  return c;
}

abstract final class CineTint {
  /// A reader page's seed (`#rrggbb`) to `page.light`; null falls back to the ambient ink.
  static Color light(String? seedHex) {
    final v = seedHex?.replaceFirst('#', '');
    final n = v == null ? null : int.tryParse(v.length == 6 ? 'FF$v' : v, radix: 16);
    if (n == null) return CineColors.ambientFallbackInk;
    final hsl = HSLColor.fromColor(Color(n));
    return pageLight(hsl.hue, hsl.saturation);
  }
}

AmbientRoles ambientRoles(double h, double s) {
  var l = 0.78;
  final sat = s.clamp(0.35, 0.70);
  var ink = _hls(h, l, sat);
  while (contrastRatio(ink, _black) < 7 && l < 1) {
    l += 0.03;
    ink = _hls(h, l, sat);
  }
  return AmbientRoles(duo: _hls(h, 0.62, s.clamp(0.45, 0.90)), tint: _hls(h, 0.06, math.min(s, 0.35)), ink: ink);
}

// OKLab (Ottosson) for the 10 % mix of the Issue ink.
List<double> _oklab(Color c) {
  double lin(double v) => v <= 0.04045 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  final r = lin(c.r), g = lin(c.g), b = lin(c.b);
  final l = math.pow(0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b, 1 / 3).toDouble();
  final m = math.pow(0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b, 1 / 3).toDouble();
  final s = math.pow(0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b, 1 / 3).toDouble();
  return [
    0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s,
    1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s,
    0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s,
  ];
}

Color _fromOklab(List<double> lab) {
  final l = math.pow(lab[0] + 0.3963377774 * lab[1] + 0.2158037573 * lab[2], 3).toDouble();
  final m = math.pow(lab[0] - 0.1055613458 * lab[1] - 0.0638541728 * lab[2], 3).toDouble();
  final s = math.pow(lab[0] - 0.0894841775 * lab[1] - 1.2914855480 * lab[2], 3).toDouble();
  double gam(double v) => (v <= 0.0031308 ? 12.92 * v : 1.055 * math.pow(v, 1 / 2.4) - 0.055).clamp(0.0, 1.0).toDouble();
  return Color.from(
    alpha: 1,
    red: gam(4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s),
    green: gam(-1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s),
    blue: gam(-0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s),
  );
}

StockColours issueStock(AmbientRoles? ambient) {
  if (ambient == null) {
    return const StockColours(page: CineColors.stockNitratePage, ink: CineColors.stockNitrateInk, muted: CineColors.stockNitrateMuted);
  }
  final page = ambient.tint;
  final a = _oklab(CineColors.ink100), b = _oklab(ambient.ink);
  var ink = _fromOklab([for (var i = 0; i < 3; i++) a[i] * 0.9 + b[i] * 0.1]);
  var hsl = HSLColor.fromColor(ink);
  while (contrastRatio(ink, page) < 13 && hsl.lightness < 1) {
    hsl = hsl.withLightness(math.min(1, hsl.lightness + 0.01));
    ink = hsl.toColor();
  }
  var mh = HSLColor.fromColor(ambient.ink);
  var muted = mh.toColor();
  while (mh.lightness > 0.01) {
    final next = mh.withLightness(mh.lightness - 0.01);
    if (contrastRatio(next.toColor(), page) < 5.5) break;
    mh = next;
    muted = mh.toColor();
  }
  return StockColours(page: page, ink: ink, muted: muted);
}
