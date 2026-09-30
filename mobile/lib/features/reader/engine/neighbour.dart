import 'dart:math' as math;
import 'package:manhwamaniacs/features/downloads/models/chapter_identity.dart';
import 'package:manhwamaniacs/features/reader/engine/zoom_math.dart' show rubberBand;

const double armPx = 48.0;
const double commitPx = 72.0;
const double overscrollC = 0.55;

enum NeighbourDirection { next, previous }

enum NeighbourPhase { idle, armed, locked }

enum NeighbourVia { touch, wheel }

class NeighbourEvent {
  const NeighbourEvent(this.phase, this.direction, this.via);
  final NeighbourPhase phase;
  final NeighbourDirection direction;
  final NeighbourVia via;
  @override
  String toString() => 'NeighbourEvent(${phase.name} ${direction.name} ${via.name})';
}

/// What `armNeighbour` resolves: the skin shows "42 pages - about 6 min".
class NeighbourInfo {
  const NeighbourInfo({required this.chapter, required this.pageCount, required this.firstPageUrl, required this.minutes});
  final ChapterIdentity chapter; // a ChapterRef
  final int pageCount;
  final String firstPageUrl;
  final int minutes;
}

int neighbourMinutes(int pageCount) => (pageCount * 0.15).ceil();

/// The displayed overscroll for a raw finger travel [raw] (sign kept) on the 0.55 band.
double displayedFromRaw(double raw, double viewportHeight) =>
    raw.sign * rubberBand(raw.abs(), viewportHeight, overscrollC);

/// Inverse of [displayedFromRaw].
double rawFromDisplayed(double y, double d) {
  final a = y.abs();
  if (a >= d) return y.sign * double.maxFinite;
  return y.sign * (d / overscrollC * (1 / (1 - a / d) - 1));
}

/// Wheel / trackpad accumulator [acc] px mapped to displayed px: 140 px -> 48, 210 px -> 72.
double wheelDisplayed(double acc) => acc <= 140 ? acc * 48 / 140 : 48 + (acc - 140) * 24 / 70;

/// The phase for [displayed] overscroll (sign is the direction, magnitude decides).
NeighbourPhase neighbourPhase(double displayed) {
  final a = displayed.abs();
  return a >= commitPx ? NeighbourPhase.locked : (a >= armPx ? NeighbourPhase.armed : NeighbourPhase.idle);
}

/// Accumulates wheel travel, resetting after 400 ms without input.
class WheelAccumulator {
  double _acc = 0;
  Duration? _last;
  double add(double delta, Duration now) {
    if (_last != null && now - _last! > const Duration(milliseconds: 400)) _acc = 0;
    _last = now;
    _acc = math.max(0, _acc + delta);
    return _acc;
  }

  void reset() {
    _acc = 0;
    _last = null;
  }
}

/// Distance a friction fling of [v0] px/s covers: `0.499 v0` (the v <- v 0.998^ms law).
double flingDistance(double v0) => v0 / (-1000 * math.log(0.998));

/// One [dtMs] step of the fling's decay.
double flingStep(double v, double dtMs) => v * math.pow(0.998, dtMs);

/// Whether a chapter ends the strip (`continuous`, today's reader) or the strip holds one chapter and
/// the neighbour is reached by a pull or a swipe (`single`).
enum ReaderChapterMode { continuous, single }
