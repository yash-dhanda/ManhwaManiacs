import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/physics.dart';

/// One orb's springy offset and fade (glass 4.10, Step into the light): a critically-soft spring toward the origin, an impulse from
/// the chosen orb, and a fade toward [alphaTarget]. Pure: [step] is a fixed-`dt` integrator.
class OrbBody {
  OrbBody();
  Offset x = Offset.zero;
  Offset v = Offset.zero;
  double alpha = 1;
  double alphaTarget = 1;
  double scale = 1;
  double scaleTarget = 1;
  bool dragging = false;

  bool get resting => !dragging && x.distance < 0.05 && v.distance < 0.5 && (alpha - alphaTarget).abs() < 0.001 && (scale - scaleTarget).abs() < 0.001;

  /// Kicks the orb along [direction] (unit) at [speed] px/s.
  void impulse(Offset direction, double speed) => v = direction * speed;
}

/// The physics of the orb field: springs home, repels, fades and follows a drag 1:1.
class OrbPhysics {
  OrbPhysics({SpringDescription? spring, this.fadeMs = 350})
      : spring = spring ?? const SpringDescription(mass: 1, stiffness: 180, damping: 22);

  final SpringDescription spring;
  final int fadeMs;
  final Map<int, OrbBody> bodies = {};

  OrbBody body(int id) => bodies.putIfAbsent(id, OrbBody.new);

  bool get resting => bodies.values.every((b) => b.resting);

  /// The chosen orb inflates and every other orb gets a radial impulse of [speed] px/s away from it, fading out.
  void choose(int chosenId, Map<int, Offset> centres, {double speed = 900, double inflate = 1.35}) {
    final c = centres[chosenId];
    for (final e in centres.entries) {
      final b = body(e.key);
      if (e.key == chosenId) {
        b.alphaTarget = 1;
        b.scaleTarget = inflate;
        b.v = Offset.zero;
        continue;
      }
      b.alphaTarget = 0;
      b.scaleTarget = 1;
      final d = c == null ? const Offset(1, 0) : e.value - c;
      final len = d.distance;
      b.impulse(len < 0.001 ? const Offset(1, 0) : d / len, speed);
    }
  }

  /// Everything returns: alpha 1, scale 1, springs to the origin.
  void reset() {
    for (final b in bodies.values) {
      b
        ..alphaTarget = 1
        ..scaleTarget = 1;
    }
  }

  void drag(int id, Offset delta) {
    final b = body(id);
    b.dragging = true;
    b.x += delta;
    b.v = Offset.zero;
  }

  void release(int id, Offset velocity) {
    final b = body(id);
    b.dragging = false;
    b.v = velocity;
  }

  void step(double dt) {
    final k = spring.stiffness, c = spring.damping, m = spring.mass;
    final fade = dt / (fadeMs / 1000);
    for (final b in bodies.values) {
      if (!b.dragging) {
        final a = (b.x * -k - b.v * c) / m;
        b.v += a * dt;
        b.x += b.v * dt;
      }
      b.alpha += (b.alphaTarget - b.alpha).clamp(-fade, fade);
      final sk = 1 - math.exp(-dt * 14);
      b.scale += (b.scaleTarget - b.scale) * sk;
    }
  }
}
