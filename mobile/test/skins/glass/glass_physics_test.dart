
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/glass/glass/lb.dart';
import 'package:manhwamaniacs/skins/glass/physics/glass_physics.dart';
import 'package:manhwamaniacs/skins/glass/tokens.g.dart';
import 'package:manhwamaniacs/skins/token_types.g.dart';

void main() {
  test('projection and rubber band', () {
    expect(project(0, 1000), closeTo(499, 0.01));
    expect(project(10, -1000), closeTo(-489, 0.01));
    expect(rubberband(100, 800), closeTo(51.5, 0.1));
    expect(rubberband(-100, 800), closeTo(-51.5, 0.1));
    expect(rubberband(100, 800), closeTo(51.5, 0.1));
    expect(projectCapped(0, 100000, 800), 800);
    expect(nearest([0, 100, 300], 180), 100);
  });

  test('springOf matches k and c of the spec', () {
    final page = springOf(const SpringToken(ms: 520, bounce: 0));
    expect(page.stiffness, closeTo(146.0, 0.1));
    expect(page.damping, closeTo(24.17, 0.1));
    final track = springOf(const SpringToken(ms: 150, bounce: 0.14));
    expect(track.stiffness, closeTo(1754.6, 0.5));
    expect(track.damping, closeTo(72.05, 0.1));
  });

  test('generated tokens give the same constants (no Cinematic 1.2 scale)', () {
    expect(springOf(glassTokens.springPage).stiffness, closeTo(146.0, 0.1));
    expect(springOf(glassTokens.springPage).damping, closeTo(24.17, 0.1));
    expect(springOf(glassTokens.springTrack).stiffness, closeTo(1754.6, 0.5));
    expect(springOf(glassTokens.springTrack).damping, closeTo(72.05, 0.1));
  });

  test('rail snap, tiers, dim, grad, depth, impact', () {
    expect(railSnap(310, 900, 136), 816);
    expect(tierFor(44), GlassTierId.t2);
    expect(tierFor(240), GlassTierId.t4);
    expect(tierFor(401), GlassTierId.t4);
    expect(tierFor(20), GlassTierId.t1);
    expect(tierFor(57), GlassTierId.t3);
    expect(glassTokens.glassSnap, [36, 57, 97]);
    expect(dimFor(1.0), closeTo(0.64, 1e-9));
    expect(dimFor(0), closeTo(0.22, 1e-9));
    expect(dimFor(0, highContrast: true), 0.40);
    expect(dimFor(1.0, highContrast: true), closeTo(0.64, 1e-9));
    expect(gradFor(1.0), 40);
    expect(gradFor(0.5, bold: true), 40);
    expect(rondFor(2.5), 50);
    expect(depthIntensity(3), closeTo(0.54, 1e-9));
    expect(impactIntensity(1200), closeTo(0.6, 1e-9));
    expect(impactIntensity(0), 0.3);
    expect(impactIntensity(100000), 1.0);
  });

  test('a dark cover with one white patch still gets the full dim', () {
    final lb = Lb.cover(1.0); // mean 0.2 is ignored: the 95th percentile rules
    expect(dimFor(lb), closeTo(0.64, 1e-9));
  });

  test('Magnet captures at 63 px and not at 65 px', () {
    final captures = <int>[];
    final m = Magnet(onCapture: (t) => captures.add(1));
    const t = MagnetTarget(Offset(100, 100), 'a');
    final moved = m.step(const Offset(37, 100), [t]);
    expect(captures.length, 1);
    expect(moved.dx, closeTo(37 + 63 * 0.35, 1e-9));
    final m2 = Magnet();
    expect(m2.step(const Offset(35, 100), [t]), const Offset(35, 100));
    expect(m2.captured, isNull);
    var released = 0;
    final m3 = Magnet(onRelease: (_) => released++);
    m3.step(const Offset(90, 100), [t]);
    m3.step(const Offset(0, 0), [t]);
    expect(released, 1);
  });

  test('SnapPhysics lands a 900 px/s fling from 310 on 816', () {
    const physics = SnapPhysics(stride: 136);
    final metrics = FixedScrollMetrics(
      minScrollExtent: 0,
      maxScrollExtent: 5000,
      pixels: 310,
      viewportDimension: 700,
      axisDirection: AxisDirection.down,
      devicePixelRatio: 1,
    );
    final sim = physics.createBallisticSimulation(metrics, 900)!;
    expect(sim.x(6), closeTo(816, 1));
    expect(sim.isDone(6), isTrue);
    // out of range defers to the rubber band parent
    final over = FixedScrollMetrics(
      minScrollExtent: 0,
      maxScrollExtent: 5000,
      pixels: -40,
      viewportDimension: 700,
      axisDirection: AxisDirection.down,
      devicePixelRatio: 1,
    );
    expect(physics.createBallisticSimulation(over, 0), isNotNull);
  });
}
