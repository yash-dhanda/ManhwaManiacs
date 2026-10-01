// ignore_for_file: require_trailing_commas
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/core/platform/gravity.dart';
import 'package:manhwamaniacs/features/downloads/models/chapter_identity.dart';
import 'package:manhwamaniacs/features/downloads/models/download_chapter_state.dart';
import 'package:manhwamaniacs/features/downloads/providers/bookmark_outbox_provider.dart';
import 'package:manhwamaniacs/features/ocr/providers/ocr_providers.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_engine_options.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_frames.dart';
import 'package:manhwamaniacs/features/reader/engine/seam.dart';
import 'package:manhwamaniacs/features/reader/models/bookmark.dart';
import 'package:manhwamaniacs/features/reader/models/reader_chapter.dart';
import 'package:manhwamaniacs/features/reader/repositories/reader_repository.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';
import 'package:manhwamaniacs/skins/glass/glass_skin.dart';
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/scrub_rail.dart';
import 'package:manhwamaniacs/skins/glass/screens/reader/chapter_seam.dart';
import 'package:manhwamaniacs/skins/glass/screens/reader/glass_manga_reader.dart';
import 'package:manhwamaniacs/skins/glass/screens/reader/page_thumb.dart';
import 'package:manhwamaniacs/skins/glass/screens/reader/reader_states.dart';

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
  final phone = kSkinShotSizes[0];

  Map<String, ReaderChapter> chapters({int pages = 20}) => {
        'c1': demo.chapter('c1', demo: 2, title: 'Chapter 142', next: 'c2', pages: pages),
        'c2': demo.chapter('c2', title: 'Chapter 143', prev: 'c1', next: 'c3', pages: pages),
        'c3': demo.chapter('c3', demo: 2, title: 'Chapter 144', prev: 'c2', pages: pages),
      };

  Future<GlassReaderRig> open(
    WidgetTester t, {
    SkinShotSize? size,
    String chapter = 'c2',
    Map<String, Object> prefs = const {},
    List<Override> extra = const [],
    String query = '',
    int pages = 20,
    TargetPlatform platform = TargetPlatform.iOS,
    bool withOcr = true,
    FeatureRig? feature,
    bool toasts = false,
  }) async {
    final sz = size ?? phone;
    final artBytes = {...demo.bytes('c1', demo: 2), ...demo.bytes('c2'), ...demo.bytes('c3', demo: 2)};
    // The scrub lens, the go-to thumbnail and the panel rows ask the image proxy for w=240 / w=96.
    addShotCovers({...artBytes, for (final e in artBytes.entries) ...{proxiedPageUrl(e.key, 240): e.value, proxiedPageUrl(e.key, 96): e.value}});
    final rig = await pumpGlassReader(t,
        size: sz.logical, padding: sz.padding, chapterKey: chapter, chapters: chapters(pages: pages), ocr: withOcr ? demo.ocr() : const [], prefsValues: prefs, extra: extra, query: query, platform: platform, mockPathProvider: false, feature: feature, toasts: toasts);
    await pumpUntilCoversLoad(t, rounds: 12);
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 800)));
    await settleReader(t, ms: 900);
    return rig;
  }

  GlassMangaReaderState st(WidgetTester t) => t.state<GlassMangaReaderState>(find.byType(GlassMangaReader));

  Future<void> shot(WidgetTester t, String name, [SkinShotSize? size]) => captureSeriesShot(t, name, size ?? phone);

  /// Lets page art that came into view fetch and decode (real time), then paints it.
  Future<void> art(WidgetTester t) async {
    for (var i = 0; i < 3; i++) {
      await pumpUntilCoversLoad(t, rounds: 6);
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 500)));
    }
    await settleReader(t, ms: 400);
  }

  /// Scrolls the strip by [px] and brings the chrome back (a scroll hides it).
  Future<void> scrollBy(WidgetTester t, double px, {bool chrome = true}) async {
    final pos = t.state<ScrollableState>(find.byType(Scrollable).first).position;
    pos.jumpTo((pos.pixels + px).clamp(pos.minScrollExtent, pos.maxScrollExtent));
    await art(t);
    if (chrome) {
      t.state<GlassMangaReaderState>(find.byType(GlassMangaReader)).engine.showChrome();
      await settleReader(t, ms: 600);
    }
  }

  Future<void> key(WidgetTester t, LogicalKeyboardKey k, {String? char}) async {
    await t.sendKeyEvent(k, character: char);
    await settleReader(t, ms: 700);
  }

  testWidgets('chrome, pill, cinema, locked, popover, zoom chip', (t) async {
    await open(t);
    await scrollBy(t, 700);
    st(t).engine.showChrome();
    await settleReader(t, ms: 600);
    await shot(t, 'chrome-shown');
    st(t).engine.hideChrome();
    await settleReader(t, ms: 700);
    await shot(t, 'chrome-hidden-pill');
    st(t).engine.showChrome();
    await settleReader(t, ms: 600);
    await key(t, LogicalKeyboardKey.keyG, char: 'g');
    await shot(t, 'goto-popover');
    st(t).setGoTo(false);
    await key(t, LogicalKeyboardKey.equal, char: '=');
    await shot(t, 'zoom-chip');
    await key(t, LogicalKeyboardKey.digit0, char: '0');
    await disposeGlassReader(t);

    await open(t, prefs: {'mm.reader-settings.device': '{"cinema":true}'});
    await scrollBy(t, 900);
    st(t).engine.hideChrome();
    await settleReader(t, ms: 3500);
    await shot(t, 'cinema');
    await disposeGlassReader(t);

    await open(t, prefs: {'mm.reader-settings.device': '{"glass":{"lockControls":true}}'});
    await scrollBy(t, 500);
    await t.tapAt(const Offset(195, 420));
    await t.pump(const Duration(milliseconds: 120));
    await shot(t, 'locked');
    await disposeGlassReader(t);
  });

  testWidgets('tint over a white page and a dark page', (t) async {
    // Demo chapter 1, page 8 is the white panel; page 15 is near black.
    await open(t);
    st(t).jumpTo(8);
    await art(t);
    st(t).engine.showChrome();
    await settleReader(t, ms: 1200);
    await shot(t, 'tint-white-page');
    st(t).jumpTo(15);
    await art(t);
    st(t).engine.showChrome();
    await settleReader(t, ms: 1200);
    await shot(t, 'tint-dark-page');
    await disposeGlassReader(t);
  });

  testWidgets('seams, the seam chip and the end states', (t) async {
    await open(t, pages: 4);
    final pos = t.state<ScrollableState>(find.byType(Scrollable).first).position;
    pos.jumpTo(pos.maxScrollExtent);
    await art(t);
    // The seam between chapter 143 and 144 a little above the middle of the screen.
    st(t).engine.seekToChapter(1);
    await art(t);
    await scrollBy(t, -300, chrome: false);
    await shot(t, 'seam');
    st(t).engine.emitSeam(const SeamEvent.top('c3'));
    await settleReader(t, ms: 300);
    await shot(t, 'seam-chip');
    await disposeGlassReader(t);

    await open(t, chapter: 'c3', pages: 4);
    final p2 = t.state<ScrollableState>(find.byType(Scrollable).first).position;
    p2.jumpTo(p2.maxScrollExtent);
    await art(t);
    await shot(t, 'caught-up');
    await disposeGlassReader(t);
  });

  testWidgets('one at a time: the next-chapter card armed and locked', (t) async {
    await open(t, pages: 4, prefs: {'mm.reader-settings.device': '{"autoNextChapter":false,"glass":{"chapters":"single"}}'});
    final pos = t.state<ScrollableState>(find.byType(Scrollable).first).position;
    pos.jumpTo(pos.maxScrollExtent);
    st(t).engine.showChrome();
    await settleReader(t, ms: 300);
    final g = await t.startGesture(const Offset(200, 420));
    await g.moveBy(const Offset(0, -20));
    await t.pump();
    await g.moveBy(const Offset(0, -95));
    await settleReader(t, ms: 400);
    await shot(t, 'next-card-armed');
    await g.moveBy(const Offset(0, -55));
    await settleReader(t, ms: 400);
    await pumpUntilCoversLoad(t, rounds: 8);
    await shot(t, 'next-card-locked');
    await g.cancel();
    await disposeGlassReader(t);
  });

  testWidgets('paged single, the settings sheet, the chapter list, the page menu', (t) async {
    await open(t, prefs: {'mm.reader-prefs.device': '{"demo:k":{"layout":"single","fit":"height"}}'});
    await art(t);
    await shot(t, 'paged-single');
    await disposeGlassReader(t);

    await open(t);
    await scrollBy(t, 600);
    await key(t, LogicalKeyboardKey.comma, char: ',');
    await settleReader(t, ms: 600);
    await shot(t, 'settings-sheet-medium');
    await t.binding.handlePopRoute();
    await settleReader(t, ms: 600);
    await key(t, LogicalKeyboardKey.keyT, char: 't');
    await settleReader(t, ms: 900);
    await shot(t, 'chapter-list');
    await t.binding.handlePopRoute();
    await settleReader(t, ms: 600);
    await t.longPressAt(const Offset(195, 500));
    await settleReader(t, ms: 700);
    await shot(t, 'page-menu');
    await disposeGlassReader(t);
  });

  testWidgets('dialogue overlay and the hit lens', (t) async {
    await open(t);
    await key(t, LogicalKeyboardKey.keyO, char: 'o');
    await shot(t, 'dialogue-overlay');
    await disposeGlassReader(t);

    await open(t, query: '?q=gate');
    await settleReader(t, ms: 1000);
    await shot(t, 'hit-lens');
    await disposeGlassReader(t);
  });

  testWidgets('landscape, tablet, desktop panels and gutters', (t) async {
    await open(t, size: kSkinShotLandscape);
    await scrollBy(t, 300);
    st(t).engine.showChrome();
    await settleReader(t, ms: 600);
    await captureSeriesShotPlain(t, 'reader-landscape');
    await disposeGlassReader(t);

    await open(t, size: kSkinShotSizes[1]);
    await scrollBy(t, 400);
    st(t).engine.showChrome();
    await settleReader(t, ms: 600);
    await captureSeriesShotPlain(t, 'reader-tablet');
    await disposeGlassReader(t);

    await open(t, size: kSkinShotDesktop);
    await scrollBy(t, 400);
    await shot(t, 'gutters', kSkinShotDesktop);
    await key(t, LogicalKeyboardKey.keyT, char: 't');
    await art(t);
    await shot(t, 'panel-left', kSkinShotDesktop);
    await key(t, LogicalKeyboardKey.comma, char: ',');
    await art(t);
    st(t).engine.showChrome();
    await settleReader(t, ms: 600);
    await shot(t, 'panels-both', kSkinShotDesktop);
    await disposeGlassReader(t);

    await open(t, size: kSkinShotDesktop, prefs: {'mm.reader-prefs.device': '{"demo:k":{"layout":"double","fit":"height"}}'});
    await art(t);
    await shot(t, 'paged-double', kSkinShotDesktop);
    await disposeGlassReader(t);

    await open(t, size: kSkinShotTabletWide);
    await art(t);
    await key(t, LogicalKeyboardKey.keyT, char: 't');
    await key(t, LogicalKeyboardKey.comma, char: ',');
    await settleReader(t, ms: 400);
    await shot(t, 'panels-narrow', kSkinShotTabletWide);
    await disposeGlassReader(t);
  });

  testWidgets('accessibility renderings: reduced, solid, contrast', (t) async {
    await open(t, extra: [glassMotionPrefsProvider.overrideWith((ref) => const GlassMotionPrefs(reduced: true))]);
    await scrollBy(t, 600);
    await shot(t, 'chrome-reduced');
    await disposeGlassReader(t);
    await open(t, extra: [glassA11yProvider.overrideWith((ref) => const GlassA11y(solid: true))]);
    await scrollBy(t, 600);
    await shot(t, 'chrome-solid');
    await disposeGlassReader(t);
    await open(t, extra: [glassA11yProvider.overrideWith((ref) => const GlassA11y(increaseContrast: true))]);
    await scrollBy(t, 600);
    await shot(t, 'chrome-contrast');
    await disposeGlassReader(t);
  });

  testWidgets('states: loading, error, no pages', (t) async {
    Future<void> frame(String name, Widget w) async {
      setSkinShotView(t, phone);
      await t.pumpWidget(ProviderScope(overrides: [...await skinShotRootOverrides(), gravitySensorProvider.overrideWithValue(() => const Stream.empty())], child: shotFrame(w)));
      await t.pump(const Duration(milliseconds: 400));
      await shot(t, name);
    }

    await frame('loading', const GlassReaderLoading(chapterLabel: 'Chapter 143', slowAfter: Duration(days: 1)));
    await frame('error', GlassReaderFailure(failure: ReaderFailure(error: const NetworkError(message: 'The source took too long to answer.'), noPages: false, retry: () {}, back: () {})));
    await frame('no-pages', GlassReaderFailure(failure: ReaderFailure(error: null, noPages: true, retry: () {}, back: () {})));
    await frame('gate-closed', GlassReaderFailure(failure: ReaderFailure(error: null, noPages: false, retry: () {}, back: () {}), gated: true));
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('scrub lens, brightness band HUD, taps overlay, settings at large', (t) async {
    await open(t);
    await scrollBy(t, 600);
    final rail = t.getRect(find.byType(GlassScrubRail));
    final g = await t.startGesture(Offset(rail.center.dx, rail.top + rail.height * 0.25));
    await t.pump(const Duration(milliseconds: 100));
    await g.moveBy(const Offset(0, 60));
    await t.pump(const Duration(milliseconds: 100));
    await g.moveBy(const Offset(0, 60));
    await settleReader(t, ms: 500);
    await pumpUntilCoversLoad(t, rounds: 8);
    await shot(t, 'scrub-lens');
    await g.up();
    await art(t);

    final b = await t.startGesture(const Offset(40, 560));
    await b.moveBy(const Offset(0, -12));
    await t.pump();
    await b.moveBy(const Offset(0, -110));
    await settleReader(t, ms: 300);
    await shot(t, 'brightness-band-hud');
    await b.up();
    await settleReader(t, ms: 1000);

    // A layout change shows the three panes for 1.5 s.
    await key(t, LogicalKeyboardKey.keyV, char: 'v');
    await shot(t, 'taps-overlay');
    await disposeGlassReader(t);

    await open(t);
    await scrollBy(t, 600);
    await key(t, LogicalKeyboardKey.comma, char: ',');
    await settleReader(t, ms: 600);
    await t.dragFrom(const Offset(195, 470), const Offset(0, -420));
    await settleReader(t, ms: 900);
    await shot(t, 'settings-sheet-large');
    await disposeGlassReader(t);
  });

  testWidgets('sideways chapter swipe and a paged Slide mid-turn', (t) async {
    await open(t, prefs: {'mm.reader-settings.device': '{"glass":{"swipeChapter":true}}'});
    await scrollBy(t, 600, chrome: false);
    final g = await t.startGesture(const Offset(320, 420));
    await g.moveBy(const Offset(-20, 0));
    await t.pump();
    await g.moveBy(const Offset(-240, 0));
    await settleReader(t, ms: 200);
    await shot(t, 'swipe-neighbour');
    await g.cancel();
    await disposeGlassReader(t);

    await open(t, prefs: {
      'mm.reader-prefs.device': '{"demo:k":{"layout":"single","fit":"height"}}',
      'mm.reader-settings.device': '{"glass":{"pageTransition":"slide"}}',
    });
    await art(t);
    st(t).engine.hideChrome();
    await settleReader(t, ms: 500);
    final p = await t.startGesture(const Offset(330, 420));
    await p.moveBy(const Offset(-20, 0));
    await t.pump();
    await p.moveBy(const Offset(-150, 0));
    await t.pump(const Duration(milliseconds: 50));
    await shot(t, 'paged-slide-mid');
    await p.cancel();
    await disposeGlassReader(t);
  });

  testWidgets('seam bands: loading, failed, missing, rate limited, offline end', (t) async {
    final bands = GlassReaderBands(nextLabel: 'Chapter 144', previousLabel: 'Chapter 142', onRetryNeighbour: () {}, onOpenNext: () {}, onDownloadNext: () {}, backoff: const Duration(seconds: 4));
    Future<void> band(String name, Widget Function(BuildContext) b) async {
      setSkinShotView(t, phone);
      await t.pumpWidget(ProviderScope(
          overrides: [...await skinShotRootOverrides(), gravitySensorProvider.overrideWithValue(() => const Stream.empty())],
          child: shotFrame(ColoredBox(
            color: const Color(0xFF000000),
            child: Column(children: [
              Expanded(child: Container(color: const Color(0xFF0B0B0F))),
              Builder(builder: b),
              Expanded(child: Container(color: const Color(0xFF0B0B0F))),
            ]),
          ))));
      await t.pump(const Duration(milliseconds: 1400));
      await shot(t, name);
    }

    await band('seam-loading', (c) => bands.build(c, BandKind.nextLoading));
    await band('seam-failed', (c) => bands.build(c, BandKind.nextFailed));
    await band('seam-missing', (c) => const GlassChapterSeam(from: 'Chapter 143', to: 'Chapter 145'));
    await band('rate-limited', (c) => bands.build(c, BandKind.rateLimited));
    await band('offline-end', (c) => bands.build(c, BandKind.offlineEnd));
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('offline: the capsule and the chapter list; Extract text on a saved chapter', (t) async {
    const saved = (state: DownloadChapterState.complete, error: null);
    await open(t, feature: FeatureRig(online: false, statuses: {'c1': saved, 'c2': saved}));
    await scrollBy(t, 600);
    await shot(t, 'offline');
    await key(t, LogicalKeyboardKey.keyT, char: 't');
    await settleReader(t, ms: 900);
    await shot(t, 'chapter-list-offline');
    await disposeGlassReader(t);

    await open(t, withOcr: false, feature: FeatureRig(statuses: {'c2': saved}), extra: [ocrAvailableProvider.overrideWith((ref) async => true)]);
    await key(t, LogicalKeyboardKey.keyO, char: 'o');
    await settleReader(t, ms: 400);
    await shot(t, 'extract-text');
    await disposeGlassReader(t);
  });

  testWidgets('toast states: bookmark saved and failed, stale anchor, further elsewhere; unavailable', (t) async {
    await open(t, toasts: true, extra: [bookmarkOutboxControllerProvider.overrideWith((ref) => _ShotOutbox(ref.watch(readerRepositoryProvider)))]);
    await scrollBy(t, 600);
    await key(t, LogicalKeyboardKey.keyB, char: 'b');
    await settleReader(t, ms: 500);
    await shot(t, 'bookmark-saved');
    await disposeGlassReader(t);

    await open(t, toasts: true);
    await scrollBy(t, 600);
    await key(t, LogicalKeyboardKey.keyB, char: 'b');
    await settleReader(t, ms: 500);
    await shot(t, 'bookmark-failed');
    await disposeGlassReader(t);

    // The toast lives 4 s: open without the long art warm-up so it is still up for the capture.
    await pumpGlassReader(t,
        size: phone.logical, padding: phone.padding, chapters: chapters(), ocr: demo.ocr(), query: '?page=25&at=0.2', mockPathProvider: false, toasts: true);
    await settleReader(t, ms: 1200);
    await shot(t, 'stale-anchor');
    await disposeGlassReader(t);

    await open(t, toasts: true);
    await scrollBy(t, 600);
    st(t).engine.reportServerProgress(chapterKey: 'c3', chapterNumber: 146, lastPage: 12, advanced: false);
    await settleReader(t, ms: 600);
    await shot(t, 'further-elsewhere');
    await disposeGlassReader(t);

    setSkinShotView(t, phone);
    await t.pumpWidget(ProviderScope(
        overrides: [...await skinShotRootOverrides(), gravitySensorProvider.overrideWithValue(() => const Stream.empty())],
        child: shotFrame(GlassReaderFailure(
            failure: ReaderFailure(
                error: const ApiError(statusCode: 404, code: 'series_not_found', message: 'Series not found'), noPages: false, retry: () {}, back: () {}),))));
    await t.pump(const Duration(milliseconds: 400));
    await shot(t, 'unavailable');
    await t.pumpWidget(const SizedBox());
  });
}

/// Saves every bookmark (no store in the rig).
class _ShotOutbox extends BookmarkOutboxController {
  _ShotOutbox(ReaderRepository repo) : super(store: null, repository: repo, activeScopeId: () => 'u1p1');

  @override
  Future<Bookmark?> create({
    required ChapterIdentity id,
    required BookmarkMedia media,
    required int anchorIndex,
    required double anchorFraction,
    required int anchorTotal,
    String? seriesTitle,
    double? chapterNumber,
    String? snippet,
    String? note,
  }) async {
    final now = DateTime.now().toUtc();
    return Bookmark(clientId: 'shot', sourceId: id.sourceId, seriesKey: id.seriesKey, chapterKey: id.chapterKey, createdAt: now, updatedAt: now);
  }
}

/// A state widget inside the Glass root, for the state captures.
Widget shotFrame(Widget child) => RepaintBoundary(
      key: kSkinShotKey,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: GlassSkin.baseTheme,
        builder: (context, c) => const GlassSkin().wrap(context, c ?? const SizedBox.shrink()),
        home: child,
      ),
    );
