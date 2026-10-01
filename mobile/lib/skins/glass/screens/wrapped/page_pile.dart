import 'dart:math' as math;
import 'dart:ui';

// The Volume card's page-glyph pile (glass 9.2.3): a pure simulation of at most 200 pages falling into 8 px columns.

const double kPileGravity = 2400;
const double kPileRestitution = 0.3;
const double kPageW = 6, kPageH = 8, kColumn = 8;

/// `clamp((pagesRead / 200).round(), 20, 200)` glyphs.
int pileCount(int pagesRead) => (pagesRead / 200).round().clamp(20, 200);

class PageBody {
  PageBody({required this.column, required this.x, required this.y, required this.delay, required this.tilt});
  final int column;
  final double x;
  double y;
  double vy = 0;
  final double delay;
  final double tilt;
  bool asleep = false;
  double age = 0;
}

class PagePile {
  PagePile({required int pages, required this.size, int seed = 1}) {
    final rng = math.Random(seed);
    final n = pileCount(pages);
    _columns = math.max(1, (size.width / kColumn).floor());
    _heights = List<double>.filled(_columns, 0);
    bodies = [
      for (var i = 0; i < n; i++)
        () {
          final c = rng.nextInt(_columns);
          return PageBody(column: c, x: c * kColumn + kColumn / 2, y: -kPageH - rng.nextDouble() * 40, delay: i * 0.012, tilt: (rng.nextDouble() - 0.5) * 0.5);
        }(),
    ];
  }

  final Size size;
  late final int _columns;
  late final List<double> _heights;
  late final List<PageBody> bodies;

  bool get asleep => bodies.every((b) => b.asleep);

  /// The y (top of the glyph) a body in [column] comes to rest at, given what has already landed there.
  double _floor(int column) => size.height - _heights[column] - kPageH;

  void step(double dt) {
    var left = math.min(dt, 0.05);
    while (left > 0) {
      final h = math.min(left, 1 / 240);
      left -= h;
      for (final b in bodies) {
        if (b.asleep) continue;
        b.age += h;
        if (b.age < b.delay) continue;
        b.vy += kPileGravity * h;
        b.y += b.vy * h;
        final floor = _floor(b.column);
        if (b.y >= floor) {
          b.y = floor;
          if (b.vy.abs() < 60) {
            b.asleep = true;
            b.vy = 0;
            _heights[b.column] += kPageH;
          } else {
            b.vy = -b.vy * kPileRestitution;
          }
        }
      }
    }
  }

  /// Runs to rest (reduced motion and the share PNG show the settled pile).
  void settle() {
    for (var i = 0; i < 4000 && !asleep; i++) {
      step(1 / 60);
    }
    for (final b in bodies.where((b) => !b.asleep)) {
      b.y = _floor(b.column);
      b.asleep = true;
      _heights[b.column] += kPageH;
    }
  }

  Rect rectOf(PageBody b) => Rect.fromLTWH(b.x - kPageW / 2, b.y, kPageW, kPageH);
}
