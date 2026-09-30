import 'dart:math' as math;
import 'dart:ui';

import 'package:manhwamaniacs/skins/glass/copy/genres.dart';

/// One body of the genre field: a genre bubble. [weight] is 0 (none), 1 liked, 2 loved, -1 not for me.
class GenreBody {
  GenreBody({required this.name, required this.rank, required this.baseRadius, required this.p});
  final String name;
  final int rank;
  final double baseRadius;
  Offset p;
  Offset v = Offset.zero;
  int weight = 0;
  double scale = 1;
  bool asleep = false;
  int quiet = 0;

  /// The grid form (reduced motion) draws a fixed radius.
  double? fixedRadius;

  double get radius => fixedRadius ?? baseRadius * scale;
}

/// The size a weight grows a bubble to (glass 8.7): liked 1.25, loved 1.5, not for me 0.8.
double genreScaleFor(int weight) => switch (weight) {
      1 => 1.25,
      2 => 1.5,
      -1 => 0.8,
      _ => 1.0,
    };

/// A tap cycles 0 to 1 to 2 to 0.
int nextGenreWeight(int weight) => switch (weight) {
      0 => 1,
      1 => 2,
      2 => 0,
      _ => 1,
    };

/// The physics of the genre field (glass 8.7): position-based dynamics with 4 iterations per frame, pairwise overlaps resolved
/// half-and-half along the normal, restitution 0.4 against the walls, a centre pull `a = -4 (p - c)` px/s², gravity from the
/// device (1 g = 400 px/s²), sleeping after 30 frames under 2 px/s and waking on any input or a gravity change above 0.02 g. Pure.
class GenreField {
  GenreField({required this.size, required List<String> names, double radiusScale = 1}) {
    final c = size.center(Offset.zero);
    final n = names.length;
    for (var i = 0; i < n; i++) {
      // A spiral so the bodies start spread out and the solver has little to undo.
      final a = i * 2.399963;
      final d = 14.0 * math.sqrt(i + 1) * 3.2;
      bodies.add(GenreBody(name: names[i], rank: i + 1, baseRadius: genreRadius(i + 1, total: n) * radiusScale, p: c + Offset(math.cos(a), math.sin(a)) * d));
    }
  }

  static const double restitution = 0.4;
  static const double centrePull = 4;
  static const double sleepSpeed = 2;
  static const int sleepFrames = 30;
  static const int iterations = 4;
  static const double wakeGravity = 0.02;
  static const double pxPerG = 400;

  /// The scale that keeps the bodies at 62 % of the field's area at most (24 bubbles of 36 to 52 px radius do not pack into a phone
  /// column at full size); 1 when they already fit.
  static double fitScale(Size size, int n) {
    var area = 0.0;
    for (var i = 1; i <= n; i++) {
      final r = genreRadius(i, total: n);
      area += math.pi * r * r;
    }
    return math.min(1.0, math.sqrt(0.62 * size.width * size.height / area));
  }

  final Size size;
  final List<GenreBody> bodies = [];
  Offset _gravity = Offset.zero;

  Offset get gravity => _gravity;
  Offset get centre => size.center(Offset.zero);
  bool get allAsleep => bodies.every((b) => b.asleep);

  GenreBody? byName(String name) {
    for (final b in bodies) {
      if (b.name == name) return b;
    }
    return null;
  }

  /// Sets gravity in px/s²; a change above 0.02 g wakes everything.
  void setGravity(Offset g) {
    if ((g - _gravity).distance / pxPerG > wakeGravity) wake();
    _gravity = g;
  }

  void wake() {
    for (final b in bodies) {
      b
        ..asleep = false
        ..quiet = 0;
    }
  }

  void setWeight(String name, int weight) {
    final b = byName(name);
    if (b == null) return;
    b.weight = weight;
    wake();
  }

  /// A drag moves [name] 1:1.
  void dragTo(String name, Offset p) {
    final b = byName(name);
    if (b == null) return;
    b.p = p;
    b.v = Offset.zero;
    wake();
  }

  void fling(String name, Offset velocity) {
    final b = byName(name);
    if (b == null) return;
    b.v = velocity;
    wake();
  }

