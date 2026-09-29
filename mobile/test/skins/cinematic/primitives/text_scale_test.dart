import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/cinematic/gallery/primitives_gallery.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/primitives.dart';

import 'gallery_host.dart';

void main() {
  for (final scale in [1.0, 1.3, 2.0]) {
    testWidgets('the gallery renders at text scale $scale without overflow', (t) async {
      await pumpGallery(t, scale: scale);
      expect(t.takeException(), isNull);
      // Sections below the fold build too: it is one column, not a lazy list.
      for (final s in kGallerySections) {
        expect(find.byKey(Key('gallery-$s')), findsOneWidget, reason: s);
      }
      await t.pump(const Duration(seconds: 3));
      expect(t.takeException(), isNull);
    });
  }

  testWidgets('a rail shows 2.3 posters on a 390 px phone at 1.3', (t) async {
    await pumpGallery(t, scale: 1.3, section: 'rails');
    final rail = find.byKey(const Key('g-rail-ready'));
    final width = t.getSize(rail).width;
    final posterW = railPosterWidth(contentWidth: width, visible: railVisible(width: 390, textScale: 1.3), gap: railGap(390));
    expect(railVisible(width: 390, textScale: 1.3), 2.3);
    final first = t.getSize(find.byType(CinePoster).first).width;
    expect(first, closeTo(posterW, 0.5));
    expect(t.takeException(), isNull);
  });
}
