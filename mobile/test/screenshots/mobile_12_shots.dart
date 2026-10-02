// ignore_for_file: require_trailing_commas, directives_ordering
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/features/reader/providers/reader_ui_provider.dart';
import 'package:manhwamaniacs/features/reader/utils/reader_prefs_migration.dart';
import 'package:manhwamaniacs/features/sources/models/source.dart';
import 'package:manhwamaniacs/features/sources/providers/sources_provider.dart';

import '../skins/cinematic/reader/reader_test_support.dart';
import 'support/series_shots.dart';
import 'support/shot_covers.dart';
import 'support/shot_network.dart';
import 'support/skin_shots.dart';

/// The mobile-12 proof shots: the Cinematic manga reader at `kSkinShotSizes`, with invented
/// fixtures only (procedural page art, never a source's pages).
void mobile12Shots() {
  Future<void> addPages(WidgetTester tester, {int pages = 6}) async {
    final png = await tester.runAsync(() async => {
          for (final (i, c) in ['c1', 'c2', 'c3', 'cx'].indexed)
            for (var n = 1; n <= pages; n++)
              '/reader/page/$c-$n/image': await ShotCoverArt(title: 'Tower of Dawn', seed: n + i * 2).toPng(width: 400, height: 1200),
        });
    addShotCovers(png!);
  }

  // The page art is fetched, written to the cache and decoded on real time.
  Future<void> loadArt(WidgetTester tester) async {
    await pumpUntilCoversLoad(tester, rounds: 12);
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 800)));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
  }

  // Loading the art takes longer than the chrome's 3 s idle, so the chrome is brought back last.
  Future<void> showChrome(WidgetTester tester) async {
    if (find.byType(Scrollable).evaluate().isEmpty || chromeVisible(tester)) return;
    await tapMenu(tester);
  }

  Future<void> toEnd(WidgetTester tester) async {
    for (var i = 0; i < 3; i++) {
      final position = tester.state<ScrollableState>(find.byType(Scrollable).first).position;
      position.jumpTo(position.maxScrollExtent);
      await settleReader(tester, ms: 500);
    }
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 600)));
    await tester.pump(const Duration(milliseconds: 300));
    final position = tester.state<ScrollableState>(find.byType(Scrollable).first).position;
    position.jumpTo(position.maxScrollExtent);
    await tester.pump(const Duration(milliseconds: 300));
  }

  ScrollPosition position(WidgetTester tester) => tester.state<ScrollableState>(find.byType(Scrollable).first).position;

  /// Renders one state at the phone and/or tablet size and captures it as `<name>-<size>.png`.
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
    Map<String, Object> failing = const {},
    bool hold = false,
    String? holdChapter,
    String? status,
    List<Override> extra = const [],
    ReaderRigOrigin origin = ReaderRigOrigin.manifest,
    String pageBase = 'reader/page',
    Future<void> Function(WidgetTester tester, ReaderRig rig, bool wide)? act,
  }) async {
    for (final (size, wide, on) in [
      (kSkinShotSizes[0], false, phone),
      (kSkinShotSizes[1], true, tablet),
    ]) {
      if (!on) continue;
      if (art) await addPages(tester);
      final gate = Completer<void>();
      final rig = await pumpReader(
        tester,
        wide: wide,
        chapterKey: chapter,
        reduced: reduced,
        prefsValues: prefs,
        failing: failing,
        holds: hold ? {holdChapter ?? chapter: gate.future} : const {},
        status: status,
        extra: extra,
        origin: origin,
        pageBase: pageBase,
      );
      if (art) await loadArt(tester);
      await settleReader(tester, ms: 300);
      if (act != null) await act(tester, rig, wide);
      if (chrome) await showChrome(tester);
      await captureSeriesShot(tester, name, size);
      if (!gate.isCompleted) gate.complete();
      await disposeReader(tester);
    }
  }

  Map<String, Object> seed(Map<String, Object> m) => {kReaderPrefsSeedKey: jsonEncode(m)};

  testWidgets('mobile-12 reader chrome', (tester) async {
    await show(tester, 'reader-chrome', tablet: true);
  });

  testWidgets('mobile-12 reader hidden', (tester) async {
    await show(tester, 'reader-hidden', chrome: false, act: (t, rig, wide) async {
      if (chromeVisible(t)) await tapMenu(t);
      await t.pump(const Duration(milliseconds: 400));
    });
  });

  testWidgets('mobile-12 landscape chrome', (tester) async {
    await addPages(tester);
    await pumpReader(tester, size: kSkinShotLandscape.logical);
    await loadArt(tester);
    await showChrome(tester);
    await captureSeriesShotPlain(tester, 'reader-landscape-chrome');
    await disposeReader(tester);
  });

  testWidgets('mobile-12 wipe hold', (tester) async {
    for (final (size, wide, target) in [(kSkinShotSizes[0], false, 268), (kSkinShotSizes[1], true, 332)]) {
      await addPages(tester);
      final started = DateTime.now();
      await pumpReader(tester, wide: wide, cineRoute: true, pushExtra: {'entry': 'wipe'});
      // pumpReader has run the route for about 200 ms; bring it to the 40 ms hold.
      await tester.pump(Duration(milliseconds: target - 200));
      await captureSeriesShot(tester, 'reader-wipe-hold', size);
      await tester.pump(const Duration(seconds: 2));
      await disposeReader(tester);
      expect(DateTime.now().difference(started).inSeconds, lessThan(60));
    }
  });

  testWidgets('mobile-12 contents', (tester) async {
    await show(tester, 'reader-contents-sheet', act: (t, rig, wide) async {
      await t.sendKeyEvent(LogicalKeyboardKey.bracketLeft);
      await settleReader(t, ms: 900);
    });
    await show(tester, 'reader-contents-panel', phone: false, tablet: true, act: (t, rig, wide) async {
      await t.sendKeyEvent(LogicalKeyboardKey.bracketLeft);
      await settleReader(t, ms: 900);
    });
  });

  testWidgets('mobile-12 jump field', (tester) async {
    await show(tester, 'reader-jump-field', act: (t, rig, wide) async {
      await t.sendKeyEvent(LogicalKeyboardKey.keyG);
      await settleReader(t, ms: 500);
    });
  });

  testWidgets('mobile-12 zoom chip', (tester) async {
    await show(tester, 'reader-zoom-chip', act: (t, rig, wide) async {
      for (var i = 0; i < 10; i++) {
        await t.sendKeyEvent(LogicalKeyboardKey.equal);
        await t.pump(const Duration(milliseconds: 20));
      }
      await t.pump(const Duration(milliseconds: 300));
    });
  });

  testWidgets('mobile-12 brightness hud', (tester) async {
    await show(tester, 'reader-brightness-hud', act: (t, rig, wide) async {
      final g = await t.startGesture(const Offset(12, 300));
      for (var i = 0; i < 8; i++) {
        await g.moveBy(const Offset(0, 22));
        await t.pump(const Duration(milliseconds: 16));
      }
      await t.pump(const Duration(milliseconds: 250));
      await g.up();
    });
  });

  testWidgets('mobile-12 seam and top band', (tester) async {
    await show(tester, 'reader-seam', act: (t, rig, wide) async {
      final p = position(t);
      p.jumpTo(p.pixels - 380);
      await settleReader(t, ms: 400);
      await loadArt(t);
    });
    await show(tester, 'reader-top-band', act: (t, rig, wide) async {
      position(t).jumpTo(0);
      await settleReader(t, ms: 600);
    });
  });

  testWidgets('mobile-12 credits', (tester) async {
    Future<void> end(WidgetTester t, ReaderRig rig, bool wide) => toEnd(t);
    await show(tester, 'reader-credits-compact', chapter: 'c3', hold: true, holdChapter: 'cx', act: end);
    await show(tester, 'reader-credits-full', tablet: true, chrome: false, chapter: 'c3', hold: true, holdChapter: 'cx', prefs: seed({'autoNextChapter': false}), act: end);
  });

  testWidgets('mobile-12 caught up and the end', (tester) async {
    await show(tester, 'reader-caught-up', chapter: 'cx', chrome: false, act: (t, rig, wide) => toEnd(t));
    await show(tester, 'reader-the-end', chapter: 'cx', status: 'Completed', chrome: false, act: (t, rig, wide) => toEnd(t));
  });

  testWidgets('mobile-12 loading and broken page', (tester) async {
    await show(tester, 'reader-loading', art: false, hold: true);
    await show(tester, 'reader-broken-page', art: false, pageBase: 'gone/page', act: (t, rig, wide) async {
      await pumpUntilCoversLoad(t, rounds: 14);
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 500)));
      await t.pump(const Duration(milliseconds: 300));
    });
  });

  testWidgets('mobile-12 rate limited', (tester) async {
    await show(tester, 'reader-rate-limited',
        failing: {'c3': const ApiError(statusCode: 429, code: 'rate_limited', message: 'slow', retryAfter: Duration(seconds: 12))},
        act: (t, rig, wide) => toEnd(t));
  });

  testWidgets('mobile-12 not available', (tester) async {
    await show(tester, 'reader-not-available',
        art: false, failing: {'c2': const ApiError(statusCode: 404, code: 'series_not_found', message: 'gone')});
  });

  testWidgets('mobile-12 rating card', (tester) async {
    await show(tester, 'reader-rating-card', art: false, extra: [
      sourcesListProvider.overrideWith((ref) async => const [
            SourceSummary(id: 'demo', name: 'Demo Source', description: 'x', browsable: true, supportsImport: false, mature: true),
          ]),
    ]);
  });

  testWidgets('mobile-12 locked toast', (tester) async {
    await show(tester, 'reader-locked-toast', act: (t, rig, wide) async {
      ProviderScope.containerOf(t.element(find.byType(MaterialApp))).read(readerUiProvider.notifier).setLocked(true);
      await t.pump(const Duration(milliseconds: 300));
      for (var i = 0; i < 5; i++) {
        await tapSingle(t);
      }
      await t.pump(const Duration(milliseconds: 300));
    });
  });

  testWidgets('mobile-12 reduced motion', (tester) async {
    await show(tester, 'reader-reduced-motion', reduced: true);
  });

  testWidgets('mobile-12 legacy edition', (tester) async {
    await show(tester, 'reader-legacy', origin: ReaderRigOrigin.legacy);
  });

  testWidgets('mobile-12 entries', (tester) async {
    await show(tester, 'entry-follow');
    await show(tester, 'entry-source', origin: ReaderRigOrigin.source);
  });
}
