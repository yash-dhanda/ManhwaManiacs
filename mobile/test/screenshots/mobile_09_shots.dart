// ignore_for_file: require_trailing_commas, directives_ordering
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/core/time/clock.dart';
import 'package:manhwamaniacs/features/content_mode/content_mode.dart';
import 'package:manhwamaniacs/features/content_mode/content_mode_controller.dart';
import 'package:manhwamaniacs/features/downloads/models/downloaded_series_group.dart';
import 'package:manhwamaniacs/features/downloads/providers/downloaded_series_provider.dart';
import 'package:manhwamaniacs/features/downloads/providers/mature_gate_provider.dart';
import 'package:manhwamaniacs/features/library/models/continue_reading_item.dart';
import 'package:manhwamaniacs/features/library/models/followed_series.dart';
import 'package:manhwamaniacs/features/library/models/read_state.dart';
import 'package:manhwamaniacs/features/library/models/shelf_query.dart';
import 'package:manhwamaniacs/features/library/models/tag.dart';
import 'package:manhwamaniacs/features/library/utils/followed_series_cache.dart';
import 'package:manhwamaniacs/features/sources/models/source.dart';
import 'package:manhwamaniacs/features/sources/providers/sources_provider.dart';
import 'package:manhwamaniacs/features/updates/providers/unread_count_provider.dart';
import 'package:manhwamaniacs/features/updates/providers/updates_provider.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/layout/cine_grid_overlay.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/feature_screen.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/library/library_screen.dart';
import 'package:manhwamaniacs/skins/cinematic/parts/library_poster.dart';
import 'package:manhwamaniacs/skins/skin_haptics.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../skins/cinematic/feature/feature_test_support.dart' show FakeReader, FakeUpdates, Recorder, RecordingHaptics, featureTheme;
import '../skins/cinematic/library/library_test_support.dart' show ShelfLibrary, savedGroup;
import '../support/test_overrides.dart';
import 'support/shot_covers.dart';
import 'support/shot_network.dart';
import 'support/skin_shots.dart';

const _titles = [
  'Salt and Iron', 'Ember Ledger', 'Moonlit Bakery', 'Night Ward', 'Petal Almanac', 'White Room Protocol',
  'Glass Tide', 'Cold Orbit', 'The Lantern Courier', 'Iron Kite', 'Harbour of Small Lights', 'A Quiet Engine',
  'Paper Saints', 'The Long Tide', 'Copper Weather', 'Lowlight District', 'Tin Orchard', 'Velvet Signal',
  'Northbound Lamp', 'Quarter Moon Post', 'Sable and Sage', 'The Clockwork Ferry', 'Hollow Almanac', 'Dusk Cartographers',
];

FollowedSeries _row(int i, {bool novel = false}) {
  final started = i % 5 != 4;
  final fresh = i % 3 == 0 ? (i % 7) + 1 : (i % 3 == 1 ? 0 : null);
  return FollowedSeries(
    id: i + 1,
    sourceId: novel ? 'novel-archive' : 'shelf',
    seriesKey: 'series-$i',
    title: _titles[i % _titles.length],
    coverUrl: '/sources/${novel ? 'novel-archive' : 'shelf'}/series/series-$i/cover',
    isFavorite: i % 6 == 1,
    readingStatus: switch (i % 6) { 0 => 'reading', 1 => 'reading', 2 => 'on_hold', 3 => 'completed', 4 => 'unread', _ => 'plan_to_read' },
    notify: i % 4 == 0,
    sortOrder: i,
    contentRating: 'safe',
    rating: 'safe',
    chapterCount: novel ? 120 + i * 9 : 40 + i,
    tags: i % 4 == 0 ? const [Tag(id: 1, name: 'slow burn', category: 'custom')] : (i % 4 == 1 ? const [Tag(id: 2, name: 'dungeon', category: 'custom')] : const []),
    readState: ReadState(
      started: started,
      chapterKey: started ? 'c${10 + i}' : null,
      chapterNumber: started ? 10.0 + i : null,
      position: started ? 10 + i : null,
      total: 40 + i,
      latestNumber: 40.0 + i,
      newCount: started ? fresh : null,
    ),
  );
}

