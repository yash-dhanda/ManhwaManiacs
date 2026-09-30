import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/cine_page_physics.dart';

void main() {
  test('target: 71 px returns, 72 px commits (forward and back)', () {
    expect(cinePageTarget(pixels: 390 + 71, viewport: 390, velocity: 10), 1);
    expect(cinePageTarget(pixels: 390 + 72, viewport: 390, velocity: 10), 2);
    expect(cinePageTarget(pixels: 390 - 71, viewport: 390, velocity: -10), 1);
    expect(cinePageTarget(pixels: 390 - 72, viewport: 390, velocity: -10), 0);
  });
  test('target: 599 px/s returns, 600 commits', () {
    expect(cinePageTarget(pixels: 390 + 10, viewport: 390, velocity: 599), 1);
    expect(cinePageTarget(pixels: 390 + 10, viewport: 390, velocity: 600), 2);
    expect(cinePageTarget(pixels: 390 - 10, viewport: 390, velocity: -600), 0);
  });
  test('physics settles on the 504 ms spring and never overshoots', () {
    final m = FixedScrollMetrics(
      minScrollExtent: 0, maxScrollExtent: 3900, pixels: 390 + 80, viewportDimension: 390,
      axisDirection: AxisDirection.right, devicePixelRatio: 1,
    );
    final sim = const CinePagePhysics().createBallisticSimulation(m, 0)!;
    expect(sim.x(0), closeTo(470, 1e-6));
    expect(sim.x(3), closeTo(780, 0.5));
    expect(sim.isDone(3), isTrue);
    var prev = 0.0;
    for (var t = 0.0; t < 2; t += 0.02) {
      expect(sim.x(t), greaterThanOrEqualTo(prev - 1e-6));
      expect(sim.x(t), lessThanOrEqualTo(780.001));
      prev = sim.x(t);
    }
  });
}
