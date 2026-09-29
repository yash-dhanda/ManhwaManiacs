import 'dart:math' as math;
import 'dart:ui';

/// WCAG 2.x relative luminance of [color] (0 = black, 1 = white).
///
/// https://www.w3.org/TR/WCAG21/#dfn-relative-luminance
double relativeLuminance(Color color) {
  double linear(double channel) => channel <= 0.04045
      ? channel / 12.92
      : math.pow((channel + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * linear(color.r) + 0.7152 * linear(color.g) + 0.0722 * linear(color.b);
}

/// WCAG contrast ratio between two colours, 1:1 … 21:1. Order-independent.
double contrastRatio(Color a, Color b) {
  final la = relativeLuminance(a);
  final lb = relativeLuminance(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

/// [top] (with its alpha) source-over [ground]; the result is opaque when [ground] is.
Color compositeOver(Color top, Color ground) {
  final a = top.a;
  final ga = ground.a;
  final oa = a + ga * (1 - a);
  if (oa <= 0) return const Color(0x00000000);
  double mix(double t, double g) => (t * a + g * ga * (1 - a)) / oa;
  return Color.from(alpha: oa, red: mix(top.r, ground.r), green: mix(top.g, ground.g), blue: mix(top.b, ground.b));
}
