import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter/widgets.dart' show Matrix4;
import 'package:manhwamaniacs/features/reader/engine/camera.dart';

void main() {
  const vp = Size(390, 844);

  test('fitRect centres a panel within 24 px margins and caps at 3x', () {
    final m = fitRect(const Rect.fromLTWH(0, 0, 342, 400), vp);
    expect(m.getMaxScaleOnAxis(), closeTo(1.0, 1e-9));
    final tiny = fitRect(const Rect.fromLTWH(100, 100, 20, 20), vp);
    expect(tiny.getMaxScaleOnAxis(), 3);
    // Centre of the rect lands on the viewport centre.
    final c = MatrixUtilsLite.apply(tiny, const Offset(110, 110));
    expect(c.dx, closeTo(195, 1e-6));
    expect(c.dy, closeTo(422, 1e-6));
  });

  test('tallPanelSteps walks 75 % of the viewport per step', () {
    final steps = tallPanelSteps(const Rect.fromLTWH(0, 0, 390, 2000), vp);
    expect(steps.first.top, 0);
    expect(steps[1].top, closeTo(844 * 0.75, 1e-9));
    expect(steps.last.bottom, 2000);
    for (final s in steps) {
      expect(s.height, lessThanOrEqualTo(844));
    }
    expect(tallPanelSteps(const Rect.fromLTWH(0, 0, 390, 500), vp), hasLength(1));
  });
}

class MatrixUtilsLite {
  static Offset apply(Matrix4 m, Offset p) {
    final s = m.storage;
    return Offset(s[0] * p.dx + s[4] * p.dy + s[12], s[1] * p.dx + s[5] * p.dy + s[13]);
  }
}
