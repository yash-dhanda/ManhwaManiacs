import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/cinematic/focus_ring.dart';

import 'gallery_host.dart';

/// Every gallery widget keyed `g-...` and every hit-sized `CinePressable` is at least 44 x 44 on
/// iOS and 48 x 48 on Android, and adjacent targets keep 8 px between them.
void main() {
  for (final (platform, min) in [(TargetPlatform.iOS, 44.0), (TargetPlatform.android, 48.0)]) {
    testWidgets('hit targets under $platform are at least $min', (t) async {
      await pumpGallery(t, platform: platform);
      expect(t.takeException(), isNull);

      final keyed = <String, Rect>{};
      for (final e in t.elementList(find.byWidgetPredicate((w) => w.key is ValueKey<String> && (w.key! as ValueKey<String>).value.startsWith('g-')))) {
        final key = (e.widget.key! as ValueKey<String>).value;
        final box = e.renderObject;
        if (box is! RenderBox || !box.hasSize || box.size.isEmpty) continue;
        keyed[key] = box.localToGlobal(Offset.zero) & box.size;
      }
      expect(keyed.length, greaterThan(60), reason: 'the gallery keys its interactive elements');
      keyed.forEach((k, r) {
        if (k.startsWith('g-static-')) return; // display-only rows keep their 40 px minimum (cinematic 7.16)
        expect(r.width, greaterThanOrEqualTo(min - 0.01), reason: '$k width');
        expect(r.height, greaterThanOrEqualTo(min - 0.01), reason: '$k height');
      });

      // Every CinePressable that grows its hit (hit: true) reaches the minimum.
      for (final e in t.elementList(find.byType(CinePressable))) {
        final w = e.widget as CinePressable;
        if (!w.hit) continue;
        final box = e.renderObject! as RenderBox;
        if (!box.hasSize) continue;
        expect(box.size.width, greaterThanOrEqualTo(min - 0.01), reason: 'CinePressable at ${box.localToGlobal(Offset.zero)}');
        expect(box.size.height, greaterThanOrEqualTo(min - 0.01), reason: 'CinePressable at ${box.localToGlobal(Offset.zero)}');
      }

      // Adjacent targets keep 8 px: no two keyed rects that do not contain one another come closer.
      // List rows tile edge to edge on their dividers; that is the row pattern, not two targets.
      final entries = [for (final e in keyed.entries) if (!e.key.startsWith('g-row-') && !e.key.startsWith('g-reorder-row-') && !e.key.startsWith('g-selectbar')) e];
      for (var i = 0; i < entries.length; i++) {
        for (var j = i + 1; j < entries.length; j++) {
          final a = entries[i].value, b = entries[j].value;
          if (a.contains(b.topLeft) && a.contains(b.bottomRight)) continue;
          if (b.contains(a.topLeft) && b.contains(a.bottomRight)) continue;
          expect(a.inflate(7.99).overlaps(b), isFalse, reason: '${entries[i].key} and ${entries[j].key} are closer than 8 px');
        }
      }
    });
  }
}
