import 'dart:math' as math;
import 'dart:ui';

import 'package:manhwamaniacs/features/reader/engine/page_sample.dart';

/// The `Lb` of a reader surface (glass 2.1.7): the maximum of the sample's bands its rect overlaps (top quarter, middle half,
/// bottom quarter of the viewport); 1.0 until a sample lands.
double bandLb(Rect surface, Size viewport, PageSample? s) {
  if (s == null) return 1.0;
  final q = viewport.height / 4;
  var v = 0.0;
  if (surface.top < q) v = math.max(v, s.pTop);
  if (surface.bottom > q && surface.top < viewport.height - q) v = math.max(v, s.pMid);
  if (surface.bottom > viewport.height - q) v = math.max(v, s.pBottom);
  return v;
}

/// `clamp(0.22 + 0.42 x Lb, 0.22, 0.64)`: the legibility dim a reader surface folds into its fill.
double dimLegibility(double lb) => (0.22 + 0.42 * lb).clamp(0.22, 0.64);
