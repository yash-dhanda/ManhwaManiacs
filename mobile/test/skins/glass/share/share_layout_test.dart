import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/glass/wrapped/share_layout.dart';

void main() {
  test('canvases and logical frames', () {
    expect(shareCanvas(ShareFormat.story), const Size(1080, 1920));
    expect(shareCanvas(ShareFormat.post), const Size(1080, 1350));
    expect(shareLogical(ShareFormat.story), const Size(360, 640));
    expect(shareLogical(ShareFormat.post), const Size(360, 450));
  });

  test('Story boxes follow the spec table', () {
    final b = shareBoxes(ShareFormat.story);
    expect(b.eyebrow, const Rect.fromLTRB(72, 216, 1008, 264));
    expect(b.headline.top, 288);
    expect(b.headline.bottom, 600);
    expect(b.figure, const Rect.fromLTRB(72, 648, 1008, 1560));
    expect(b.footnote.top, 1584);
    expect(b.footnote.bottom, 1656);
    expect([b.wordmarkBaseline, b.monoBaseline, b.nameBaseline], [1760, 1816, 1864]);
    // the stat layout: numeral then context then the 240 x 360 cover, never overlapping.
    expect(b.numeral.bottom, lessThan(b.context.top));
    expect(b.context.bottom, lessThan(b.cover.top));
    expect(b.cover.size, const Size(240, 360));
    expect(b.cover.left, 420);
  });

  test('Post boxes and no cover or bars', () {
    final b = shareBoxes(ShareFormat.post);
    expect(b.eyebrow.top, 144);
    expect(b.headline.bottom, 480);
    expect(b.figure.top, 512);
    expect(b.figure.bottom, 1080);
    expect(b.wordmarkBaseline, 1176);
    expect(b.monoBaseline, 1224);
    expect(b.nameBaseline, 1268);
    expect(b.numeral.top, 512);
    expect(b.numeral.bottom, 776);
    expect(b.context.top, 800);
    expect(b.cover, Rect.zero);
    expect(b.bars, Rect.zero);
  });

  test('the figure fits: Story is exact, Post scales down and centres', () {
    final s = figureFit(shareBoxes(ShareFormat.story).figure);
    expect(s.scale, closeTo(3, 1e-9));
    expect(s.origin, const Offset(72, 648));
    final p = figureFit(shareBoxes(ShareFormat.post).figure);
    expect(p.scale, closeTo(568 / 304, 1e-9));
    expect(p.origin.dx, greaterThan(72));
    expect(p.origin.dy, 512);
  });
}
