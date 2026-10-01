import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/novels/models/glass_novel_prefs.dart';
import 'package:manhwamaniacs/skins/glass/screens/novel/page_turn.dart';

void main() {
  const size = Size(400, 800);
  PageTapAction at(GlassTapZones z, double x, double y) => tapBand(z, Offset(x, y), size);

  test('standard: 25 / 50 / 25 at the band edges, never mirrored', () {
    expect(at(GlassTapZones.standard, 0, 400), PageTapAction.back);
    expect(at(GlassTapZones.standard, 99.9, 400), PageTapAction.back);
    expect(at(GlassTapZones.standard, 100, 400), PageTapAction.menu);
    expect(at(GlassTapZones.standard, 299.9, 400), PageTapAction.menu);
    expect(at(GlassTapZones.standard, 300, 400), PageTapAction.forward);
    expect(at(GlassTapZones.standard, 400, 400), PageTapAction.forward);
  });

  test('both margins go forward', () {
    expect(at(GlassTapZones.bothMargins, 0, 400), PageTapAction.forward);
    expect(at(GlassTapZones.bothMargins, 99.9, 400), PageTapAction.forward);
    expect(at(GlassTapZones.bothMargins, 100, 400), PageTapAction.menu);
    expect(at(GlassTapZones.bothMargins, 299.9, 400), PageTapAction.menu);
    expect(at(GlassTapZones.bothMargins, 300, 400), PageTapAction.forward);
  });

  test('one hand: left 20 % back, top 12 % menu across the width, the rest forward', () {
    expect(at(GlassTapZones.oneHand, 10, 95.9), PageTapAction.menu);
    expect(at(GlassTapZones.oneHand, 390, 95.9), PageTapAction.menu);
    expect(at(GlassTapZones.oneHand, 79.9, 96), PageTapAction.back);
    expect(at(GlassTapZones.oneHand, 80, 96), PageTapAction.forward);
    expect(at(GlassTapZones.oneHand, 200, 700), PageTapAction.forward);
  });

  test('slide: the projection past 50 % turns, one page at most', () {
    expect(slideTarget(pixels: 400 + 150, velocity: 0, pageWidth: 400, from: 1), 1);
    expect(slideTarget(pixels: 400 + 201, velocity: 0, pageWidth: 400, from: 1), 2);
    // A flick: 120 px dragged at 400 px/s projects 120 + 199.6 = 319.6 > 200.
    expect(slideTarget(pixels: 400 + 120, velocity: 400, pageWidth: 400, from: 1), 2);
    expect(slideTarget(pixels: 400 - 120, velocity: -400, pageWidth: 400, from: 1), 0);
    expect(slideTarget(pixels: 400 + 120, velocity: 100000, pageWidth: 400, from: 1), 2);
  });

  test('lift commits past half the width, release velocity included', () {
    expect(liftCommits(150, 0, 400), isFalse);
    expect(liftCommits(201, 0, 400), isTrue);
    expect(liftCommits(100, 300, 400), isTrue);
    expect(liftCommits(-201, 0, 400), isTrue);
  });
}