List<FollowedSeries> _rows({bool novel = false, int n = 24}) => [for (var i = 0; i < n; i++) _row(i, novel: novel)];

List<ContinueReadingItem> _continue(List<FollowedSeries> rows) => [
      for (var i = 0; i < 6; i++)
        ContinueReadingItem(
          sourceId: rows[i].sourceId,
          seriesKey: rows[i].seriesKey,
          chapterKey: 'c${10 + i}',
          chapterNumber: 10.0 + i,
          lastPage: 8 + i,
          pageCount: 14 + i,
          title: rows[i].title,
          coverUrl: rows[i].coverUrl,
          lastReadAt: DateTime.utc(2026, 9, 29 - i),
        ),
    ];

/// The mobile-09 proof shots: the Library shelf, Cinematic, at `kSkinShotSizes`. Invented fixtures.
void mobile09Shots() {
  Future<void> addCovers(WidgetTester tester) async {
    final png = <String, Uint8List>{};
    for (var i = 0; i < _titles.length; i++) {
      for (final src in ['shelf', 'novel-archive']) {
        final bytes = await tester.runAsync(() => ShotCoverArt(title: _titles[i], seed: i).toPng());
        png['/sources/$src/series/series-$i/cover'] = bytes!;
      }
    }
    addShotCovers(png);
  }

  Future<void> shot(
    WidgetTester t,
    String name, {
    ShelfLibrary? lib,
    Map<String, Object> prefs = const {},
    bool phone = true,
    bool tablet = true,
    bool reduced = false,
    double textScale = 1,
    bool novel = false,
    bool gate = false,
    bool grid = false,
    bool browse = false,
    String query = '',
    List<DownloadedSeriesGroup> saved = const [],
    List<Override> extra = const [],
    Duration settle = const Duration(seconds: 2),
    Widget? home,
    Future<void> Function(WidgetTester t, bool wide)? drive,
  }) async {
    await addCovers(t);
    for (final (size, wide, on) in [(kSkinShotSizes[0], false, phone), (kSkinShotSizes[1], true, tablet)]) {
      if (!on) continue;
      SharedPreferences.setMockInitialValues(testPrefsDefaults(prefs));
      final p = await SharedPreferences.getInstance();
      final fake = lib ?? ShelfLibrary(all: _rows(novel: novel), continueRows: _continue(_rows(novel: novel)), tags: const [Tag(id: 1, name: 'slow burn', category: 'custom'), Tag(id: 2, name: 'dungeon', category: 'custom')]);
      final rec = Recorder();
      await captureSkinWidget(
        t,
        name: name,
        size: size,
        disableAnimations: reduced,
        textScale: textScale,
        overrides: [
          sharedPrefsProvider.overrideWithValue(p),
          apiBaseUrlOverride('http://example.test'),
          ...contentModeOverrides(mode: novel ? ContentMode.novel : ContentMode.manga, novelsEnabled: true),
          sourceModeIndexProvider.overrideWithValue({'shelf': ContentMode.manga, 'novel-archive': ContentMode.novel}),
          libraryRepositoryProvider.overrideWithValue(fake),
          readerRepositoryProvider.overrideWithValue(FakeReader(rec)),
          skinHapticsProvider.overrideWithValue(RecordingHaptics(rec)),
          unreadNotificationCountProvider.overrideWith(_Unread.new),
          newChaptersBannerProvider.overrideWith((ref) async => null),
          matureGateOpenProvider.overrideWithValue(gate),
          downloadedSeriesProvider.overrideWith((ref) async => saved),
          clockProvider.overrideWithValue(() => DateTime.utc(2026, 9, 30, 21, 4)),
          sourcesListProvider.overrideWith((ref) async => const [
                SourceSummary(id: 'shelf', name: 'Shelf Scans', description: '', browsable: true, supportsImport: false),
                SourceSummary(id: 'novel-archive', name: 'Novel Archive', description: '', browsable: true, supportsImport: false),
              ]),
          ...extra,
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: featureTheme(TargetPlatform.android),
          builder: (context, child) => Stack(children: [child!, if (grid) const Positioned.fill(child: CineGridOverlay())]),
          home: home ?? LibraryScreen(browse: browse, params: query.isEmpty ? const {} : Uri.splitQueryString(query)),
        ),
        settle: (t) async {
          for (var ms = 0; ms < settle.inMilliseconds; ms += 100) {
            await t.pump(const Duration(milliseconds: 100));
          }
          await pumpUntilCoversLoad(t, rounds: 8);
          if (drive != null) await drive(t, wide);
        },
      );
    }
  }

  Map<String, Object> stored(ShelfQuery q) => {'mm.shelf-query.u1p1': q.toStoredJson()};

  testWidgets('mobile-09 wall', (t) async => shot(t, 'library-wall'));
  testWidgets('mobile-09 compact', (t) async => shot(t, 'library-compact', prefs: stored(const ShelfQuery(density: ShelfDensity.compact))));
  testWidgets('mobile-09 list', (t) async => shot(t, 'library-list', prefs: stored(const ShelfQuery(density: ShelfDensity.list))));
  testWidgets('mobile-09 grid', (t) async => shot(t, 'library-grid', grid: true));

  testWidgets('mobile-09 browse sheet', (t) async => shot(t, 'library-browse-sheet', browse: true, tablet: false, settle: const Duration(milliseconds: 2500)));

  testWidgets('mobile-09 filters active', (t) async {
    await shot(t, 'library-filters-active', prefs: stored(const ShelfQuery(status: ShelfStatus.reading, fav: true, newOnly: true, tagIds: [1, 2])), lib: ShelfLibrary(
      all: [for (var i = 0; i < 24; i++) _row(i)].map((s) => s.copyWith(isFavorite: true, readingStatus: 'reading')).toList(),
      tags: const [Tag(id: 1, name: 'slow burn', category: 'custom'), Tag(id: 2, name: 'dungeon', category: 'custom')],
    ));
  });

  testWidgets('mobile-09 hub mid swipe', (t) async {
    await shot(t, 'library-hub-mid-swipe', tablet: false, drive: (t, wide) async {
      final g = await t.startGesture(const Offset(300, 560));
      await g.moveBy(const Offset(-24, 0));
      await t.pump(const Duration(milliseconds: 20));
      await g.moveBy(const Offset(-120, 0));
      await t.pump(const Duration(milliseconds: 60));
    });
  });

  testWidgets('mobile-09 hover', (t) async {
    await shot(t, 'library-hover', phone: false, drive: (t, wide) async {
      final mouse = await t.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: const Offset(5, 5));
      addTearDown(mouse.removePointer);
      await mouse.moveTo(t.getCenter(find.byType(LibraryPoster).at(3)));
      await t.pump(const Duration(milliseconds: 400));
    });
  });

  Future<void> wait(WidgetTester t, int ms) async {
    for (var i = 0; i < ms; i += 100) {
      await t.pump(const Duration(milliseconds: 100));
    }
  }

  /// Scrolls the page so the wall is on screen (the hub puts Continue reading above it).
  Future<void> toWall(WidgetTester t) async {
    final pos = t.state<ScrollableState>(find.descendant(of: find.byType(CustomScrollView), matching: find.byType(Scrollable)).first).position;
    pos.jumpTo((pos.maxScrollExtent).clamp(0.0, 480.0));
    await t.pump(const Duration(milliseconds: 300));
  }

  Future<void> selectSome(WidgetTester t, bool wide) async {
    await t.tap(find.text('Select'));
    await toWall(t);
    await t.pump(const Duration(milliseconds: 400));
    for (final i in [0, 2, 3]) {
      await t.tap(find.byType(LibraryPoster).at(i));
      await t.pump(const Duration(milliseconds: 100));
    }
    await t.pump(const Duration(milliseconds: 300));
  }

  testWidgets('mobile-09 select', (t) async => shot(t, 'library-select', drive: selectSome));

  testWidgets('mobile-09 bulk running', (t) async {
    await shot(t, 'library-bulk-running', tablet: false, lib: ShelfLibrary(all: _rows(), patchDelay: const Duration(milliseconds: 900), continueRows: _continue(_rows())), drive: (t, wide) async {
      await t.tap(find.text('Select'));
      await t.pump(const Duration(milliseconds: 400));
      await t.tap(find.text('Select all 24'));
      await t.pump(const Duration(milliseconds: 200));
      await t.tap(find.text('Favourite'));
      await wait(t, 1200);
    });
  });

  testWidgets('mobile-09 unfollow dialog', (t) async {
    await shot(t, 'library-unfollow-dialog', tablet: false, drive: (t, wide) async {
      await selectSome(t, wide);
      await t.ensureVisible(find.text('Unfollow'));
      await t.tap(find.text('Unfollow'));
      await wait(t, 700);
    });
  });

  testWidgets('mobile-09 manual order', (t) async => shot(t, 'library-manual-order', tablet: false, prefs: stored(const ShelfQuery(sort: ShelfSort.manual))));

  testWidgets('mobile-09 books', (t) async => shot(t, 'library-books', novel: true));

  testWidgets('mobile-09 tag sheet', (t) async {
    await shot(t, 'library-tag-sheet', tablet: false, drive: (t, wide) async {
      await t.tap(find.text('Filters'));
      await wait(t, 800);
      await t.ensureVisible(find.text('Manage tags…'));
      await t.tap(find.text('Manage tags…'));
      await wait(t, 1000);
    });
  });

  testWidgets('mobile-09 quick look', (t) async {
    await shot(t, 'library-quick-look', tablet: false, drive: (t, wide) async {
      await toWall(t);
      await t.longPress(find.byType(LibraryPoster).at(1));
      await wait(t, 1000);
    });
  });

  testWidgets('mobile-09 loading', (t) async => shot(t, 'library-loading', lib: ShelfLibrary(all: _rows(), listGate: Completer<void>()), settle: const Duration(milliseconds: 800)));
  testWidgets('mobile-09 empty', (t) async => shot(t, 'library-empty', lib: ShelfLibrary(all: const []), settle: const Duration(seconds: 3)));
  testWidgets('mobile-09 filtered empty', (t) async => shot(t, 'library-filtered-empty', prefs: stored(const ShelfQuery(status: ShelfStatus.dropped)), settle: const Duration(seconds: 3)));
  testWidgets('mobile-09 search empty', (t) async => shot(t, 'library-search-empty', query: 'q=zzz', settle: const Duration(seconds: 3)));
  testWidgets('mobile-09 error', (t) async => shot(t, 'library-error', lib: ShelfLibrary(all: _rows(), listError: const ApiError(statusCode: 500, code: 'boom', message: 'boom')), settle: const Duration(seconds: 3)));

  testWidgets('mobile-09 offline', (t) async {
    final rows = _rows(n: 12);
    await shot(
      t,
      'library-offline',
      lib: ShelfLibrary(all: rows, failList: true),
      prefs: {followedSeriesCacheKeyFor('u1p1'): _cacheJson(rows)},
      saved: [for (final i in [0, 2, 3, 7]) _saved(rows[i])],
    );
  });

  testWidgets('mobile-09 text 2.0', (t) async => shot(t, 'library-text-2.0', tablet: false, textScale: 2.0));
  testWidgets('mobile-09 reduced motion', (t) async => shot(t, 'library-reduced-motion', tablet: false, reduced: true, settle: const Duration(milliseconds: 500)));

  testWidgets('mobile-09 feature by follow not found', (t) async {
    await shot(t, 'feature-by-follow-notfound', tablet: false, home: const FeatureByFollowScreen(followedId: 77), extra: [
      updatesProvider.overrideWith(() => FakeUpdates(Recorder(), const [])),
    ], settle: const Duration(seconds: 3));
  });
}

class _Unread extends UnreadCountNotifier {
  @override
  int build() => 3;
}

String _cacheJson(List<FollowedSeries> rows) => '[${rows.map((r) => _enc(r.toJson())).join(',')}]';

String _enc(Object? o) => jsonEncode(o);

DownloadedSeriesGroup _saved(FollowedSeries s) => savedGroup(s.id - 1, source: s.sourceId);
