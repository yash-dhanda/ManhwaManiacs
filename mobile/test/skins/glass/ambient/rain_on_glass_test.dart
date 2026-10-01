import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/glass/ambient/rain_on_glass.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart';

void main() {
  const frame = Duration(microseconds: 16667);

  test('never more than 10 droplets alive, and the first run is immediate', () {
    final s = RainSim();
    var most = 0;
    for (var t = 0; t < 60 * 30; t++) {
      s.advance(frame);
      most = math.max(most, s.drops.length);
    }
    expect(most, lessThanOrEqualTo(10));
    expect(most, greaterThanOrEqualTo(6));
  });

  test('a droplet spawns every 600 ms within a frame', () {
    final s = RainSim();
    final at = <int>[];
    var now = 0;
    for (var i = 0; i < 60 * 8; i++) {
      now += 16667;
      if (s.advance(frame).isNotEmpty) at.add(now);
    }
    expect(at.length, inInclusiveRange(12, 14));
    for (var i = 1; i < at.length; i++) {
      expect((at[i] - at[i - 1]) / 1000, closeTo(600, 17));
    }
  });

  test('each run lasts 4 s, radii stay inside 3-6 px and the lateral offset stays inside 15 % of the height travelled', () {
    final s = RainSim(seed: 9);
    final seen = <Droplet>{};
    final gone = <Droplet, int>{};
    var now = 0;
    for (var i = 0; i < 60 * 20; i++) {
      now += 16667;
      s.advance(frame);
      for (final d in s.drops) {
        seen.add(d);
        expect(d.radius, inInclusiveRange(3, 6));
        expect((d.x - d.x0).abs(), lessThanOrEqualTo(0.15 * (d.y - d.y0).abs() + 1e-9));
      }
      for (final d in seen) {
        if (!s.drops.contains(d)) gone.putIfAbsent(d, () => now);
      }
    }
    expect(gone, isNotEmpty);
    for (final d in gone.keys) {
      expect(d.age, inInclusiveRange(4.0, 4.0 + 0.02));
    }
  });

  testWidgets('the host registers one extra layer while it runs and none otherwise', (tester) async {
    late WidgetRef ref;
    Widget build(bool active) => ProviderScope(
          child: Consumer(builder: (context, r, _) {
            ref = r;
            return Directionality(
              textDirection: TextDirection.ltr,
              child: RainOnGlassHost(active: active, light: 2.3, child: const RainOnGlass(radius: BorderRadius.all(Radius.circular(28)), child: SizedBox(width: 100, height: 56))),
            );
          },),
        );
    await tester.pumpWidget(build(false));
    expect(ref.read(glassRegistryProvider).layers, 0);
    await tester.pumpWidget(build(true));
    await tester.pump(const Duration(milliseconds: 50));
    expect(ref.read(glassRegistryProvider).layers, 1);
    await tester.pumpWidget(build(false));
    await tester.pump();
    expect(ref.read(glassRegistryProvider).layers, 0);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
