import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/reader/engine/paged_zoom.dart';

void main() {
  const size = Size(400, 800);
  test('the point under the focal stays put', () {
    const focal = Offset(300, 200);
    final pan = panForFocal(focal: focal, size: size, oldPan: Offset.zero, oldScale: 1, newScale: 2);
    // content point under focal before: (300,200); after: centre + pan + 2*(p - centre)
    const centre = Offset(200, 400);
    final after = centre + pan + (focal - centre) * 2;
    expect(after.dx, closeTo(300, 1e-9));
    expect(after.dy, closeTo(200, 1e-9));
  });
  test('scale 1 has no pan; pan is clamped to the overflow', () {
    expect(panForFocal(focal: const Offset(10, 10), size: size, oldPan: const Offset(50, 50), oldScale: 2, newScale: 1), Offset.zero);
    expect(clampPan(const Offset(999, -999), size, 2), const Offset(200, -400));
  });
  test('double tap toggles 1x and 2x', () {
    expect(pagedDoubleTapTarget(1), 2);
    expect(pagedDoubleTapTarget(2), 1);
    expect(pagedDoubleTapTarget(1.005), 2);
  });
}
