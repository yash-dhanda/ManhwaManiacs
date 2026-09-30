import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/ruler_math.dart';

void main() {
  test('value to x and back', () {
    expect(rulerX(1, 40, 390), 0);
    expect(rulerX(40, 40, 390), 390);
    expect(rulerX(21, 41, 400), 200);
    for (final p in [1, 7, 18, 33, 40]) {
      expect(rulerPage(rulerX(p, 40, 390), 40, 390), p);
    }
    expect(rulerPage(-30, 40, 390), 1);
    expect(rulerPage(900, 40, 390), 40);
  });

  test('RTL mirrors', () {
    expect(rulerX(1, 40, 390, rtl: true), 390);
    expect(rulerX(40, 40, 390, rtl: true), 0);
    expect(rulerPage(0, 40, 390, rtl: true), 40);
    expect(rulerPage(rulerX(12, 40, 390, rtl: true), 40, 390, rtl: true), 12);
  });

  test('ticks drop above 120 pages and never draw for a single page', () {
    expect(rulerTickXs(120, 600), hasLength(120));
    expect(rulerTickXs(121, 600), isEmpty);
    expect(rulerTickXs(1, 600), isEmpty);
    expect(rulerShowsTicks(2), isTrue);
  });

  test('bookmark marks sit at their pages', () {
    expect(rulerBookmarkXs([1, 21, 41], 41, 400), [0, 200, 400]);
    expect(rulerBookmarkXs([99], 41, 400), [400]);
  });

  test('a one-page chapter has a degenerate track', () {
    expect(rulerX(1, 1, 300), 0);
    expect(rulerPage(150, 1, 300), 1);
  });
}
