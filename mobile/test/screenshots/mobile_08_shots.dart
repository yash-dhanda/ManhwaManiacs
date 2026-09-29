// ignore_for_file: require_trailing_commas, directives_ordering
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/diagnostics/debug_overlays.dart';
import 'package:manhwamaniacs/core/time/clock.dart';
import 'package:manhwamaniacs/features/home/models/home_feed.dart';
import 'package:manhwamaniacs/features/home/providers/home_feed_provider.dart';
import 'package:manhwamaniacs/features/home/utils/at_risk.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/gallery/primitives_gallery.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/layout/cine_grid_overlay.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/tonight/tonight_screen.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/skins.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../skins/cinematic/feature/feature_test_support.dart' show featureTheme;
import '../skins/cinematic/tonight/tonight_test_support.dart';
import 'support/series_shots.dart';
import 'support/shot_covers.dart';
import 'support/shot_harness.dart';
import 'support/shot_network.dart';
import 'support/skin_shots.dart';

const _stamp = {'mm.tonight.typed.u1p1': '{"date":"2026-09-30","variant":"normal"}'};

/// Every cover path of the Tonight fixtures, painted in-repo (the repository is public: no real
/// series, cover or account ever appears here).
Map<String, List<String>> _coverTitles() {
  final out = <String, List<String>>{};
  void walk(Object? j) {
    if (j is Map<String, dynamic>) {
      final cover = j['cover_url'];
      if (cover is String && cover.startsWith('/sources/')) out[cover] = [(j['title'] as String?) ?? cover.split('/')[4]];
      j.values.forEach(walk);
    } else if (j is List<dynamic>) {
      j.forEach(walk);
    } else if (j is String && j.startsWith('/sources/') && j.endsWith('/cover')) {
      out.putIfAbsent(j, () => [j.split('/')[4]]);
    }
  }

  for (final f in Directory('test/fixtures/home').listSync().whereType<File>()) {
    walk(jsonDecode(f.readAsStringSync()));
  }
  return out;
}

