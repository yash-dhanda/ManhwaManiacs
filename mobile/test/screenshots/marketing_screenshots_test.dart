@Tags(['screenshots'])
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/app/theme/app_theme.dart';
import 'package:manhwamaniacs/app/theme/preset_controller.dart';
import 'package:manhwamaniacs/app/theme/theme_controller.dart';
import 'package:manhwamaniacs/core/diagnostics/debug_overlays.dart';
import 'package:manhwamaniacs/features/content_mode/content_mode.dart';
import 'package:manhwamaniacs/features/library/models/library_statistics.dart';
import 'package:manhwamaniacs/features/library/providers/intelligence_providers.dart';
import 'package:manhwamaniacs/features/library/screens/dashboard_screen.dart';
import 'package:manhwamaniacs/features/library/screens/statistics_screen.dart';
import 'package:manhwamaniacs/features/settings/screens/theme_gallery_screen.dart';
import 'package:manhwamaniacs/features/sources/models/source.dart';
import 'package:manhwamaniacs/features/sources/providers/sources_provider.dart';
import 'package:manhwamaniacs/features/updates/models/update_notification.dart';
import 'package:manhwamaniacs/features/updates/providers/updates_provider.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/gallery/overlays_gallery.dart';
import 'package:manhwamaniacs/skins/cinematic/gallery/primitives_gallery.dart';
import 'package:manhwamaniacs/skins/skins.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/test_overrides.dart';
import 'mobile_05_shots.dart';
import 'mobile_06_shots.dart';
import 'mobile_07_shots.dart';
import 'mobile_08_shots.dart';
import 'mobile_09_shots.dart';
import 'mobile_10_shots.dart';
import 'mobile_11_shots.dart';
import 'mobile_12_shots.dart';
import 'mobile_13_shots.dart';
import 'mobile_14_shots.dart';
import 'mobile_15_shots.dart';
import 'support/mobile21_shots.dart';
import 'support/shot_covers.dart';
import 'support/shot_fixtures.dart';
import 'support/shot_harness.dart';
import 'support/shot_network.dart';
import 'support/skin_shots.dart';

