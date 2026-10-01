import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/glass/physics/glass_page_physics.dart';
import 'package:manhwamaniacs/skins/glass/screens/reader/reader_gestures.dart';

void main() {
  const s = Size(390, 844);

  test('double tap: 280 ms and 24 px limits', () {
    expect(isDoubleTap(gap: const Duration(milliseconds: 280), distance: 24), isTrue);
    expect(isDoubleTap(gap: const Duration(milliseconds: 281), distance: 0), isFalse);
    expect(isDoubleTap(gap: const Duration(milliseconds: 100), distance: 24.5), isFalse);
  });

  test('the 30 / 40 / 30 bands, mirrored for right-to-left until the reader sets their own', () {
    expect(tapBandOf(116, 390), TapBand.left);
    expect(tapBandOf(118, 390), TapBand.centre);
    expect(tapBandOf(272, 390), TapBand.centre);
    expect(tapBandOf(274, 390), TapBand.right);
    expect(pagedTapAction(TapBand.left, rtl: false), TapZoneAction.previous);
    expect(pagedTapAction(TapBand.left, rtl: true), TapZoneAction.next);
    expect(pagedTapAction(TapBand.centre, rtl: true), TapZoneAction.menu);
    expect(
      pagedTapAction(TapBand.left, rtl: true, zones: const [TapZoneAction.menu, TapZoneAction.next, TapZoneAction.previous]),
      TapZoneAction.menu,
    );
  });

  test('tap to scroll: top third and left-middle back, bottom third and right-middle forward, centre toggles', () {
    expect(stripScrollTapAction(const Offset(195, 100), s), TapZoneAction.previous);
    expect(stripScrollTapAction(const Offset(195, 800), s), TapZoneAction.next);
    expect(stripScrollTapAction(const Offset(40, 420), s), TapZoneAction.previous);
    expect(stripScrollTapAction(const Offset(350, 420), s), TapZoneAction.next);
    expect(stripScrollTapAction(const Offset(195, 420), s), TapZoneAction.menu);
  });

  test('locked: five centre taps within 2 s unlock', () {
    expect(inUnlockRegion(const Offset(195, 420), s), isTrue);
    expect(inUnlockRegion(const Offset(20, 420), s), isFalse);
    final c = UnlockCounter();
    final t0 = DateTime(2026);
    for (var i = 0; i < 4; i++) {
      expect(c.tap(t0.add(Duration(milliseconds: i * 300))), i + 1);
    }
    expect(c.tap(t0.add(const Duration(milliseconds: 1500))), 5);
    final d = UnlockCounter();
    d.tap(t0);
    expect(d.tap(t0.add(const Duration(milliseconds: 2500))), 1, reason: 'older taps fall out of the 2 s window');
  });

  test('paged physics: the projection past half a page commits, one page at most', () {
    expect(GlassPagePhysics.targetPage(390 * 2 + 100, 0, 390), 2, reason: 'a short drag springs back');
    expect(GlassPagePhysics.targetPage(390 * 2 + 220, 0, 390), 3, reason: 'past half a page commits');
    expect(GlassPagePhysics.targetPage(390 * 2 + 60, 1200, 390), 3, reason: 'a flick projects past half');
    expect(GlassPagePhysics.targetPage(390 * 2 + 60, 30000, 390), 3, reason: 'never more than one page');
    expect(GlassPagePhysics.targetPage(390 * 2 + 60, -30000, 390), 2);
  });
}
