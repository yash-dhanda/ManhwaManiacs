
import 'package:flutter/physics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/glass/screens/profiles/orb_physics.dart';

void main() {
  test('choosing inflates the chosen orb and repels the others along the line from it', () {
    final p = OrbPhysics(spring: const SpringDescription(mass: 1, stiffness: 180, damping: 22));
    p.choose(1, {1: const Offset(100, 100), 2: const Offset(300, 100), 3: const Offset(100, 300)});
    expect(p.body(1).scaleTarget, 1.35);
    expect(p.body(2).v.dx, closeTo(900, 1e-6));
    expect(p.body(2).v.dy, closeTo(0, 1e-6));
    expect(p.body(3).v.dy, closeTo(900, 1e-6));
    expect(p.body(2).alphaTarget, 0);
    expect(p.body(1).alphaTarget, 1);
  });

  test('a repelled orb flies out then springs home while it fades', () {
    final p = OrbPhysics();
    p.choose(1, {1: Offset.zero, 2: const Offset(200, 0)});
    var peak = 0.0;
    for (var i = 0; i < 30; i++) {
      p.step(1 / 60);
      if (p.body(2).x.dx > peak) peak = p.body(2).x.dx;
    }
    expect(peak, greaterThan(10));
    for (var i = 0; i < 240; i++) {
      p.step(1 / 60);
    }
    expect(p.body(2).x.dx.abs(), lessThan(0.5));
    expect(p.body(2).alpha, 0);
  });

  test('dragging follows 1:1 and a release springs home with the release velocity', () {
    final p = OrbPhysics();
    p.drag(1, const Offset(30, 10));
    expect(p.body(1).x, const Offset(30, 10));
    expect(p.resting, isFalse);
    p.release(1, const Offset(500, 0));
    for (var i = 0; i < 400; i++) {
      p.step(1 / 60);
    }
    expect(p.body(1).x.distance, lessThan(0.1));
  });
}