/// Regenerates the marketing screenshots served on the install page.
///
/// Run it deliberately:
///
/// ```sh
/// cd mobile
/// MM_WRITE_SHOTS=1 flutter test test/screenshots/marketing_screenshots_test.dart
/// ```
///
/// Without `MM_WRITE_SHOTS` the same screens are still built, pumped and
/// rasterised — so a screen that stops rendering fails here — but nothing is
/// written, which keeps an ordinary `flutter test` from dirtying the working
/// tree.
///
/// Output lands in `mobile/docs/screenshots/`, which the deploy mounts into
/// the backend container and `backend/routes/app_distribution.py` serves under
/// `/app/media`. The filenames are load-bearing: the `_SHOWCASE` list in that
/// file names each one, and its captions describe these exact frames.
///
/// Everything on screen comes from `support/shot_fixtures.dart` and
/// `support/shot_covers.dart` — invented series, cover art painted in-repo.
/// That is a requirement, not a shortcut: the install page is public and the
/// app carries mature sources, so no real source, series or artwork may reach
/// it. Fixtures make that a property of the code rather than a promise.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadAppFonts);
  setUpAll(setUpShotCoverCache);

  // mobile-11: the Cinematic series page, Book page and chapter downloads.
  group('mobile-15', mobile15Shots);
  group('mobile-14', mobile14Shots);
  group('mobile-13', mobile13Shots);
  group('mobile-12', mobile12Shots);
  group('mobile-11', mobile11Shots);
  group('mobile-05', mobile05Shots);
  group('mobile-06', mobile06Shots);
  group('mobile-07', mobile07Shots);
  group('mobile-08', mobile08Shots);
  group('mobile-09', mobile09Shots);
  group('mobile-10', mobile10Shots);
  // Both skins at every proof size (mobile/03). Default: Tonight only, so the
  // plain suite stays fast; a proof run sets MM_PROOF_SCREENS and MM_PROOF_DIR.
  group('mobile-21', mobile21Group);

  group('skins', () {
    for (final skin in [SkinId.cinematic, SkinId.glass]) {
      for (final size in kSkinShotSizes) {
        for (final screen in proofScreens) {
          testWidgets('${skin.name} ${screen.id} ${size.name}', (tester) async {
            await captureSkinScreen(tester, skin: skin, screen: screen, size: size);
          });
        }
      }
    }

    testWidgets('captureSkinWidget writes <name>-<size>.png', (tester) async {
      final dir = Directory.systemTemp.createTempSync('mm-skinshot-');
      addTearDown(() => dir.deleteSync(recursive: true));
      await captureSkinWidget(
        tester,
        name: 'plain',
        size: kSkinShotSizes.first,
        child: const ColoredBox(color: Color(0xFF123456)),
        proofDirOverride: dir.path,
      );
      expect(File('${dir.path}/plain-phone.png').existsSync(), isTrue);
    });
  });


  // Cinematic primitives gallery (mobile/04): one capture per section, grid off and on, plus
  // reduced-motion and text-scale-2 variants of the four sections that reflow or animate most.
  group('mobile-04', () {
    const heights = {
      'buttons': 1500.0,
      'icon-buttons': 900.0,
      'fields': 1700.0,
      'search': 500.0,
      'slug-lines': 900.0,
      'cards': 3600.0,
      'posters': 2200.0,
      'rails': 2400.0,
      'galleys': 800.0,
      'progress': 1500.0,
      'badges': 500.0,
      'avatars': 800.0,
      'keycaps': 300.0,
      'masthead': 1100.0,
      'layout': 1900.0,
      'grain-duotone': 700.0,
      'reveals': 1000.0,
      // mobile-08: the streak flame in every tier and state.
      'streak-flame': 900.0,
      'motion-timings': 700.0,
      // mobile-05 sections: captured open by the mobile-05 group; here only their resting page.
      'sheets': 800.0,
      'dialogs': 1000.0,
      'toasts': 700.0,
      'tabs': 900.0,
      'rows': 4200.0,
      'sliders': 900.0,
      'toggles': 1100.0,
      'menus': 700.0,
      'notices': 1900.0,
      'certificate': 700.0,
      'other': 2600.0,
      'lightbox': 500.0,
      // mobile-06: captured by the mobile-06 group; here only their resting page.
      'shell': 6400.0,
      'shell-frames': 2600.0,
      // mobile-07: captured by the mobile-07 group; here only its resting page.
      'auth': 2400.0,
      // mobile-09: the Library's parts (posters, list rows, book rows); the screens are in the mobile-09 group.
      'library': 2600.0,
    };
    const variants = {'buttons', 'fields', 'rails', 'reveals'};
    for (final size in kSkinShotSizes) {
      for (final section in kGallerySections.where((s) => !kOverlayGallerySections.contains(s))) {
        final tall = SkinShotSize(size.name, Size(size.logical.width, heights[section]!), size.pixelRatio, size.padding);
        Future<void> shot(WidgetTester t, String name, {bool grid = false, bool reduced = false, double scale = 1.0, Future<void> Function(WidgetTester)? settle}) =>
            captureSkinWidget(
              t,
              name: name,
              size: tall,
              disableAnimations: reduced,
              textScale: scale,
              settle: settle,
              overrides: [if (grid) layoutGridOverlayProvider.overrideWith((ref) => true)],
              child: MaterialApp(debugShowCheckedModeBanner: false, home: CinePrimitivesGalleryPage(section: section)),
            );
        testWidgets('mobile-04 $section ${size.name}', (t) => shot(t, section));
        testWidgets('mobile-04 $section grid ${size.name}', (t) => shot(t, '$section-grid', grid: true));
        if (variants.contains(section)) {
          testWidgets('mobile-04 $section reduced ${size.name}', (t) => shot(t, '$section-reduced', reduced: true));
          testWidgets('mobile-04 $section scale2 ${size.name}', (t) => shot(t, '$section-scale2', scale: 2.0));
        }
        if (section == 'reveals') {
          testWidgets('mobile-04 reveals mid-reveal ${size.name}', (t) => shot(t, 'reveals-mid400', settle: (t) async {
                await t.pump();
                await t.pump(const Duration(milliseconds: 400));
              },),);
        }
      }
    }
  });

  testWidgets('library — the followed shelf', (tester) async {
    useShotViewport(tester);
    await paintCovers(tester, shotManga);
    final prefs = await shotPrefs();

    final key = GlobalKey();
    await tester.pumpWidget(
      _shotApp(
        key: key,
        overrides: [
          sharedPrefsProvider.overrideWithValue(prefs),
          ...contentModeOverrides(),
          _shelfSource(novels: false),
          _followedOverride(shotManga),
        ],
        child: const DashboardScreen(),
      ),
    );
    await settleShot(tester);
    await pumpUntilCoversLoad(tester);
    await settleShot(tester);

    expect(find.text('The Lantern Courier'), findsOneWidget);
    expect(find.text('9 series followed'), findsOneWidget);
    await maybeWriteShot(tester, find.byKey(key), 'shot-library.png');
    await drainCacheTimers(tester);
  });

  testWidgets('novels — the same library, as books', (tester) async {
    useShotViewport(tester);
    await paintCovers(tester, shotNovels);
    final prefs = await shotPrefs();

    final key = GlobalKey();
    await tester.pumpWidget(
      _shotApp(
        key: key,
        overrides: [
          sharedPrefsProvider.overrideWithValue(prefs),
          ...contentModeOverrides(
            mode: ContentMode.novel,
            novelsEnabled: true,
          ),
          _shelfSource(novels: true),
          _followedOverride(shotNovels),
        ],
        child: const DashboardScreen(),
      ),
    );
    await settleShot(tester);
    // Twice: the shelf only exists once the content-mode scope has resolved,
    // so the first pass is spent getting the rows built, not their covers.
    await pumpUntilCoversLoad(tester);
    await settleShot(tester);
    await pumpUntilCoversLoad(tester);
    await settleShot(tester);

    expect(find.text('The Salt Road Chronicles'), findsOneWidget);
    await maybeWriteShot(tester, find.byKey(key), 'shot-novels.png');
    await drainCacheTimers(tester);
  });

  testWidgets('statistics — what the reading actually looks like',
      (tester) async {
    useShotViewport(tester);
    await paintCovers(tester, shotManga);
    final prefs = await shotPrefs();

    final key = GlobalKey();
    await tester.pumpWidget(
      _shotApp(
        key: key,
        overrides: [
          sharedPrefsProvider.overrideWithValue(prefs),
          statisticsProvider.overrideWith((ref) async => shotStatistics()),
        ],
        child: const StatisticsScreen(),
      ),
    );
    await settleShot(tester);
    // "Most read" carries covers, and so brings the cache manager (and its
    // deferred cleanup timer) with it.
    await pumpUntilCoversLoad(tester);
    await settleShot(tester);

    expect(find.textContaining('day'), findsWidgets);
    await maybeWriteShot(tester, find.byKey(key), 'shot-statistics.png');
    await drainCacheTimers(tester);
  });

  testWidgets('themes — the palette gallery', (tester) async {
    useShotViewport(tester);
    final prefs = await shotPrefs();

    final key = GlobalKey();
    await tester.pumpWidget(
      _shotApp(
        key: key,
        overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
        child: const ThemeGalleryScreen(),
      ),
    );
    await settleShot(tester);

    expect(find.text('DARK'), findsOneWidget);
    await maybeWriteShot(tester, find.byKey(key), 'shot-themes.png');
  });
}

