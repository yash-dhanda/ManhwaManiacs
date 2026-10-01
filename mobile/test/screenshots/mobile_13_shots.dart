// ignore_for_file: require_trailing_commas, directives_ordering
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/circle/models/circle_models.dart';
import 'package:manhwamaniacs/features/circle/providers/circle_providers.dart';
import 'package:manhwamaniacs/features/ocr/models/page_text.dart';
import 'package:manhwamaniacs/features/ocr/providers/ocr_providers.dart';
import 'package:manhwamaniacs/features/reader/engine/paged_reader_view.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_engine_view.dart';
import 'package:manhwamaniacs/features/reader/utils/reader_prefs_migration.dart';
import 'package:manhwamaniacs/features/sources/models/source_series.dart';
import 'package:manhwamaniacs/features/sources/providers/sources_provider.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/paged_rules.dart';

import '../skins/cinematic/reader/reader_read_all_test.dart' show BatchReader;
import '../skins/cinematic/reader/reader_test_support.dart';
import 'support/series_shots.dart';
import 'support/shot_covers.dart';
import 'support/shot_network.dart';
import 'support/skin_shots.dart';

/// The mobile-13 proof shots: paged layouts, read-all, Reading setup, Margins and the page actions
/// of the Cinematic manga reader, with invented fixtures only (procedural page art).
void mobile13Shots() {
  Future<void> addPages(WidgetTester tester, {int chapters = 4, int pages = 6, int first = 1}) async {
    final png = await tester.runAsync(() async => {
          for (var i = 0; i < chapters; i++)
            for (var n = 1; n <= pages; n++)
              '/reader/page/${i < 4 && first == 1 ? ['c1', 'c2', 'c3', 'cx'][i] : 'c${first + i}'}-$n/image':
                  await ShotCoverArt(title: 'Tower of Dawn', seed: n + i * 2).toPng(width: 400, height: 600),
        });
    addShotCovers(png!);
  }

  Future<void> loadArt(WidgetTester tester) async {
    await pumpUntilCoversLoad(tester, rounds: 12);
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 800)));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> showChrome(WidgetTester tester) async {
    if (chromeVisible(tester)) return;
    await tapMenu(tester);
  }

  String legacyDirection(String v) => v;

  Map<String, Object> seed(String layout, {String direction = 'ltr', String fit = 'height', Map<String, Object> more = const {}, Map<String, Object> device = const {}}) => {
        kReaderPrefsMigratedKey: true,
        kReaderPrefsSeedKey: jsonEncode({
          'seriesDefaults': {'layout': layout, 'direction': direction, 'fit': fit},
          ...more,
        }),
        ...device,
      };

  Future<void> show(
    WidgetTester tester,
    String name, {
    bool phone = true,
    bool tablet = false,
    bool art = true,
    String chapter = 'c2',
    bool reduced = false,
    bool chrome = true,
    Map<String, Object> prefs = const {},
    List<Override> extra = const [],
    ReaderRigOrigin origin = ReaderRigOrigin.manifest,
    TargetPlatform platform = TargetPlatform.android,
    int artChapters = 4,
    int artFirst = 1,
    Future<void> Function(WidgetTester tester, ReaderRig rig, bool wide)? act,
    Future<void> Function(WidgetTester tester)? after,
  }) async {
    for (final (size, wide, on) in [
      (kSkinShotSizes[0], false, phone),
      (kSkinShotSizes[1], true, tablet),
    ]) {
      if (!on) continue;
      if (art) await addPages(tester, chapters: artChapters, first: artFirst);
      final rig = await pumpReader(tester, wide: wide, chapterKey: chapter, reduced: reduced, prefsValues: prefs, extra: extra, origin: origin, platform: platform);
      if (art) await loadArt(tester);
      await settleReader(tester, ms: 300);
      if (act != null) await act(tester, rig, wide);
      if (chrome) await showChrome(tester);
      await captureSeriesShot(tester, name, size);
      if (after != null) await after(tester);
      await disposeReader(tester);
    }
  }

  PagedReaderView paged(WidgetTester t) => t.widget<PagedReaderView>(find.byType(PagedReaderView));

  Future<void> key(WidgetTester t, LogicalKeyboardKey k, {int ms = 800, bool shift = false}) async {
    if (shift) await t.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await t.sendKeyEvent(k);
    if (shift) await t.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await settleReader(t, ms: ms);
  }

  Future<void> tab(WidgetTester t, String label) async {
    final f = find.text(label, findRichText: true).last;
    await t.ensureVisible(f);
    await t.pump(const Duration(milliseconds: 300));
    await t.tap(f);
    await settleReader(t, ms: 600);
  }

  const ocr = [
    PageText(page: 1, text: 'You came back.\nWhy?', boxes: [
      OcrTextBox(text: 'You came back.', x: 0.12, y: 0.1, width: 0.5, height: 0.08),
      OcrTextBox(text: 'Why?', x: 0.25, y: 0.42, width: 0.3, height: 0.07),
    ]),
    PageText(page: 3, text: 'The lantern is still lit.', boxes: [OcrTextBox(text: 'The lantern is still lit.', x: 0.2, y: 0.3, width: 0.55, height: 0.08)]),
  ];
  List<Override> withOcr() => [
        ocrChapterTextProvider.overrideWith((ref, id) async => ocr),
        ocrAvailableProvider.overrideWith((ref) async => true),
      ];

  // A 201-chapter series numbered 131..331: the key `c12` is chapter 142, position 12 of 201.
  List<Override> bigSeries() {
    final f = loadSeriesFixture('manga-ongoing');
    final chapters = [
      for (var i = 1; i <= 201; i++)
        SourceChapterSummary(id: 'c$i', sourceId: 'demo', seriesId: 'k', title: 'Chapter ${130 + i}', number: 130.0 + i, pageCount: 6),
    ];
    return [
      sourceSeriesDetailProvider.overrideWith((ref, k) async => SourceSeriesDetailData(series: f.series, chapters: chapters)),
    ];
  }

  Future<void> toChapterEnd(WidgetTester t) async {
    final engine = paged(t).controller;
    engine.jumpToPage(engine.value.pageCount);
    await settleReader(t, ms: 500);
    engine.pageBy(forward: true);
    await settleReader(t, ms: 900);
  }

  testWidgets('mobile-13 paged', (tester) async {
    final single = seed('single');
    await show(tester, 'paged-single', tablet: true, prefs: single);
    await show(tester, 'paged-double', phone: false, tablet: true, prefs: seed('double'), chrome: false);
    await show(tester, 'paged-double-rtl', phone: false, tablet: true, prefs: seed('double', direction: 'rtl'), chrome: false);
    await show(tester, 'paged-zoomed', prefs: single, chrome: false, act: (t, rig, wide) async {
      paged(t).controller.pinchZoom(const Offset(195, 400), 2.2, 0, min: 1, max: 3);
      await t.pump(const Duration(milliseconds: 300));
    });
    await show(tester, 'paged-credits-screen', prefs: single, chrome: false, act: (t, rig, wide) => toChapterEnd(t));
    await show(tester, 'reduced-motion-paged', prefs: single, reduced: true);
  });

  testWidgets('mobile-13 zone bands and K01 toast', (tester) async {
    await show(tester, 'paged-zone-bands', art: false, chrome: false, prefs: seed('single'), act: (t, rig, wide) async {
      await t.pump(const Duration(milliseconds: 100));
    });
    await show(tester, 'k01-toast', art: false, chrome: false, prefs: seed('single', device: {'settings_reading_direction': 'leftToRight', kZonesSeenKey: ['single:previous,menu,next']}), act: (t, rig, wide) async {
      await t.pump(const Duration(milliseconds: 300));
    });
  });

  testWidgets('mobile-13 slide mid-turn', (tester) async {
    await show(tester, 'paged-slide-midturn', prefs: seed('single', more: {'pageTurn': 'slide'}, device: {kZonesSeenKey: ['single:previous,menu,next']}), chrome: false, act: (t, rig, wide) async {
      paged(t).controller.pageBy(forward: true);
      await t.pump();
      await t.pump(const Duration(milliseconds: 130));
    });
  });

  testWidgets('mobile-13 read-all', (tester) async {
    final batch = BatchReader(Recorder());
    List<Override> ra() => [...bigSeries(), readerRepositoryProvider.overrideWithValue(batch)];
    Future<void> settle(WidgetTester t) async {
      await settleReader(t, ms: 1200);
      await loadArt(t);
    }

    await show(tester, 'readall', tablet: true, chapter: 'c12', origin: ReaderRigOrigin.readAll, extra: ra(), artChapters: 14, artFirst: 12, act: (t, rig, wide) => settle(t));
    await show(tester, 'readall-divider', chrome: false, chapter: 'c12', origin: ReaderRigOrigin.readAll, extra: ra(), artChapters: 14, artFirst: 12, act: (t, rig, wide) async {
      await settle(t);
      final p = t.state<ScrollableState>(find.byType(Scrollable).first).position;
      // The end of chapter 142 (six pages of 400 x 600 at the phone's width).
      p.jumpTo(p.pixels + 6 * 585 - 240);
      await settleReader(t, ms: 500);
      await loadArt(t);
    });
    await show(tester, 'readall-ruler-drag', chrome: false, chapter: 'c12', origin: ReaderRigOrigin.readAll, extra: ra(), artChapters: 14, artFirst: 12, act: (t, rig, wide) async {
      await settle(t);
      await showChrome(t);
      final ruler = find.bySemanticsLabel('Page position');
      final r = t.getRect(ruler);
      final g = await t.startGesture(Offset(r.left + 6, r.center.dy));
      await g.moveTo(Offset(r.left + r.width * 0.11, r.center.dy));
      await t.pump(const Duration(milliseconds: 200));
      // hold the drag for the capture: the gesture is released when the test ends
      addTearDown(g.up);
    });
    final failing = BatchReader(Recorder(), failKeys: {'c13'});
    await show(tester, 'readall-chapter-failed', chrome: false, chapter: 'c12', origin: ReaderRigOrigin.readAll, extra: [...bigSeries(), readerRepositoryProvider.overrideWithValue(failing)], artChapters: 14, artFirst: 12, act: (t, rig, wide) async {
      await settle(t);
      t.widget<ReaderEngineView>(find.byType(ReaderEngineView)).controller.seekToChapter(1);
      await settleReader(t, ms: 7000);
    });
    await show(tester, 'readall-list-failed', art: false, chapter: 'c1', origin: ReaderRigOrigin.readAll, extra: [sourceSeriesDetailProvider.overrideWith((ref, k) async => throw Exception('no list'))], chrome: false, act: (t, rig, wide) => settleReader(t, ms: 9000));
  });

  testWidgets('mobile-13 setup sheet', (tester) async {
    Future<void> open(WidgetTester t) async {
      await key(t, LogicalKeyboardKey.comma, ms: 1200);
    }

    await show(tester, 'setup-layout', chrome: false, act: (t, rig, wide) => open(t));
    await show(tester, 'setup-image', chrome: false, act: (t, rig, wide) async {
      await open(t);
      await tab(t, 'IMAGE');
    });
    await show(tester, 'setup-controls', tablet: true, chrome: false, act: (t, rig, wide) async {
      await open(t);
      await tab(t, 'CONTROLS');
    });
    await show(tester, 'setup-ambient', chrome: false, act: (t, rig, wide) async {
      await open(t);
      await tab(t, 'AMBIENT');
    });
    await show(tester, 'setup-controls-ios', chrome: false, platform: TargetPlatform.iOS, act: (t, rig, wide) async {
      await open(t);
      await tab(t, 'CONTROLS');
    });
    await show(tester, 'setup-reset-arming', chrome: false, act: (t, rig, wide) async {
      await open(t);
      await t.drag(find.text('READING SETUP', findRichText: true), const Offset(0, -400));
      await t.pump(const Duration(milliseconds: 700));
      final reset = find.text('Reset reader settings', findRichText: true);
      await t.ensureVisible(reset);
      await t.pump(const Duration(milliseconds: 300));
      await t.tap(reset);
      await t.pump(const Duration(milliseconds: 700));
    });
  });

  testWidgets('mobile-13 margins', (tester) async {
    final circle = circleSeriesProvider.overrideWith(
      (ref, k) async => const CircleSeriesData(
        readers: [
          CircleReader(member: CircleMemberRef(profileId: 1, name: 'Asha', avatarKey: 'matinee'), chapterKey: 'c2', chapterNumber: 2),
          CircleReader(member: CircleMemberRef(profileId: 2, name: 'Riya', avatarKey: 'lantern'), chapterKey: 'c3', chapterNumber: 3),
          CircleReader(member: CircleMemberRef(profileId: 3, name: 'Dev', avatarKey: 'slate'), chapterKey: 'c2', chapterNumber: 2),
        ],
        chapters: [
          CircleChapterReactions(chapterKey: 'c2', chapterNumber: 2, by: [ReactionBy(profileId: 1, name: 'Asha', kind: ReactionKind.chefsKiss)]),
          CircleChapterReactions(chapterKey: 'c3', chapterNumber: 3, by: [ReactionBy(profileId: 2, name: 'Riya', kind: ReactionKind.tears)]),
        ],
      ),
    );
    Future<void> margins(WidgetTester t, String? tabLabel) async {
      await key(t, LogicalKeyboardKey.bracketRight, ms: 1000);
      if (tabLabel != null) await tab(t, tabLabel);
    }

    await show(tester, 'margins-notes', phone: false, tablet: true, chrome: false, extra: [...withOcr(), circle], act: (t, rig, wide) => margins(t, null));
    await show(tester, 'margins-dialogue', phone: false, tablet: true, chrome: false, extra: [...withOcr(), circle], act: (t, rig, wide) => margins(t, 'DIALOGUE'));
    await show(tester, 'margins-circle-guarded', phone: false, tablet: true, chrome: false, extra: [...withOcr(), circle], act: (t, rig, wide) => margins(t, 'CIRCLE'));
  });

  testWidgets('mobile-13 page actions', (tester) async {
    await show(tester, 'page-actions-sheet', chrome: false, extra: withOcr(), act: (t, rig, wide) async {
      await t.longPressAt(const Offset(195, 400));
      await settleReader(t, ms: 1400);
    });
    await show(tester, 'page-dialogue-outlines', chrome: false, extra: withOcr(), act: (t, rig, wide) async {
      await key(t, LogicalKeyboardKey.f10, shift: true, ms: 1200);
      await t.tap(find.text('Show dialogue on this page', findRichText: true));
      await settleReader(t, ms: 900);
    });
    await show(tester, 'page-lightbox', chrome: false, act: (t, rig, wide) async {
      await key(t, LogicalKeyboardKey.f10, shift: true, ms: 1200);
      await t.tap(find.text('Open page image', findRichText: true));
      await settleReader(t, ms: 1200);
      await loadArt(t);
    });
  });

  testWidgets('mobile-13 entries and legacy', (tester) async {
    final batch = BatchReader(Recorder());
    await show(tester, 'entry-follow-readall', chapter: 'c1', origin: ReaderRigOrigin.readAll, extra: [readerRepositoryProvider.overrideWithValue(batch)], act: (t, rig, wide) => settleReader(t, ms: 1200));
    await show(tester, 'entry-source-readall', chapter: 'c1', origin: ReaderRigOrigin.readAll, extra: [readerRepositoryProvider.overrideWithValue(batch)], act: (t, rig, wide) => settleReader(t, ms: 1200));
    await show(tester, 'entry-follow-paged', prefs: seed('single'));
    await show(tester, 'entry-source-paged', prefs: seed('single'), origin: ReaderRigOrigin.source);
    await show(tester, 'legacy-horizontal-strip', origin: ReaderRigOrigin.legacy, prefs: {'settings_reading_direction': legacyDirection('leftToRight')});
  });
}
