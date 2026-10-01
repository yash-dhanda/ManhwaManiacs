// ignore_for_file: require_trailing_commas
import 'dart:ui' show Rect;

import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/glass/listen/band_geometry.dart';
import 'package:manhwamaniacs/skins/glass/listen/highlight_layer.dart';
import 'package:manhwamaniacs/skins/glass/listen/paged_follow.dart';

import '../../../support/narration_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the band follows the active sentence, takes the speaker hue and steps the word', () async {
    final h = await NarrationHarness.create();
    addTearDown(h.dispose);
    final targets = <BandTarget?>[];
    final band = GlassListenBand(vsync: const TestVSync(), reduced: () => false, onSentence: targets.add);
    addTearDown(band.dispose);
    final target = listenTarget();
    await h.startAndSettle(target);
    void sync() => band.sync(narration: h.controller, state: h.state, chapter: target.key, paragraphs: target.paragraphs);
    sync();
    expect(band.enabled, isTrue);
    h.player.tick(0);
    await h.settle();
    expect(band.segment, 0);
    expect(band.next, isNotNull);
    final first = band.next!;
    // Sentence 2 of the fixture is dialogue read by Iris: its segment's `spk` hue replaces the narration iris.
    h.player.tick(21000);
    await h.settle();
    expect(band.segment, isNot(0));
    expect(band.prev, first);
    expect(targets.where((e) => e != null).length, greaterThanOrEqualTo(2));
    expect(band.word, isNotNull);
    expect(band.word!.start, greaterThanOrEqualTo(band.next!.start));
    expect(band.word!.end, lessThanOrEqualTo(band.next!.end));
  });

  test('stale timing or another chapter shows no band', () async {
    final h = await NarrationHarness.create();
    addTearDown(h.dispose);
    final band = GlassListenBand(vsync: const TestVSync(), reduced: () => false);
    addTearDown(band.dispose);
    final stale = listenTarget(stale: true);
    await h.startAndSettle(stale);
    band.sync(narration: h.controller, state: h.state, chapter: stale.key, paragraphs: stale.paragraphs);
    expect(band.enabled, isFalse);
    final other = listenTarget(chapter: 'c13');
    await h.startAndSettle(other);
    band.sync(narration: h.controller, state: h.state, chapter: stale.key, paragraphs: stale.paragraphs);
    expect(band.enabled, isFalse);
  });

  test('geometry: bands slide and paged follow decouples', () {
    const a = [Rect.fromLTWH(10, 10, 100, 20)];
    const b = [Rect.fromLTWH(10, 40, 100, 20)];
    expect(morphBands(a, b, 0.5).single.top, closeTo(25, 1e-9));
    final f = PagedFollow();
    expect(f.turnFor(activeFirstLineTop: 900, pageBottom: 800), isTrue);
    f.manualTurn();
    expect(f.turnFor(activeFirstLineTop: 900, pageBottom: 800), isFalse);
    expect(kBandAlpha, 0.14);
  });
}