/// The app the shots are taken inside — a real `MaterialApp` wearing the real
/// theme, rebuilt from the theme and preset controllers exactly as
/// `ManhwaManiacsApp` wires them, wrapped in the boundary the capture reads.
Widget _shotApp({
  required GlobalKey key,
  required List<Override> overrides,
  required Widget child,
}) {
  return RepaintBoundary(
    key: key,
    child: ProviderScope(
      overrides: [
        apiBaseUrlOverride(shotBaseUrl),
        authenticatedAuthOverride(),
        activeProfileOverride(),
        profileSessionReadyOverride(),
        ...overrides,
      ],
      child: Consumer(
        builder: (context, ref, _) => MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.fromPalette(
            ref.watch(themeControllerProvider),
            metrics: ref.watch(presetControllerProvider),
          ),
          home: child,
        ),
      ),
    ),
  );
}

/// The one source the fixture library is followed from.
///
/// Stubbed even in manga mode: with the novels gate open, `ContentModeScope`
/// builds its manga/novel index from a real `/sources` call otherwise, and a
/// follow row carries a source id but no kind — so this listing is what makes
/// the novel fixtures novels.
Override _shelfSource({required bool novels}) =>
    sourcesListProvider.overrideWith(
      (ref) async => [
        SourceSummary(
          id: 'shelf',
          name: 'Shelf',
          description: '',
          browsable: true,
          supportsImport: false,
          contentKind: novels ? kNovelContentKind : kMangaContentKind,
        ),
      ],
    );

Override _followedOverride(List<ShotSeries> series) =>
    updatesProvider.overrideWith(
      () => _StaticUpdates(
        UpdatesState(
          notifications: const <UpdateNotification>[],
          unreadCount: 0,
          followed: shotFollowed(series),
        ),
      ),
    );

