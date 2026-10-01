// ignore_for_file: require_trailing_commas
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/reader/models/reader_chapter.dart';

import '../../skins/glass/reader/demo_pages.dart';
import '../../skins/glass/reader/glass_reader_rig.dart';
import '../support/series_shots.dart';
import '../support/shot_harness.dart';
import '../support/shot_network.dart';
import '../support/skin_shots.dart';

/// The mobile-35 proof: the Glass manga reader over the demo pages (`brand/demo`), into `MM_PROOF_DIR`.
void main() {
  final demo = DemoPages.load();
  setUpAll(loadAppFonts);
  setUpAll(setUpShotCoverCache);

  Map<String, ReaderChapter> chapters() => {
        'c1': demo.chapter('c1', demo: 2, title: 'Chapter 142', next: 'c2'),
        'c2': demo.chapter('c2', title: 'Chapter 143', prev: 'c1', next: 'c3'),
        'c3': demo.chapter('c3', demo: 2, title: 'Chapter 144', prev: 'c2'),
      };

  Future<GlassReaderRig> open(WidgetTester t, {SkinShotSize? size, String chapter = 'c2'}) async {
    final sz = size ?? kSkinShotSizes[0];
    addShotCovers({...demo.bytes('c1', demo: 2), ...demo.bytes('c2'), ...demo.bytes('c3', demo: 2)});
    final rig = await pumpGlassReader(t, size: sz.logical, padding: sz.padding, chapterKey: chapter, chapters: chapters(), ocr: demo.ocr());
    await pumpUntilCoversLoad(t, rounds: 12);
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 800)));
    await settleReader(t, ms: 900);
    return rig;
  }

  testWidgets('chrome shown and the pill', (t) async {
    await open(t);
    await captureSeriesShot(t, 'chrome-shown', kSkinShotSizes[0]);
    await t.drag(find.byType(Scrollable).first, const Offset(0, -300));
    await settleReader(t, ms: 900);
    await captureSeriesShot(t, 'chrome-hidden-pill', kSkinShotSizes[0]);
    await disposeGlassReader(t);
  });
}