  /// Rest positions in a [columns]-column grid (the reduced-motion form): no physics, and a weight changes a bubble's size without a
  /// spring. Call again after a weight changes.
  void layoutGrid(int columns, {double gap = 8}) {
    final cell = (size.width - gap * (columns - 1)) / columns;
    for (var i = 0; i < bodies.length; i++) {
      final b = bodies[i];
      b.p = Offset((i % columns) * (cell + gap) + cell / 2, (i ~/ columns) * (cell + gap) + cell / 2);
      b.v = Offset.zero;
      b.asleep = true;
      b.fixedRadius = cell / 2 * math.min(1.0, 0.62 * genreScaleFor(b.weight));
    }
  }

  /// The height the grid needs.
  double gridHeight(int columns, {double gap = 8}) {
    final cell = (size.width - gap * (columns - 1)) / columns;
    final rows = (bodies.length / columns).ceil();
    return rows * cell + (rows - 1) * gap;
  }

  /// One frame; [dt] is clamped to 1/30 s.
  void step(double dt) {
    dt = math.min(dt, 1 / 30);
    for (final b in bodies) {
      final target = genreScaleFor(b.weight);
      if ((b.scale - target).abs() > 0.001) {
        b.scale += (target - b.scale) * (1 - math.exp(-dt * 12));
        b.asleep = false;
        b.quiet = 0;
      } else {
        b.scale = target;
      }
    }
    final c = centre;
    for (final b in bodies) {
      if (b.asleep) continue;
      final a = _gravity + (b.p - c) * -centrePull;
      b.v += a * dt;
      b.p += b.v * dt;
    }
    for (var it = 0; it < iterations; it++) {
      for (var i = 0; i < bodies.length; i++) {
        for (var j = i + 1; j < bodies.length; j++) {
          final a = bodies[i], b = bodies[j];
          final d = b.p - a.p;
          final dist = d.distance;
          final min = a.radius + b.radius;
          if (dist >= min) continue;
          if (a.asleep != b.asleep) {
            a.asleep = false;
            b.asleep = false;
          }
          final n = dist < 1e-6 ? const Offset(1, 0) : d / dist;
          final push = (min - dist) / 2;
          a.p -= n * push;
          b.p += n * push;
          // Remove the approaching velocity, with the same restitution as the walls.
          final rel = (b.v - a.v).dx * n.dx + (b.v - a.v).dy * n.dy;
          if (rel < 0) {
            final j2 = -(1 + restitution) * rel / 2;
            a.v -= n * j2;
            b.v += n * j2;
          }
        }
      }
      for (final b in bodies) {
        _wall(b);
      }
    }
    for (final b in bodies) {
      if (b.asleep) continue;
      if (b.v.distance < sleepSpeed) {
        b.quiet++;
        if (b.quiet >= sleepFrames) {
          b.asleep = true;
          b.v = Offset.zero;
        }
      } else {
        b.quiet = 0;
      }
    }
  }

  void _wall(GenreBody b) {
    final r = b.radius;
    var x = b.p.dx, y = b.p.dy, vx = b.v.dx, vy = b.v.dy;
    if (x < r) {
      x = r;
      if (vx < 0) vx = -vx * restitution;
    } else if (x > size.width - r) {
      x = size.width - r;
      if (vx > 0) vx = -vx * restitution;
    }
    if (y < r) {
      y = r;
      if (vy < 0) vy = -vy * restitution;
    } else if (y > size.height - r) {
      y = size.height - r;
      if (vy > 0) vy = -vy * restitution;
    }
    b.p = Offset(x, y);
    b.v = Offset(vx, vy);
  }

  /// The body nearest to [from] in [direction] (radians, screen coordinates) within +-45 degrees, or null.
  GenreBody? nearest(GenreBody from, double direction) {
    GenreBody? best;
    var bestD = double.infinity;
    for (final b in bodies) {
      if (identical(b, from)) continue;
      final d = b.p - from.p;
      var diff = (math.atan2(d.dy, d.dx) - direction).abs();
      if (diff > math.pi) diff = 2 * math.pi - diff;
      if (diff > math.pi / 4) continue;
      if (d.distance < bestD) {
        bestD = d.distance;
        best = b;
      }
    }
    return best;
  }
}
