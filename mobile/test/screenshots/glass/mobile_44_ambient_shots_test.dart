// ignore_for_file: require_trailing_commas
import 'dart:convert';
import 'dart:io';
import 'dart:ui' show Rect;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/reader/models/reader_chapter.dart';
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/screens/reader/glass_manga_reader.dart';
import 'package:manhwamaniacs/skins/glass/screens/reader/page_thumb.dart' show proxiedPageUrl;
import 'package:manhwamaniacs/skins/glass/soundscape/recipes.dart';
import 'package:manhwamaniacs/skins/glass/soundscape/soundscape_controller.dart';

import '../../skins/glass/reader/demo_pages.dart';
import '../../skins/glass/reader/glass_reader_rig.dart';
import '../../skins/glass/soundscape/soundscape_fakes.dart';
import '../support/series_shots.dart';
import '../support/shot_harness.dart';
import '../support/shot_network.dart';
import '../support/skin_shots.dart';

/// The mobile-44 proof: cruise, the soundscape sheet, rain, guided view and page-tinted chrome over the demo pages, into `MM_PROOF_DIR`.
void main() {
  final demo = DemoPages.load();
  setUpAll(loadAppFonts);
  setUpAll(setUpShotCoverCache);
  final phone = kSkinShotSizes[0];

  Map<String, ReaderChapter> chapters() => {
        'c1': demo.chapter('c1', demo: 2, title: 'Chapter 142', next: 'c2'),
        'c2': demo.chapter('c2', title: 'Chapter 143', prev: 'c1', next: 'c3'),
        'c3': demo.chapter('c3', demo: 2, title: 'Chapter 144', prev: 'c2'),
      };

  /// The panel boxes of `brand/demo/demo.json` for chapter 1 as page fractions.
  Map<int, List<Rect>> demoPanels() {
    final d = jsonDecode(File('../brand/demo/demo.json').readAsStringSync()) as Map<String, dynamic>;
    final pages = [for (final p in (d['pages'] as List).cast<Map<String, dynamic>>()) if (p['chapter'] == 1) p];
    return {
      for (final (i, p) in pages.indexed)
        i + 1: [
          for (final b in (p['panels'] as List).cast<Map<String, dynamic>>())
            Rect.fromLTWH((b['x'] as num) / (p['width'] as num), (b['y'] as num) / (p['height'] as num), (b['w'] as num) / (p['width'] as num), (b['h'] as num) / (p['height'] as num)),
        ],
    };
  }

  late SoundscapeRig sound;

  Future<GlassReaderRig> open(
    WidgetTester t, {
    SkinShotSize? size,
    Map<String, Object> prefs = const {},
    List<Override> extra = const [],
  }) async {
    final sz = size ?? phone;
    sound = await SoundscapeRig.create();
    final artBytes = {...demo.bytes('c1', demo: 2), ...demo.bytes('c2'), ...demo.bytes('c3', demo: 2)};
    addShotCovers({...artBytes, for (final e in artBytes.entries) ...{proxiedPageUrl(e.key, 240): e.value, proxiedPageUrl(e.key, 96): e.value}});
    final rig = await pumpGlassReader(t,
        size: sz.logical,
        padding: sz.padding,
        chapters: chapters(),
        ocr: const [],
        prefsValues: prefs,
        extra: [
          soundscapeAudioProvider.overrideWithValue(sound.audio),
          proceduralStoreProvider.overrideWithValue(FakeStore()),
          glassSoundscapeFilesProvider.overrideWithValue(sound.files),
          soundscapeSessionProvider.overrideWithValue(sound.session),
          musicActiveProvider.overrideWithValue(() async => false),
          ...extra,
        ],
        mockPathProvider: false);
    await pumpUntilCoversLoad(t, rounds: 12);
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 800)));
    await settleReader(t, ms: 900);
    return rig;
  }

  GlassMangaReaderState st(WidgetTester t) => t.state<GlassMangaReaderState>(find.byType(GlassMangaReader));

  Future<void> shot(WidgetTester t, String name, [SkinShotSize? size]) => captureSeriesShot(t, name, size ?? phone);

  Future<void> art(WidgetTester t) async {
    for (var i = 0; i < 3; i++) {
      await pumpUntilCoversLoad(t, rounds: 6);
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 500)));
    }
    await settleReader(t, ms: 400);
  }

  Future<void> scrollTo(WidgetTester t, double px) async {
    final pos = t.state<ScrollableState>(find.byType(Scrollable).first).position;
    pos.jumpTo(px.clamp(pos.minScrollExtent, pos.maxScrollExtent));
    await art(t);
    st(t).engine.showChrome();
    await settleReader(t, ms: 600);
  }

  Future<void> key(WidgetTester t, LogicalKeyboardKey k, {String? char, bool shift = false}) async {
    if (shift) await t.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await t.sendKeyEvent(k, character: char);
    if (shift) await t.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await settleReader(t, ms: 700);
  }

  void seedPanels(WidgetTester t) => st(t).engine.ambient.seed('c2', panels: demoPanels());

  testWidgets('cruise: the pill running, the HUD while dragging, the landscape pill, the Cruise row at 1.4x', (t) async {
    await open(t);
    await scrollTo(t, 600);
    st(t).toggleCruise();
    await settleReader(t, ms: 600);
    await shot(t, 'cruise-pill');
    final centre = t.getCenter(find.text('1.0×'));
    final g = await t.startGesture(centre);
    await g.moveBy(const Offset(0, -20));
    await t.pump();
    await g.moveBy(const Offset(0, -80));
    await settleReader(t, ms: 500);
    await shot(t, 'cruise-hud');
    await g.up();
    await settleReader(t, ms: 500);
    await disposeGlassReader(t);

    await open(t, size: kSkinShotLandscape);
    await scrollTo(t, 400);
    st(t).toggleCruise();
    await settleReader(t, ms: 600);
    await shot(t, 'cruise', kSkinShotLandscape);
    await disposeGlassReader(t);

    t.platformDispatcher.textScaleFactorTestValue = 1.4;
    addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
    await open(t);
    await scrollTo(t, 600);
    await key(t, LogicalKeyboardKey.comma, char: ',');
    await settleReader(t, ms: 700);
    await shot(t, 'cruise-textscale-1.4');
    await disposeGlassReader(t);
  });

  testWidgets('soundscape: the sheet playing Rain with its level bars, the built-in badge, landscape and the tablet panel', (t) async {
    await open(t);
    await scrollTo(t, 600);
    await key(t, LogicalKeyboardKey.keyS, char: 'S', shift: true);
    await settleReader(t, ms: 900);
    await t.tapAt(t.getCenter(find.text('Rain').first) - const Offset(0, 40));
    await settleReader(t, ms: 3000);
    await shot(t, 'soundscape-sheet');
    await shot(t, 'soundscape-builtin');
    await t.binding.handlePopRoute();
    await settleReader(t, ms: 800);
    await shot(t, 'rain');
    await disposeGlassReader(t);

    await open(t, size: kSkinShotLandscape);
    await scrollTo(t, 400);
    await key(t, LogicalKeyboardKey.keyS, char: 'S', shift: true);
    await settleReader(t, ms: 900);
    await t.tapAt(t.getCenter(find.text('Wind').first) - const Offset(0, 40));
    await settleReader(t, ms: 2500);
    await shot(t, 'soundscape-sheet', kSkinShotLandscape);
    await disposeGlassReader(t);

    await open(t, size: kSkinShotDesktop);
    await scrollTo(t, 400);
    await key(t, LogicalKeyboardKey.keyS, char: 'S', shift: true);
    await settleReader(t, ms: 1200);
    await captureSeriesShotPlain(t, 'soundscape-panel-desktop');
    await disposeGlassReader(t);
  });

  testWidgets('guided view: framed panel, mid-glide, whole page, overview', (t) async {
    await open(t);
    seedPanels(t);
    await scrollTo(t, 0);
    await key(t, LogicalKeyboardKey.keyP, char: 'P', shift: true);
    await art(t);
    await shot(t, 'guided');
    await t.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await t.pump(const Duration(milliseconds: 140));
    await shot(t, 'guided-sliver');
    await settleReader(t, ms: 700);
    await t.tapAt(const Offset(195, 420));
    await t.pump(const Duration(milliseconds: 80));
    await t.tapAt(const Offset(195, 420));
    await settleReader(t, ms: 800);
    await shot(t, 'guided-whole-page');
    await settleReader(t, ms: 1800);
    await t.tap(find.byWidgetPredicate((w) => w is Semantics && w.properties.label == 'Show the whole page'));
    await settleReader(t, ms: 800);
    await shot(t, 'guided-overview');
    await disposeGlassReader(t);
  });

  testWidgets('page-tinted chrome over a dark, a white and a colourful page; off; solid', (t) async {
    await open(t);
    st(t).jumpTo(15);
    await art(t);
    st(t).engine.showChrome();
    await settleReader(t, ms: 1400);
    await shot(t, 'tint-dark-page');
    st(t).jumpTo(8);
    await art(t);
    st(t).engine.showChrome();
    await settleReader(t, ms: 1400);
    await shot(t, 'tint-white-page');
    st(t).jumpTo(3);
    await art(t);
    st(t).engine.showChrome();
    await settleReader(t, ms: 1400);
    await shot(t, 'tint-colour-page');
    await disposeGlassReader(t);

    await open(t, prefs: {'mm.reader-settings.device': '{"glass":{"pageTinted":false}}'});
    st(t).jumpTo(3);
    await art(t);
    st(t).engine.showChrome();
    await settleReader(t, ms: 1400);
    await shot(t, 'tint-off');
    await disposeGlassReader(t);

    await open(t, extra: [glassA11yProvider.overrideWith((ref) => const GlassA11y(solid: true))]);
    st(t).jumpTo(3);
    await art(t);
    st(t).engine.showChrome();
    await settleReader(t, ms: 1400);
    await shot(t, 'tint-solid');
    await disposeGlassReader(t);
    expect(SoundScene.values.length, 6);
  });
}
