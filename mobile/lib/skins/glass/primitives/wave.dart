import 'dart:math' as math;
import 'dart:ui' show Offset, Rect;

import 'package:manhwamaniacs/skins/glass/tokens.g.dart';

/// glass 4.8: `delay_i = min(distance_i / 1.6 px/ms, 240 ms)` from the cause point. Items outside the
/// viewport get `null` (no entrance).
Map<int, Duration?> waveDelays(List<Rect> items, Offset cause, Rect viewport) {
  final out = <int, Duration?>{};
  for (var i = 0; i < items.length; i++) {
    final r = items[i];
    if (!r.overlaps(viewport)) {
      out[i] = null;
      continue;
    }
    final ms = math.min((r.center - cause).distance / GlassPhysics.waveSpeed, GlassPhysics.waveMaxDelay);
    out[i] = Duration(microseconds: (ms * 1000).round());
  }
  return out;
}
