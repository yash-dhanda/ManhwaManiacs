/// The voice orbit's per-card maths (glass 8.16.4, B4). [offset] is the card's signed distance from the centre in cards.
library;

import 'dart:math' as math;

/// A 160 px card and a 16 px gap.
const double kOrbitStride = 176;
const double kOrbitCardWidth = 160, kOrbitCardHeight = 220;

double orbitRotateY(double offset) => 18 * math.pi / 180 * offset.clamp(-2.0, 2.0);

double orbitScale(double offset) => 1 - 0.14 * math.min(offset.abs(), 1.0);

double orbitOpacity(double offset) => 1 - 0.4 * math.min(offset.abs(), 1.0);

/// The dot on the 80-300 Hz pitch track, 0 (deeper) to 1 (brighter).
double pitchPosition(double pitchHz) => ((pitchHz.clamp(80.0, 300.0) - 80) / 220).toDouble();

/// The raw `expressiveness` has no fixed range, so the five dots rank a voice among the loaded list: rank 1..n.
int expressivenessDots(int rank, int n) => n <= 0 ? 0 : (5 * rank / n).ceil().clamp(1, 5);

/// Ranks (1 = flattest) of [values] among themselves, ties sharing the earlier rank.
List<int> expressivenessRanks(List<double> values) {
  final sorted = [...values]..sort();
  return [for (final v in values) sorted.indexOf(v) + 1];
}
