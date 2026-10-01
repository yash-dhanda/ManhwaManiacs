import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/reader/engine/page_sample.dart';
import 'package:manhwamaniacs/skins/glass/screens/reader/band_lb.dart';

void main() {
  const vp = Size(390, 844);
  const s = PageSample(
    tint: Color(0xFF808080),
    top: Color(0xFFFFFFFF),
    bottom: Color(0xFF000000),
    lTop: 0.9,
    lMid: 0.5,
    lBottom: 0.1,
    pTop: 0.95,
    pMid: 0.4,
    pBottom: 0.05,
    source: PageSampleSource.decode,
  );

  test('no sample: Lb 1.0, dim 0.64', () {
    expect(bandLb(const Rect.fromLTWH(0, 0, 100, 44), vp, null), 1.0);
    expect(dimLegibility(1.0), closeTo(0.64, 1e-9));
  });

  test('a surface reads the bands it overlaps', () {
    expect(bandLb(const Rect.fromLTWH(16, 55, 200, 44), vp, s), 0.95, reason: 'top quarter');
    expect(bandLb(const Rect.fromLTWH(16, 760, 200, 56), vp, s), 0.05, reason: 'bottom quarter');
    expect(bandLb(const Rect.fromLTWH(16, 400, 200, 40), vp, s), 0.4, reason: 'middle half');
    expect(bandLb(const Rect.fromLTWH(16, 600, 200, 100), vp, s), 0.4, reason: 'middle and bottom: the maximum');
    expect(bandLb(const Rect.fromLTWH(0, 0, 390, 844), vp, s), 0.95);
  });

  test('dim formula clamps at both ends', () {
    expect(dimLegibility(0), 0.22);
    expect(dimLegibility(0.5), closeTo(0.43, 1e-9));
    expect(dimLegibility(2), 0.64);
  });
}
