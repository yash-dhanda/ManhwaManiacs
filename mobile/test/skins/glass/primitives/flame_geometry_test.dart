import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/glass/primitives/flame_geometry.dart';

void main() {
  test('the lean is capped at 18 % of the height', () {
    final l = flameLean(gravity: const Offset(5, 5), scrollAccel: 50000, height: 100);
    expect(l.distance, closeTo(18, 1e-9));
    expect(flameLean(gravity: Offset.zero, scrollAccel: 0, height: 100), Offset.zero);
  });

  test('the tip rests at zero with no push and follows a steady one', () {
    final t = FlameTip();
    for (var i = 0; i < 600; i++) {
      t.step(1 / 60, Offset.zero);
    }
    expect(t.resting, isTrue);
    t.pos = const Offset(10, -6);
    for (var i = 0; i < 600; i++) {
      t.step(1 / 60, const Offset(4, 0));
    }
    expect(t.pos.dx, closeTo(4, 0.05));
    expect(t.pos.dy, closeTo(0, 0.05));
  });

  test('the flicker stays within 2 % of the height', () {
    var maxSeen = 0.0;
    for (var i = 0; i < 2000; i++) {
      maxSeen = math.max(maxSeen, flameFlicker(i / 100, 200).abs());
      maxSeen = math.max(maxSeen, flameFlicker(i / 100, 200, slow: true).abs());
    }
    expect(maxSeen, lessThanOrEqualTo(4.0));
    expect(maxSeen, greaterThan(0.5));
  });

  test('the teardrop path has a bounded, non-empty outline', () {
    const s = Size(96, 96);
    final b = teardrop(s, const Offset(48, 0), 0).getBounds();
    expect(b.isEmpty, isFalse);
    expect(b.top, closeTo(0, 0.01));
    expect(b.bottom, lessThanOrEqualTo(96.001));
    final inner = teardrop(s, const Offset(48, 0), 14).getBounds();
    expect(inner.width, lessThan(b.width));
  });

  test('embers rise and die after 900 ms', () {
    final e = spawnEmbers(Offset.zero, math.Random(1));
    expect(e.length, 8);
    for (final x in e) {
      for (var i = 0; i < 40; i++) {
        x.step(0.025);
      }
      expect(x.dead, isTrue);
      expect(x.pos.dy, lessThan(0));
    }
  });
}