/// Paints the fixture covers and registers them with the suite's cover server.
Future<void> paintCovers(WidgetTester tester, List<ShotSeries> series) async {
  final covers = <String, Uint8List>{};
  await tester.runAsync(() async {
    for (var i = 0; i < series.length; i++) {
      covers[shotCoverPath(series[i])] =
          await ShotCoverArt(title: series[i].title, seed: i).toPng();
    }
  });
  addShotCovers(covers);
}

Future<SharedPreferences> shotPrefs() async {
  SharedPreferences.setMockInitialValues(testPrefsDefaults());
  return SharedPreferences.getInstance();
}

class _StaticUpdates extends UpdatesNotifier {
  _StaticUpdates(this.value);
  final UpdatesState value;
  @override
  Future<UpdatesState> build() async => value;
}

/// A believable, entirely invented reading record.
LibraryStatistics shotStatistics() {
  final today = DateTime(2026, 9, 4);
  return LibraryStatistics(
    followedTotal: 9,
    favorites: 3,
    byReadingStatus: const {
      'reading': 6,
      'completed': 2,
      'plan_to_read': 1,
    },
    chaptersCompleted: 1462,
    totals: ReadingTotals(
      sessions: 318,
      pagesRead: 21460,
      chaptersRead: 1462,
      seriesRead: 9,
      secondsRead: 486000,
      firstSessionAt: DateTime.utc(2026, 1, 12, 21),
      lastSessionAt: DateTime.utc(2026, 9, 4, 23, 40),
    ),
    window: const ReadingTotals(
      sessions: 41,
      pagesRead: 2870,
      chaptersRead: 163,
      seriesRead: 5,
      secondsRead: 61200,
    ),
    streak: ReadingStreak(
      currentDays: 12,
      longestDays: 31,
      lastActiveDate: today,
    ),
    daily: [
      for (var i = 29; i >= 0; i--)
        DailyActivity(
          date: today.subtract(Duration(days: i)),
          sessions: _dailyShape[i % _dailyShape.length],
          pagesRead: _dailyShape[i % _dailyShape.length] * 62,
          chaptersRead: _dailyShape[i % _dailyShape.length] * 4,
          secondsRead: _dailyShape[i % _dailyShape.length] * 1450,
        ),
    ],
    byHour: [
      for (var h = 0; h < 24; h++)
        HourActivity(
          hour: h,
          sessions: _hourShape[h],
          pagesRead: _hourShape[h] * 58,
          secondsRead: _hourShape[h] * 1320,
        ),
    ],
    bySource: const [
      SourceActivity(
        sourceId: 'shelf',
        name: 'Shelf',
        sessions: 41,
        pagesRead: 2870,
        chaptersRead: 163,
        seriesRead: 5,
        secondsRead: 61200,
      ),
    ],
    bySeries: [
      for (var i = 0; i < 4; i++)
        SeriesActivity(
          sourceId: 'shelf',
          seriesKey: shotManga[i].slug,
          title: shotManga[i].title,
          lastReadAt: DateTime.utc(2026, 9, 4, 23 - i),
          sessions: 42 - i * 9,
          pagesRead: 1180 - i * 210,
          chaptersRead: 74 - i * 13,
          secondsRead: 26400 - i * 4800,
        ),
    ],
    recentSessions: [
      for (var i = 0; i < 3; i++)
        RecentSession(
          sourceId: 'shelf',
          seriesKey: shotManga[i].slug,
          chapterKey: 'ch-${120 - i * 7}',
          chapterNumber: (120 - i * 7).toDouble(),
          title: shotManga[i].title,
          pagesRead: 48 - i * 6,
          secondsRead: 1500 - i * 220,
          startedAt: DateTime.utc(2026, 9, 4, 22 - i * 2),
          endedAt: DateTime.utc(2026, 9, 4, 22 - i * 2, 25),
        ),
    ],
  );
}

const _dailyShape = [3, 5, 2, 6, 4, 1, 7, 5, 3, 8, 4, 2, 6, 5, 9, 3, 4, 7, 2, 5, 6, 3, 8, 4, 5, 2, 7, 6, 3, 5];
const _hourShape = [2, 1, 0, 0, 0, 0, 0, 1, 3, 4, 2, 3, 5, 4, 3, 6, 5, 7, 9, 12, 15, 18, 22, 14];
