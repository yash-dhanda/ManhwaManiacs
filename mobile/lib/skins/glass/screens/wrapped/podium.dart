import 'dart:math' as math;
import 'dart:ui';

// The Top five podium (glass 9.2.3): rest rectangles in the 312 x 304 figure box and the drop of the covers.

const double kPodiumGravity = 3000;
const double kPodiumRestitution = 0.3;
const double kPodiumFrom = 200;
const double kPodiumStaggerMs = 120;

/// Rest rectangle of the cover of [rank] (1 to 5) in figure units (the frame's x - 24, y - 216).
Rect podiumRest(int rank) => switch (rank) {
      1 => const Rect.fromLTWH(104, 20, 104, 156),
      2 => const Rect.fromLTWH(4, 44, 88, 132),
      3 => const Rect.fromLTWH(220, 44, 88, 132),
      4 => const Rect.fromLTWH(0, 208, 32, 48),
      _ => const Rect.fromLTWH(0, 256, 32, 48),
    };

/// The step a cover stands on: 16 px under #1, 8 px under #2 and #3; none for #4 and #5.
Rect? podiumStep(int rank) => switch (rank) {
      1 => const Rect.fromLTWH(104, 176, 104, 16),
      2 => const Rect.fromLTWH(4, 176, 88, 8),
      3 => const Rect.fromLTWH(220, 176, 88, 8),
      _ => null,
    };

/// When [rank] starts to fall: #5 first, then #4, #3, #2, #1, 120 ms apart.
double dropStartMs(int rank) => (5 - rank) * kPodiumStaggerMs;

/// The vertical offset of [rank]'s cover (px above its rest, negative while it is in the air) [tMs] after the drop began: a fall of
/// 200 px under 3,000 px/s^2, bouncing with restitution 0.3 until it is at rest.
double dropOffset(int rank, double tMs) {
  var t = (tMs - dropStartMs(rank)) / 1000;
  if (t <= 0) return -kPodiumFrom;
  final tFall = math.sqrt(2 * kPodiumFrom / kPodiumGravity);
  if (t < tFall) return -kPodiumFrom + 0.5 * kPodiumGravity * t * t;
  t -= tFall;
  var v = kPodiumGravity * tFall * kPodiumRestitution;
  for (var i = 0; i < 8; i++) {
    final air = 2 * v / kPodiumGravity;
    if (t < air) return -(v * t - 0.5 * kPodiumGravity * t * t);
    t -= air;
    v *= kPodiumRestitution;
    if (v < 20) break;
  }
  return 0;
}

/// When every cover is at rest (ms).
double dropEndMs() {
  var end = 0.0;
  for (var r = 1; r <= 5; r++) {
    for (var t = dropStartMs(r); t < 4000; t += 8) {
      if (dropOffset(r, t) == 0 && t > dropStartMs(r) + 300) {
        end = math.max(end, t);
        break;
      }
    }
  }
  return end;
}

/// The moment cover [rank] first lands (ms from the start).
double landMs(int rank) => dropStartMs(rank) + math.sqrt(2 * kPodiumFrom / kPodiumGravity) * 1000;
