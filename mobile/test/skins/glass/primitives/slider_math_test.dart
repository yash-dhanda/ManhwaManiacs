import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/glass/primitives/slider_math.dart';

void main() {
  group('step magnet', () {
    test('within 30 % of the spacing the thumb is pulled to the step', () {
      final m = stepMagnet(104, 100, 10);
      expect(m.pos, 100);
      expect(m.magnet, isTrue);
      expect(stepMagnet(129, 100, 10).pos, 100);
    });
    test('between steps it follows the finger', () {
      final m = stepMagnet(150, 100, 10);
      expect(m.pos, 150);
      expect(m.magnet, isFalse);
      expect(stepMagnet(131, 100, 10).magnet, isFalse);
    });
    test('nearest step clamps to the ends', () {
      expect(nearestStep(-40, 100, 10), 0);
      expect(nearestStep(1400, 100, 10), 10);
      expect(nearestStep(260, 100, 10), 3);
    });
  });

  test('the rubber band never passes 12 px, on either side', () {
    expect(sliderRubber(5000, 300), 12);
    expect(sliderRubber(-5000, 300), -12);
    expect(sliderRubber(10, 300).abs(), lessThan(10));
    expect(sliderRubber(0, 300), 0);
  });

  group('speed dial', () {
    test('6 px per 0.05 step, up raises', () {
      expect(dialRaw(1.0, -6), closeTo(1.05, 1e-9));
      expect(dialRaw(1.0, 60), closeTo(0.5, 1e-9));
      expect(dialValue(1.30).value, 1.3);
    });
    test('quantised to 0.05 and clamped to 0.5 to 3.0', () {
      expect(dialValue(1.27).value, 1.25);
      expect(dialValue(9).value, 3.0);
      expect(dialValue(0).value, 0.5);
    });
    test('the magnet at 1.0 holds within 0.08', () {
      expect(dialValue(1.07).value, 1.0);
      expect(dialValue(1.07).magnet, isTrue);
      expect(dialValue(0.93).value, 1.0);
      expect(dialValue(1.10).value, 1.1);
      expect(dialValue(1.10).magnet, isFalse);
    });
    test('ticks every 0.25x and never on the 0.05 steps', () {
      expect(dialTick(1.20, 1.25), isTrue);
      expect(dialTick(1.05, 1.10), isFalse);
      expect(dialTick(1.30, 1.20), isTrue);
    });
    test('past the ends it rubber-bands 12 px at most', () {
      expect(dialOvershootPx(3.0), 0);
      expect(dialOvershootPx(9), 12);
      expect(dialOvershootPx(-4), -12);
    });
  });

  group('scrub rail', () {
    test('the page for a thumb position', () {
      expect(scrubPage(0, 40), 0);
      expect(scrubPage(1, 40), 39);
      expect(scrubPage(17 / 39, 40), 17);
      expect(scrubPage(0.5, 1), 0);
    });
    test('the thumb snaps page by page and a fling projects to the nearest page', () {
      expect(scrubFraction(20, 41), 0.5);
      expect(scrubProjectedPage(0.5, 0, 41), 20);
      expect(scrubProjectedPage(0.5, 0.2, 41), greaterThan(20));
    });
  });

  test('value magnet holds within 30 % of one step and releases beyond', () {
    // 5..120 in steps of 5 over 230 px: spacing 10 px, the 30 min magnet at 50 px.
    expect(valueMagnet(50, 50, 10), (pos: 50.0, held: true));
    expect(valueMagnet(52.9, 50, 10), (pos: 50.0, held: true));
    expect(valueMagnet(53.1, 50, 10).held, isFalse);
    expect(valueMagnet(46.9, 50, 10).pos, 46.9);
  });
}
