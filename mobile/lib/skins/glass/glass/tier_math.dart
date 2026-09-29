import 'dart:math' as math;
import 'dart:ui';

import 'package:manhwamaniacs/skins/glass/physics/glass_physics.dart';
import 'package:manhwamaniacs/skins/glass/tokens.g.dart';

/// Chromatic aberration per tier on the Flutter path (glass 2.4.3 Flutter mapping; the web `dispersion`
/// column is a CSS quantity and does not carry over).
const List<double> kFlutterChromatic = [0, 0, 0, 0.35, 0.5];

/// The library's default refractive index, the calibration starting point (glass 2.4.3 knobs).
const double kRefractiveIndex = 1.2;

/// Every numeric parameter of one tier, so a growing surface can interpolate them (glass 2.4.2 rule 2).
class TierParams {
  const TierParams({
    required this.thickness,
    required this.blur,
    required this.saturate,
    required this.fill,
    required this.specular,
    required this.shadowOffsetY,
    required this.shadowBlur,
    required this.shadowColor,
    required this.chromatic,
    required this.rond,
    required this.rim,
  });

  final double thickness;
  final double blur;
  final double saturate;
  final Color fill;
  final double specular;
  final double shadowOffsetY;
  final double shadowBlur;
  final Color shadowColor;
  final double chromatic;
  final double rond;
  final Color rim;
}

GlassTier _tierToken(int i) => switch (i) {
      1 => glassTokens.glassT1,
      2 => glassTokens.glassT2,
      3 => glassTokens.glassT3,
      4 => glassTokens.glassT4,
      _ => glassTokens.glassT5,
    };

TierParams tierParamsAt(int tier) {
  final t = _tierToken(tier);
  return TierParams(
    thickness: t.thickness,
    blur: t.blur,
    saturate: t.saturate,
    fill: t.fill,
    specular: t.specular,
    shadowOffsetY: t.shadow.offset.dy,
    shadowBlur: t.shadow.blurRadius,
    shadowColor: t.shadow.color,
    chromatic: kFlutterChromatic[tier - 1],
    rond: t.rond,
    rim: t.rim,
  );
}

TierParams tierParams(GlassTierId id) => tierParamsAt(switch (id) {
      GlassTierId.t1 => 1,
      GlassTierId.t2 => 2,
      GlassTierId.t3 => 3,
      GlassTierId.t4 => 4,
      GlassTierId.t5 => 5,
      GlassTierId.auto => 3,
    },);

/// Interpolates every tier parameter between the neighbouring tiers for a [tierValue] of 1.0 to 5.0.
TierParams lerpTier(double tierValue) {
  final v = tierValue.clamp(1.0, 5.0);
  final lo = math.min(v.floor(), 4);
  final f = v - lo;
  final a = tierParamsAt(lo);
  final b = tierParamsAt(lo + 1);
  double l(double x, double y) => x + (y - x) * f;
  return TierParams(
    thickness: l(a.thickness, b.thickness),
    blur: l(a.blur, b.blur),
    saturate: l(a.saturate, b.saturate),
    fill: Color.lerp(a.fill, b.fill, f)!,
    specular: l(a.specular, b.specular),
    shadowOffsetY: l(a.shadowOffsetY, b.shadowOffsetY),
    shadowBlur: l(a.shadowBlur, b.shadowBlur),
    shadowColor: Color.lerp(a.shadowColor, b.shadowColor, f)!,
    chromatic: l(a.chromatic, b.chromatic),
    rond: l(a.rond, b.rond),
    rim: Color.lerp(a.rim, b.rim, f)!,
  );
}

/// Folds the `dimLegibility` layer (black at [dim], beneath the fill) and [fill] into one colour that
/// composites identically over any backdrop under source-over: `a' = 1 - (1 - dim)(1 - a)`, `rgb' = c a / a'`.
Color foldDim(Color fill, double dim) {
  final a = fill.a;
  final a2 = 1 - (1 - dim) * (1 - a);
  if (a2 <= 0) return const Color(0x00000000);
  final k = a / a2;
  return Color.from(alpha: a2, red: fill.r * k, green: fill.g * k, blue: fill.b * k);
}

/// The 4x5 colour matrix that scales saturation by [s] (Rec. 709 luma weights), for the frost path.
List<double> saturationMatrix(double s) {
  const r = 0.2126, g = 0.7152, b = 0.0722;
  final ir = (1 - s) * r, ig = (1 - s) * g, ib = (1 - s) * b;
  return [
    ir + s, ig, ib, 0, 0, //
    ir, ig + s, ib, 0, 0,
    ir, ig, ib + s, 0, 0,
    0, 0, 0, 1, 0,
  ];
}
