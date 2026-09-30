import 'dart:math' as math;

import 'package:manhwamaniacs/skins/glass/physics/glass_physics.dart';

// Pure stack-overview numbers (glass 7.37): how many cards, where they sit, and when a swipe removes one.

/// Up to eight slots; older levels compress into a "+N earlier" card at the top.
const int kStackSlots = 8;
const double kCardScale = 0.62;
const double kFanDegrees = 14;
const double kFanPerspective = 0.0012;
const double kCardRadius = 26;
const double kCardSpacing = 0.28;

class StackSlots {
  const StackSlots({required this.earlier, required this.first, required this.count});

  /// How many older levels the "+N earlier" card stands for (0 when there is none).
  final int earlier;

  /// The index of the first real level shown.
  final int first;

  /// The slots drawn, the "+N earlier" card included.
  final int count;
}

/// [levels] levels: all of them up to eight; above eight the top slot is the "+N earlier" card and the newest seven follow.
StackSlots stackSlots(int levels) {
  if (levels <= kStackSlots) return StackSlots(earlier: 0, first: 0, count: levels);
  const shown = kStackSlots - 1;
  return StackSlots(earlier: levels - shown, first: levels - shown, count: kStackSlots);
}

/// The vertical offsets of [slots] cards, deepest first at the top: spaced by 28 % of the scaled height [cardHeight], compressed
/// when they would not fit in [available].
List<double> cardOffsets(int slots, double cardHeight, {double? available}) {
  if (slots <= 0) return const [];
  var spacing = kCardSpacing * cardHeight;
  if (available != null && slots > 1) spacing = math.min(spacing, math.max(0, (available - cardHeight) / (slots - 1)));
  return [for (var i = 0; i < slots; i++) i * spacing];
}

/// A sideways swipe removes the card when its projected offset passes 40 % of its width.
bool swipeRemoves(double dx, double velocity, double cardWidth) => project(dx, velocity).abs() > 0.4 * cardWidth;

/// The strata rim's tint mix and the card's aspect are the screen's; the card's scaled size is:
({double width, double height}) cardSize(double screenWidth, double screenHeight) => (width: screenWidth * kCardScale, height: screenHeight * kCardScale);
