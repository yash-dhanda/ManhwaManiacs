import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/glass/physics/glass_physics.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/spotlight_physics.dart';
import 'package:manhwamaniacs/skins/glass/tokens.g.dart';

FixedScrollMetrics metrics(double px, {double w = 390, int pages = 6}) => FixedScrollMetrics(
      minScrollExtent: 0,
      maxScrollExtent: w * (pages - 1),
      pixels: px,
      viewportDimension: w,
      axisDirection: AxisDirection.right,
      devicePixelRatio: 3,
    );

void main() {
  test('one page per flick even at 4,000 px/s', () {
    expect(spotlightTargetPage(0, -4000, 390, 6), 0);
    expect(spotlightTargetPage(0, 4000, 390, 6), 1);
    expect(spotlightTargetPage(390, 9000, 390, 6), 2);
    expect(spotlightTargetPage(390, -9000, 390, 6), 0);
    expect(spotlightTargetPage(2 * 390 + 100, 9000, 390, 6), 3);
  });

  test('a slow release lands on the nearest page and pages stay in range', () {
    expect(spotlightTargetPage(100, 0, 390, 6), 0);
    expect(spotlightTargetPage(250, 0, 390, 6), 1);
    expect(spotlightTargetPage(5 * 390, 9000, 390, 6), 5);
  });

  test('the rubber band never passes 25 percent of the width', () {
    expect(spotlightOverscrollCap(400), 100);
    expect(spotlightRubber(10, 400), lessThan(10));
    expect(spotlightRubber(100000, 400), 100);
    expect(spotlightRubber(-100000, 400), -100);
    const p = SpotlightPhysics();
    var px = 0.0;
    for (var i = 0; i < 200; i++) {
      final adjusted = p.applyPhysicsToUserOffset(metrics(px), 20);
      px -= adjusted;
    }
    expect(px, greaterThanOrEqualTo(-390 * 0.25 - 1e-6));
    expect(px, lessThan(0));
  });

  test('ballistics settle on springSettle constants', () {
    final d = springOf(GlassSprings.settle);
    expect(d.stiffness, closeTo(322.3, 0.5));
    expect(d.damping, closeTo(35.9, 0.05));
    final sim = const SpotlightPhysics().createBallisticSimulation(metrics(120), -3000)! as ScrollSpringSimulation;
    expect(sim.x(5), closeTo(0, 0.5));
    final fwd = const SpotlightPhysics().createBallisticSimulation(metrics(120), 3000)! as ScrollSpringSimulation;
    expect(fwd.x(5), closeTo(390, 0.5));
  });
}
