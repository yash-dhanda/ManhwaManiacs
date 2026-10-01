import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/painting.dart' show EdgeInsets;

import 'package:manhwamaniacs/skins/glass/frame.dart';

// The Wrapped frame (glass 9.2.3): one 360 x 640 logical frame scaled uniformly, and the fixed slots inside it.

const Size kWrappedFrame = Size(360, 640);

/// The frame's uniform scale. Phones: `min((width - 32) / 360, (height - 32 - safeTop - safeBottom) / 640)`; tablet and desktop
/// frames: `min(1.2, (height - 64) / 640)`.
double frameScale(Size screen, EdgeInsets safe, GlassFrameKind kind) {
  if (kind == GlassFrameKind.phone) {
    return math.min((screen.width - 32) / kWrappedFrame.width, (screen.height - 32 - safe.top - safe.bottom) / kWrappedFrame.height);
  }
  return math.min(1.2, (screen.height - 64) / kWrappedFrame.height);
}

/// The slot rectangles in frame units (360 x 640).
abstract final class WrappedSlots {
  static const Rect capsules = Rect.fromLTRB(16, 12, 344, 16);
  static const Rect buttons = Rect.fromLTRB(24, 24, 336, 68);
  static const Rect safe = Rect.fromLTRB(24, 0, 336, 640);
  static const Rect eyebrow = Rect.fromLTRB(24, 72, 336, 88);
  static const Rect headline = Rect.fromLTRB(24, 96, 336, 200);
  static const Rect coverHeadline = Rect.fromLTRB(24, 96, 336, 240);
  static const Rect figure = Rect.fromLTRB(24, 216, 336, 520);
  static const Rect footnote = Rect.fromLTRB(24, 528, 336, 552);
  static const Rect export = Rect.fromLTRB(232, 576, 336, 620);

  /// Card 4's "Recommend" capsule (mobile/43).
  static const Rect recommend = Rect.fromLTRB(24, 576, 128, 620);
}

/// [r] (frame units) scaled by [scale] and placed at [origin] (the frame's top-left on screen).
Rect scaledSlot(Rect r, double scale, Offset origin) => Rect.fromLTRB(origin.dx + r.left * scale, origin.dy + r.top * scale, origin.dx + r.right * scale, origin.dy + r.bottom * scale);

/// The frame's size in real pixels.
Size frameSize(double scale) => Size(kWrappedFrame.width * scale, kWrappedFrame.height * scale);

/// `f = textScale(17) / 17`; at 1.3 and above the cards reflow into columns (glass 3.3 rule 5).
const double kLargeTextScale = 1.3;
bool largeText(double f) => f >= kLargeTextScale;
