import 'dart:ui';

import 'package:flutter/painting.dart' show EdgeInsets;

import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/screens/wrapped/page_pile.dart';
import 'package:manhwamaniacs/skins/glass/screens/wrapped/podium.dart';
import 'package:manhwamaniacs/skins/glass/screens/wrapped/wrapped_frame.dart';

void main() {
  group('frame', () {
    test('phone 390 x 844', () {
      // width: (390-32)/360 = 0.994; height: (844-32-47-34)/640 = 1.142 -> width wins.
      final s = frameScale(const Size(390, 844), const EdgeInsets.only(top: 47, bottom: 34), GlassFrameKind.phone);
      expect(s, closeTo(358 / 360, 1e-9));
      expect(frameSize(s).width, closeTo(358, 1e-9));
    });

    test('tablet 820 x 1180 and desktop 1180 x 820', () {
      expect(frameScale(const Size(820, 1180), EdgeInsets.zero, GlassFrameKind.tablet), 1.2);
      expect(frameScale(const Size(1180, 820), EdgeInsets.zero, GlassFrameKind.desktop), closeTo((820 - 64) / 640, 1e-9));
    });

    test('slots and scaling', () {
      expect(WrappedSlots.figure.size, const Size(312, 304));
      expect(WrappedSlots.export, const Rect.fromLTRB(232, 576, 336, 620));
      final r = scaledSlot(WrappedSlots.headline, 2, const Offset(10, 20));
      expect(r.left, 10 + 48);
      expect(r.top, 20 + 192);
      expect(largeText(1.29), isFalse);
      expect(largeText(1.3), isTrue);
    });
  });

  group('page pile', () {
    test('count is clamped to 20..200', () {
      expect(pileCount(0), 20);
      expect(pileCount(4000), 20);
      expect(pileCount(38410), 192);
      expect(pileCount(96000), 200);
    });

    test('falls, rests and sleeps', () {
      final p = PagePile(pages: 38410, size: const Size(312, 200));
      expect(p.bodies.length, 192);
      expect(p.asleep, isFalse);
      var steps = 0;
      while (!p.asleep && steps < 2000) {
        p.step(1 / 60);
        steps++;
      }
      expect(p.asleep, isTrue);
      for (final b in p.bodies) {
        expect(b.y + kPageH, lessThanOrEqualTo(200.0001));
        expect(b.y, greaterThanOrEqualTo(0 - 1e-6));
      }
    });

    test('settle() matches the stacked heights', () {
      final p = PagePile(pages: 4000, size: const Size(312, 200))..settle();
      expect(p.asleep, isTrue);
      final perColumn = <int, int>{};
      for (final b in p.bodies) {
        perColumn[b.column] = (perColumn[b.column] ?? 0) + 1;
      }
      for (final c in perColumn.entries) {
        final tops = p.bodies.where((b) => b.column == c.key).map((b) => b.y).toList()..sort();
        expect(tops.first, closeTo(200 - c.value * kPageH, 1e-6));
      }
    });
  });

  group('podium', () {
    test('drop order is 5, 4, 3, 2, 1, 120 ms apart', () {
      expect([for (var r = 5; r >= 1; r--) dropStartMs(r)], [0, 120, 240, 360, 480]);
      expect(landMs(1) - landMs(2), closeTo(120, 1e-6));
    });

    test('the cover starts 200 px above and ends at rest', () {
      expect(dropOffset(5, 0), -200);
      expect(dropOffset(1, 100), -200);
      expect(dropOffset(5, 1000), 0);
      expect(dropOffset(1, 3000), 0);
      // it is in the air mid-fall and never below its rest before landing
      expect(dropOffset(5, 200), lessThan(0));
      for (var t = 0.0; t < 2000; t += 10) {
        expect(dropOffset(3, t), lessThanOrEqualTo(0));
      }
    });

    test('rest positions', () {
      expect(podiumRest(1).width, 104);
      expect(podiumRest(2).height, 132);
      expect(podiumStep(1)!.height, 16);
      expect(podiumStep(2)!.height, 8);
      expect(podiumStep(4), isNull);
      expect(dropEndMs(), greaterThan(800));
    });
  });
}
