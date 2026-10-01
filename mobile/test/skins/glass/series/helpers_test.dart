import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/glass/screens/series/chapter_extents.dart';
import 'package:manhwamaniacs/skins/glass/screens/series/collapse.dart';
import 'package:manhwamaniacs/skins/glass/screens/series/detent_from_throw.dart';

void main() {
  group('openingDetent (844 px viewport)', () {
    const vh = 844.0;
    const mediumTop = vh - 0.52 * vh;
    const largeTop = 47.0 + 10;
    SeriesDetent at(double vy) => openingDetent(vy: vy, mediumTop: mediumTop, largeTop: largeTop, viewportHeight: vh);

    test('no velocity opens at medium', () => expect(at(0), SeriesDetent.medium));
    test('-1200 px/s opens at medium', () => expect(at(-1200), SeriesDetent.medium));
    test('-2400 px/s opens at large', () => expect(at(-2400), SeriesDetent.large));
  });

  group('collapse', () {
    test('progress at both ends and the middle', () {
      expect(collapseProgress(400, 400, 60), 0);
      expect(collapseProgress(60, 400, 60), 1);
      expect(collapseProgress(230, 400, 60), closeTo(0.5, 1e-9));
      expect(collapseProgress(500, 400, 60), 0);
      expect(collapseProgress(0, 400, 60), 1);
    });
    test('cover to capsule', () {
      const slot = Rect.fromLTWH(16, 200, 112, 168);
      const thumb = Rect.fromLTWH(60, 20, 24, 36);
      final a = coverToCapsule(0, slot, thumb), b = coverToCapsule(1, slot, thumb), m = coverToCapsule(0.5, slot, thumb);
      expect(a.scale, 1);
      expect(a.offset, Offset.zero);
      expect(b.scale, closeTo(24 / 112, 1e-9));
      expect(b.offset, const Offset(44, -180));
      expect(m.scale, closeTo((1 + 24 / 112) / 2, 1e-9));
      expect(m.offset, const Offset(22, -90));
    });
  });

  group('chapterRowExtent', () {
    test('1.0', () {
      expect(chapterRowExtent(hasSecondary: false), 56);
      expect(chapterRowExtent(hasSecondary: true), 68);
    });
    test('1.3', () {
      expect(chapterRowExtent(hasSecondary: false, textScale: 1.3), closeTo(72.8, 1e-9));
      expect(chapterRowExtent(hasSecondary: true, textScale: 1.3), closeTo(88.4, 1e-9));
    });
  });
}
