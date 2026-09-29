import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/glass/physics/glass_physics.dart';
import 'package:manhwamaniacs/skins/glass/routes/glass_sheet_route.dart';

const _vh = 844.0;
const _medium = 0.52 * _vh;
const _large = _vh - 47 - 10;

int _snap(double offset, double v, {List<double> detents = const [_medium, _large]}) =>
    snapDetentIndex(offset: offset, velocity: v, detentsPx: detents, viewport: _vh);

void main() {
  group('projected nearest detent', () {
    test('a slow release settles on the nearest detent', () {
      expect(_snap(_medium + 40, 0), 0);
      expect(_snap(_large - 40, 0), 1);
    });
    test('a fling up from medium lands on large, a fling down from large on medium', () {
      expect(_snap(_medium, 1200), 1);
      expect(_snap(_large, -700), 0);
    });
    test('with a peek detent the middle one is reachable', () {
      const d = [96.0, _medium, _large];
      expect(_snap(300, 0, detents: d), 1);
      expect(_snap(100, 0, detents: d), 0);
    });
    test('the projection is capped at one viewport', () {
      expect(projectCapped(100, 1e6, _vh), 100 + _vh);
    });
  });

  group('dismissal', () {
    test('a projection more than 50 % of the lowest detent below it dismisses', () {
      // Lowest detent 439: 50 % below is 219.4.
      expect(_snap(230, 0), isNot(-1));
      expect(_snap(210, 0), -1);
    });
    test('a fling of 1,500 px/s or more at the lowest detent dismisses', () {
      expect(_snap(_medium, -1500), -1);
      expect(_snap(_medium, -1600), -1);
    });
    test('a gentle drag down from the lowest detent does not', () {
      expect(_snap(_medium - 40, -100), 0);
    });
    test('a sheet with only large dismisses on the same rule', () {
      expect(_snap(_large, -1600, detents: const [_large]), -1);
      expect(_snap(_large - 20, 0, detents: const [_large]), 0);
    });
  });

  group('rubber band above the top detent', () {
    test('never more than 60 px however far the finger goes', () {
      expect(sheetRubber(5000, _vh), 60);
      expect(sheetRubber(30, _vh), lessThan(30));
      expect(sheetRubber(0, _vh), 0);
      for (final x in [10.0, 50.0, 200.0, 800.0]) {
        expect(sheetRubber(x, _vh), lessThanOrEqualTo(60));
        expect(sheetRubber(x, _vh), closeTo(rubberband(x, _vh).clamp(0, 60), 1e-9));
      }
    });
  });

  test('detent px', () {
    expect(sheetDetentPx(GlassDetent.peek, viewport: _vh, large: _large), 96);
    expect(sheetDetentPx(GlassDetent.medium, viewport: _vh, large: _large), _medium);
    expect(sheetDetentPx(GlassDetent.large, viewport: _vh, large: _large), _large);
    expect(sheetLargePx(844, 47), 787);
  });
}
