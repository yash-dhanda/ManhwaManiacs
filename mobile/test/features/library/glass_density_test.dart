import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/library/utils/glass_density.dart';

void main() {
  test('phone steps walk list, 2, 3, 4, 5 and stop at both ends', () {
    expect(stepPhone(GlassPhoneDensity.c3, larger: true), GlassPhoneDensity.c2);
    expect(stepPhone(GlassPhoneDensity.c2, larger: true), GlassPhoneDensity.list);
    expect(stepPhone(GlassPhoneDensity.list, larger: true), GlassPhoneDensity.list);
    expect(stepPhone(GlassPhoneDensity.c4, larger: false), GlassPhoneDensity.c5);
    expect(stepPhone(GlassPhoneDensity.c5, larger: false), GlassPhoneDensity.c5);
    expect(stepPhone(GlassPhoneDensity.list, larger: false), GlassPhoneDensity.c2);
  });

  test('wide steps walk list, comfortable, compact and stop at both ends', () {
    expect(stepWide(GlassDensityWide.compact, larger: true), GlassDensityWide.comfortable);
    expect(stepWide(GlassDensityWide.comfortable, larger: true), GlassDensityWide.list);
    expect(stepWide(GlassDensityWide.list, larger: true), GlassDensityWide.list);
    expect(stepWide(GlassDensityWide.comfortable, larger: false), GlassDensityWide.compact);
    expect(stepWide(GlassDensityWide.compact, larger: false), GlassDensityWide.compact);
  });

  test('grid minimums and column counts', () {
    expect(gridMin(GlassDensityWide.comfortable, desktop: false), 148);
    expect(gridMin(GlassDensityWide.comfortable, desktop: true), 152);
    expect(gridMin(GlassDensityWide.compact, desktop: false), 112);
    expect(gridMin(GlassDensityWide.compact, desktop: true), 112);
    expect(gridColumns(820, 148, 20), 5);
    expect(gridColumns(1180, 152, 20), 6);
    expect(gridColumns(50, 148, 20), 1);
  });

  test('pinch thresholds', () {
    expect(pinchSteps(1.24), 0);
    expect(pinchSteps(1.25), 1);
    expect(pinchSteps(0.81), 0);
    expect(pinchSteps(0.8), -1);
    expect(pinchSteps(3), 1);
  });

  test('wheel steps: 119 px none, 120 px one, negative is larger, reset after 400 ms', () {
    expect(wheelSteps(119), 0);
    expect(wheelSteps(120), -1);
    expect(wheelSteps(-120), 1);
    final w = WheelAccumulator();
    expect(w.add(60, Duration.zero), 0);
    expect(w.add(60, const Duration(milliseconds: 100)), -1);
    final r = WheelAccumulator();
    expect(r.add(100, Duration.zero), 0);
    expect(r.add(100, const Duration(milliseconds: 450)), 0, reason: 'the first 100 px expired');
    expect(r.add(-240, const Duration(milliseconds: 500)), 1);
  });

  test('the stored form round-trips', () {
    for (final d in GlassPhoneDensity.values) {
      expect(GlassPhoneDensity.parse(d.wire), d);
    }
    expect(GlassPhoneDensity.parse(null), GlassPhoneDensity.c3);
  });
}
