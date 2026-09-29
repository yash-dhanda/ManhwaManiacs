import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/glass/physics/glass_physics.dart';
import 'package:manhwamaniacs/skins/glass/tokens.g.dart';

void main() {
  test('the sheet curve is 0 at 0 and exactly 1 at 1', () {
    final c = SpringCurve(GlassSprings.sheet);
    expect(c.transform(0), 0);
    expect(c.transform(1), 1);
  });

  test('the sheet curve stays within 0.5 % of 1 from 447 ms', () {
    final c = SpringCurve(GlassSprings.sheet);
    expect(c.transform(1.0), 1);
    // The underlying spring at 447 ms is at rest to within 0.55 %, and stays there.
    expect((c.transform(0.9999) - 1).abs(), lessThan(0.0055));
    for (final t in [0.99, 0.995, 0.999]) {
      expect((c.transform(t) - 1).abs(), lessThan(0.02), reason: '$t');
    }
  });

  test('the sheet spring (bounce 0.08) rises without a visible overshoot inside its 447 ms', () {
    final c = SpringCurve(GlassSprings.sheet);
    var prev = 0.0;
    for (var i = 0; i <= 100; i++) {
      final v = c.transform(i / 100);
      expect(v, greaterThanOrEqualTo(prev - 1e-9));
      expect(v, lessThanOrEqualTo(1.001));
      prev = v;
    }
  });

  test('every overlay spring is settled by its recorded time', () {
    for (final t in [GlassSprings.dismiss, GlassSprings.sheetSnap, GlassSprings.settle, GlassSprings.zoom]) {
      final c = SpringCurve(t);
      expect((c.transform(0.995) - 1).abs(), lessThan(0.01), reason: '${t.ms}');
    }
  });

  test('the settle times of glass 4.10', () {
    expect(kSpringSettleMs, {'sheet': 447, 'dismiss': 378, 'sheetSnap': 342, 'settle': 414, 'zoom': 558});
  });
}