/// The mobile-08 proof shots: Tonight, Cinematic, at `kSkinShotSizes`, invented fixtures only.
void mobile08Shots() {
  Future<void> addCovers(WidgetTester tester) async {
    final covers = _coverTitles();
    var seed = 0;
    final png = <String, Uint8List>{};
    for (final e in covers.entries) {
      final title = e.value.first.replaceAll('-', ' ');
      final bytes = await tester.runAsync(() => ShotCoverArt(title: title, seed: seed++).toPng(width: 480, height: 720));
      png[e.key] = bytes!;
    }
    addShotCovers(png);
  }

  List<Override> feedOverrides(HomeFeedView? view, {Future<void>? hold, DateTime? now}) => [
        clockProvider.overrideWithValue(() => now ?? kTonightNow),
        homeFeedProvider.overrideWith(() => FakeHomeFeed(view, hold: hold)),
      ];

  /// The app frame at `/` (thumb index, running head), as the owner sees Tonight.
  testWidgets('mobile-08 tonight in the app frame', (tester) async {
    await addCovers(tester);
    for (final size in kSkinShotSizes) {
      await captureSkinScreen(
        tester,
        skin: SkinId.cinematic,
        screen: ScreenId.tonight,
        size: size,
        overrides: [...feedOverrides(viewOf(loadFeed('ready'))), sharedPrefsProvider.overrideWithValue(await _prefs())],
      );
      await pumpUntilCoversLoad(tester, rounds: 3);
    }
  });

  Future<void> host(
    WidgetTester tester,
    String name,
    HomeFeedView? view, {
    Future<void>? hold,
    DateTime? now,
    bool reduced = false,
    double textScale = 1,
    bool phone = true,
    bool tablet = true,
    bool grid = false,
    bool novel = false,
    Duration settle = const Duration(seconds: 4),
    Future<void> Function(WidgetTester t, bool wide)? drive,
  }) async {
    await addCovers(tester);
    for (final (size, wide, on) in [(kSkinShotSizes[0], false, phone), (kSkinShotSizes[1], true, tablet)]) {
      if (!on) continue;
      await captureSkinWidget(
        tester,
        name: name,
        size: size,
        disableAnimations: reduced,
        textScale: textScale,
        overrides: [
          ...feedOverrides(view, hold: hold, now: now),
          sharedPrefsProvider.overrideWithValue(await _prefs()),
          if (grid) layoutGridOverlayProvider.overrideWith((ref) => true),
        ],
        child: Stack(children: [
          MaterialApp(debugShowCheckedModeBanner: false, theme: featureTheme(TargetPlatform.android), home: const TonightScreen()),
          if (grid) const Positioned.fill(child: CineGridOverlay()),
        ]),
        settle: (t) async {
          await pumpUntilCoversLoad(t, rounds: 3);
          await settleTonight(t, by: settle);
          if (drive != null) await drive(t, wide);
        },
      );
    }
  }

  testWidgets('mobile-08 ready', (t) async => host(t, 'tonight', viewOf(loadFeed('ready'))));
  testWidgets('mobile-08 grid', (t) async => host(t, 'tonight-grid', viewOf(loadFeed('ready')), grid: true));
  testWidgets('mobile-08 loading', (t) async => host(t, 'tonight-loading', null, hold: Completer<void>().future, settle: const Duration(seconds: 1)));
  testWidgets('mobile-08 new profile', (t) async => host(t, 'tonight-new-profile', viewOf(loadFeed('new-profile'))));
  testWidgets('mobile-08 onboarded', (t) async => host(t, 'tonight-onboarded', viewOf(loadFeed('onboarded'))));
  testWidgets('mobile-08 caught up', (t) async => host(t, 'tonight-caught-up', viewOf(loadFeed('caught-up'))));
  testWidgets('mobile-08 at risk', (t) async {
    final now = DateTime.utc(2026, 9, 30, 20, 30);
    await host(t, 'tonight-at-risk', viewOf(applyAtRisk(loadFeed('at-risk'), now)), now: now);
  });
  testWidgets('mobile-08 ai unavailable', (t) async => host(t, 'tonight-ai-unavailable', viewOf(loadFeed('ai-unavailable'))));
  testWidgets('mobile-08 stale', (t) async => host(t, 'tonight-stale', viewOf(loadFeed('stale'))));
  testWidgets('mobile-08 offline', (t) async {
    final f = loadFeed('ready').copyWith(headline: 'Offline edition.', deck: "Only what's saved on this device is here.", also: const [], sections: [
      const HomeSection(type: HomeSectionType.saved, title: 'Saved on this device', items: [
        HomeSavedItem(sourceId: 'shelf', seriesKey: 'iron-kite', title: 'Iron Kite', chapters: 3, coverUrl: '/sources/shelf/series/iron-kite/cover'),
        HomeSavedItem(sourceId: 'shelf', seriesKey: 'moonlit-bakery', title: 'Moonlit Bakery', chapters: 5, coverUrl: '/sources/shelf/series/moonlit-bakery/cover'),
      ]),
      loadFeed('ready').section(HomeSectionType.continueReading)!.copyWith(title: 'Continue (saved chapters)'),
    ]);
    await host(t, 'tonight-offline', viewOf(f, origin: HomeFeedOrigin.offline, offline: true), settle: const Duration(seconds: 5));
  });
  testWidgets('mobile-08 error', (t) async => host(t, 'tonight-error', null));
  testWidgets('mobile-08 novel', (t) async => host(t, 'tonight-novel', viewOf(loadFeed('novel'))));
  testWidgets('mobile-08 reduced motion', (t) async => host(t, 'tonight-reduced-motion', viewOf(loadFeed('ready')), reduced: true, tablet: false, settle: const Duration(milliseconds: 500)));
  testWidgets('mobile-08 text 2.0', (t) async => host(t, 'tonight-text-2.0', viewOf(loadFeed('ready')), textScale: 2.0, tablet: false));

  ScrollPosition position(WidgetTester t) =>
      t.state<ScrollableState>(find.descendant(of: find.byType(CustomScrollView), matching: find.byType(Scrollable)).first).position;

  testWidgets('mobile-08 trailer scrub half', (t) async {
    await host(t, 'tonight-scrub-half', viewOf(loadFeed('ready')), tablet: false, drive: (t, wide) async {
      position(t).jumpTo((487.5 - 64 - 240) + 120);
      await t.pump();
      await t.pump(const Duration(milliseconds: 50));
    });
  });

  testWidgets('mobile-08 trailer scrubbed', (t) async {
    await host(t, 'tonight-scrubbed', viewOf(loadFeed('ready')), drive: (t, wide) async {
      position(t).jumpTo((wide ? 820.0 : 487.5) - (wide ? 24.0 : 47.0) + 90);
      await t.pump();
      await t.pump(const Duration(milliseconds: 50));
    });
  });

  testWidgets('mobile-08 also pager', (t) async {
    await host(t, 'tonight-also-pager', viewOf(loadFeed('ready')), tablet: false, drive: (t, wide) async {
      position(t).jumpTo(380);
      await t.pump();
      await t.pump(const Duration(milliseconds: 100));
    });
  });

  testWidgets('mobile-08 quick look', (t) async {
    await host(t, 'tonight-quick-look', viewOf(loadFeed('ready')), tablet: false, drive: (t, wide) async {
      position(t).jumpTo(700);
      await t.pump();
      await settleTonight(t, by: const Duration(seconds: 2));
      final target = find.textContaining('CH 142');
      if (target.evaluate().isNotEmpty) {
        await t.longPress(target.first);
        await settleTonight(t, by: const Duration(seconds: 1));
      }
    });
  });

  testWidgets('mobile-08 lightbox', (t) async {
    await host(t, 'tonight-lightbox', viewOf(loadFeed('ready')), tablet: false, drive: (t, wide) async {
      await t.sendKeyEvent(LogicalKeyboardKey.keyV);
      await pumpUntilCoversLoad(t, rounds: 3);
      await settleTonight(t, by: const Duration(seconds: 1));
    });
  });

  testWidgets('mobile-08 streak flame gallery', (t) async {
    await addCovers(t);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final size = kSkinShotSizes.first;
    t.view.physicalSize = size.logical;
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(ProviderScope(
      overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
      child: RepaintBoundary(key: kSkinShotKey, child: const CinePrimitivesGalleryPage(section: 'streak-flame')),
    ));
    await t.pump(const Duration(milliseconds: 600));
    await captureSeriesShotPlain(t, 'streak-flame-gallery');
    await t.pumpWidget(const SizedBox());
  });
}

Future<SharedPreferences> _prefs() async {
  SharedPreferences.setMockInitialValues(_stamp);
  return SharedPreferences.getInstance();
}
