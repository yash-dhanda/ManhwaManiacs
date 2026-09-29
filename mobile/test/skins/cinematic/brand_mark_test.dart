import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/cinematic/brand_mark.g.dart';

void main() {
  const canvas = Rect.fromLTWH(0, 0, 1024, 1024);

  test('both M paths are non-empty and inside the 232..792 box', () {
    for (final p in [CineMarkPaths.upright(), CineMarkPaths.italic()]) {
      final b = p.getBounds();
      expect(b.isEmpty, isFalse);
      expect(b.left, greaterThanOrEqualTo(231));
      expect(b.right, lessThanOrEqualTo(793));
      expect(canvas.contains(b.topLeft) && canvas.contains(b.bottomRight), isTrue);
    }
  });

  test('intersection is non-empty and inside both', () {
    final i = CineMarkPaths.intersection().getBounds();
    expect(i.isEmpty, isFalse);
    for (final p in [CineMarkPaths.upright(), CineMarkPaths.italic()]) {
      final b = p.getBounds();
      expect(i.left, greaterThanOrEqualTo(b.left - 1));
      expect(i.right, lessThanOrEqualTo(b.right + 1));
      expect(i.top, greaterThanOrEqualTo(b.top - 1));
      expect(i.bottom, lessThanOrEqualTo(b.bottom + 1));
    }
  });
}
