// ignore_for_file: require_trailing_commas, directives_ordering
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/core/time/clock.dart';
import 'package:manhwamaniacs/features/auth/providers/session_offline_provider.dart';
import 'package:manhwamaniacs/features/content_mode/content_mode.dart';
import 'package:manhwamaniacs/features/content_mode/content_mode_controller.dart';
import 'package:manhwamaniacs/features/downloads/providers/bookmark_outbox_provider.dart';
import 'package:manhwamaniacs/features/downloads/providers/downloaded_series_provider.dart';
import 'package:manhwamaniacs/features/downloads/providers/mature_gate_provider.dart';
import 'package:manhwamaniacs/features/library/models/collection.dart';
import 'package:manhwamaniacs/features/library/models/followed_series.dart';
import 'package:manhwamaniacs/features/library/models/read_state.dart';
import 'package:manhwamaniacs/features/library/providers/bookmarks_provider.dart';
import 'package:manhwamaniacs/features/library/utils/smart_shelf.dart';
import 'package:manhwamaniacs/features/profiles/models/mood.dart';
import 'package:manhwamaniacs/features/profiles/models/profile.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/features/reader/models/bookmark.dart';
import 'package:manhwamaniacs/features/sources/models/source.dart';
import 'package:manhwamaniacs/features/sources/providers/sources_provider.dart';
import 'package:manhwamaniacs/features/updates/models/update_settings.dart';
import 'package:manhwamaniacs/features/updates/providers/updates_provider.dart';
import 'package:manhwamaniacs/features/updates/providers/unread_count_provider.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/parts/library_poster.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cards/cine_collection_plate.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/bookmarks/bookmarks_screen.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/collections/collection_screen.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/collections/collections_screen.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/history/history_screen.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/updates/updates_screen.dart';
import 'package:manhwamaniacs/skins/skin_haptics.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../skins/cinematic/feature/feature_test_support.dart' show FakeReader, Recorder, RecordingHaptics, featureTheme;
import '../skins/cinematic/hub/hub_test_support.dart' hide settle;
import '../support/test_overrides.dart';
import 'support/shot_covers.dart';
import 'support/shot_network.dart';
import 'support/skin_shots.dart';

const _titles = [
  'Salt and Iron', 'Ember Ledger', 'Moonlit Bakery', 'Night Ward', 'Petal Almanac', 'White Room Protocol',
  'Glass Tide', 'Cold Orbit', 'The Lantern Courier', 'Iron Kite', 'Harbour of Small Lights', 'A Quiet Engine',
];

final _now = DateTime.utc(2026, 9, 30, 21, 4);

FollowedSeries _row(int i) => FollowedSeries(
      id: i + 1,
      sourceId: 'shelf',
      seriesKey: 'series-${i + 1}',
      title: _titles[i % _titles.length],
      coverUrl: '/sources/shelf/series/series-${i + 1}/cover',
      isFavorite: i % 4 == 1,
      readingStatus: i % 3 == 2 ? 'completed' : 'reading',
      notify: i % 3 == 0,
      sortOrder: i,
      contentRating: 'safe',
      rating: 'safe',
      chapterCount: 40 + i,
      lastCheckedAt: _now.subtract(Duration(minutes: 12 + i * 9)),
      readState: ReadState(started: true, chapterKey: 'c${10 + i}', chapterNumber: 10.0 + i, position: 10 + i, total: 40 + i, latestNumber: 40.0 + i, newCount: i < 4 ? 4 - i : 0),
    );

List<FollowedSeries> _rows() => [for (var i = 0; i < 12; i++) _row(i)];

HubLibrary _library({bool fail = false, bool offline = false, List<Collection>? shelves, bool history = true, int historyCount = 12}) => HubLibrary(
      all: _rows(),
      collections: shelves ??
          [
            shelfOf(1, 'Slow burns', at: DateTime.utc(2026, 8), description: 'Long arcs for rainy weeks.'),
            shelfOf(2, 'Night reads', order: 1, at: DateTime.utc(2026, 9, 3)),
            shelfOf(3, 'Hot right now', order: 2, at: DateTime.utc(2026, 9, 20), rules: const ShelfRules(all: [ShelfRule(field: 'reading_status', op: 'eq', value: 'reading'), ShelfRule(field: 'new_count', op: 'gte', value: 3)])),
            shelfOf(4, 'Unstarted pile', order: 3, at: DateTime.utc(2026, 9, 25)),
          ],
      members: {
        1: [for (var i = 1; i <= 6; i++) ('shelf', 'series-$i')],
        2: [('shelf', 'series-7'), ('shelf', 'series-8'), ('shelf', 'series-9')],
        3: <(String, String)>[],
        4: <(String, String)>[],
      },
      history: !history
          ? const []
          : [
              for (var i = 0; i < historyCount; i++)
                logRow(i + 1, (i % 12) + 1, chapter: 12.0 + i, page: 4 + i, pages: 32 + i, done: i == 2, at: i < 4 ? _now.subtract(Duration(minutes: 20 + i * 47)) : _now.subtract(Duration(days: 1 + i ~/ 4, hours: i)), title: _titles[i % 12], cover: '/sources/shelf/series/series-${(i % 12) + 1}/cover'),
            ],
    )
      ..failCollections = fail
      ..offlineCollections = offline;

FakeUpdates _updates({bool fail = false, bool offline = false, bool empty = false}) => FakeUpdates(
      notes: empty
          ? []
          : [
              note(1, 1, 141, at: _now.subtract(const Duration(minutes: 25))),
              note(2, 1, 142, at: _now.subtract(const Duration(minutes: 22))),
              note(3, 1, 143, at: _now.subtract(const Duration(minutes: 20))),
              note(4, 2, 88, at: _now.subtract(const Duration(hours: 3))),
              note(5, 3, 17, at: _now.subtract(const Duration(days: 1, hours: 2))),
              note(6, 4, 9, at: _now.subtract(const Duration(days: 1, hours: 5)), read: true),
              note(7, 5, 61, at: _now.subtract(const Duration(days: 2))),
            ],
      settings: UpdateSettings(enabled: true, checkIntervalMinutes: 30, notifyEnabled: true, checkOnStartup: false, lastRunAt: _now.subtract(const Duration(minutes: 12))),
      runs: [
        for (var i = 0; i < 4; i++) UpdateRun(id: 20 - i, trigger: i == 0 ? 'manual' : 'scheduled', status: 'finished', seriesChecked: 212, newChaptersFound: 3 - i.clamp(0, 3), startedAt: _now.subtract(Duration(minutes: 12 + i * 30))),
      ],
      progress: [
        const UpdateRun(id: 30, trigger: 'manual', status: 'running', seriesChecked: 180, newChaptersFound: 3),
      ],
    )
      ..failList = fail
      ..offline = offline;

List<Bookmark> _marks() => [
      mark('a', novel: true, snippet: 'The door had never been locked. That was the first thing she should have noticed.', fraction: 0.62, note: 'Reread before the reveal.', at: DateTime.utc(2026, 9, 28, 20)),
      mark('b', series: 2, chapter: 88, at: DateTime.utc(2026, 9, 27, 9)),
      mark('c', series: 2, index: 12, chapter: 86, note: 'The panel with the lantern.', at: DateTime.utc(2026, 9, 26, 9)),
      mark('d', series: 3, novel: true, snippet: 'It was the kind of quiet that has a shape.', stale: true, chapter: 17, index: 3, total: 9, at: DateTime.utc(2026, 9, 25, 9)),
      mark('e', series: 4, chapter: 9, index: 21, at: DateTime.utc(2026, 9, 24, 9)),
    ];

class _Unread extends UnreadCountNotifier {
  @override
  int build() => 6;
}

class _ProfilesOff extends ProfilesNotifier {
  @override
  Future<List<Profile>> build() async => [Profile(id: 1, name: 'Tester', avatarKey: null, mood: Mood.neutral, sortOrder: 0, matureContentEnabled: false, createdAt: DateTime.utc(2026), notifyEnabled: false)];
}

class _Offline extends SessionOfflineNotifier {
  @override
  bool build() => true;
}

/// The mobile-10 proof shots: Updates, Collections, a shelf, History and Bookmarks, Cinematic, at
/// `kSkinShotSizes` and `kSkinShotTabletWide`. Invented fixtures only.
void mobile10Shots() {
  Future<void> addCovers(WidgetTester tester) async {
    final png = <String, Uint8List>{};
    for (var i = 0; i < 12; i++) {
      final bytes = await tester.runAsync(() => ShotCoverArt(title: _titles[i], seed: i).toPng());
      png['/sources/shelf/series/series-${i + 1}/cover'] = bytes!;
    }
    addShotCovers(png);
  }

  Future<void> wait(WidgetTester t, int ms) async {
    for (var i = 0; i < ms; i += 100) {
      await t.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> shot(
    WidgetTester t,
    String name,
    Widget home, {
    HubLibrary? lib,
    FakeUpdates? updates,
    List<Bookmark>? marks,
    Object? marksError,
    bool member = false,
    bool phone = true,
    bool tablet = true,
    bool wide = false,
    bool reduced = false,
    double textScale = 1,
    bool novel = false,
    bool offline = false,
    bool noticesOff = false,
    Map<String, Object> prefs = const {},
    Duration settle = const Duration(seconds: 3),
    Future<void> Function(WidgetTester t, bool wide)? drive,
  }) async {
    await addCovers(t);
    final sizes = [if (phone) (kSkinShotSizes[0], false), if (tablet) (kSkinShotSizes[1], true), if (wide) (kSkinShotTabletWide, true)];
    for (final (size, isWide) in sizes) {
      SharedPreferences.setMockInitialValues(testPrefsDefaults(prefs));
      final p = await SharedPreferences.getInstance();
      final library = lib ?? _library();
      final fakeUpdates = updates ?? _updates();
      final items = [...(marks ?? _marks())];
      final outbox = FakeOutbox(items);
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
          authenticatedAuthOverride(),
          activeProfileOverride(),
          ...contentModeOverrides(mode: novel ? ContentMode.novel : ContentMode.manga, novelsEnabled: true),
          sourceModeIndexProvider.overrideWithValue({'shelf': ContentMode.manga}),
          libraryRepositoryProvider.overrideWithValue(library),
          readerRepositoryProvider.overrideWithValue(FakeReader(rec)),
          skinHapticsProvider.overrideWithValue(RecordingHaptics(rec)),
          unreadNotificationCountProvider.overrideWith(_Unread.new),
          newChaptersBannerProvider.overrideWith((ref) async => null),
          matureGateOpenProvider.overrideWithValue(false),
          downloadedSeriesProvider.overrideWith((ref) async => const []),
          clockProvider.overrideWithValue(() => _now),
          sourcesListProvider.overrideWith((ref) async => const [
                SourceSummary(id: 'shelf', name: 'Shelf Scans', description: '', browsable: true, supportsImport: false),
              ]),
          ...updatesOverrides(fakeUpdates, member: member),
          bookmarksProvider.overrideWith(() => FakeBookmarks(items, error: marksError is AppError ? marksError : null)),
          bookmarkOutboxControllerProvider.overrideWithValue(outbox),
          if (offline) sessionOfflineProvider.overrideWith(_Offline.new),
          if (noticesOff) profilesProvider.overrideWith(_ProfilesOff.new),
        ],
        child: MaterialApp(debugShowCheckedModeBanner: false, theme: featureTheme(TargetPlatform.android), home: home),
        settle: (t) async {
          await wait(t, settle.inMilliseconds);
          await pumpUntilCoversLoad(t, rounds: 8);
          if (drive != null) await drive(t, isWide);
        },
      );
    }
  }

  // ---- Updates -----------------------------------------------------------------------------------

  const updates = UpdatesScreen();
  testWidgets('mobile-10 updates new', (t) async => shot(t, 'updates-new', updates));
  testWidgets('mobile-10 updates following', (t) async => shot(t, 'updates-following', updates, drive: (t, w) async {
        await t.tap(find.text('FOLLOWING'));
        await wait(t, 800);
      }));
  testWidgets('mobile-10 updates checking', (t) async => shot(t, 'updates-checking', updates, tablet: false, drive: (t, w) async {
        await t.tap(find.text('Check now'));
        await wait(t, 900);
      }));
  testWidgets('mobile-10 updates aside', (t) async => shot(t, 'updates-aside', updates, phone: false, tablet: false, wide: true));
  testWidgets('mobile-10 updates loading', (t) async => shot(t, 'updates-loading', updates, lib: _library()..failCollections = false, updates: _updates()..failList = false, settle: const Duration(milliseconds: 60)));
  testWidgets('mobile-10 updates empty', (t) async => shot(t, 'updates-empty', updates, updates: _updates(empty: true), lib: HubLibrary(all: const [])));
  testWidgets('mobile-10 updates offline', (t) async {
    final u = _updates();
    await shot(t, 'updates-offline', updates, updates: u, drive: (t, w) async {
      u.offline = true;
      final c = ProviderScope.containerOf(t.element(find.byType(UpdatesScreen)));
      c.invalidate(updatesProvider);
      await wait(t, 1200);
    });
  });
  testWidgets('mobile-10 updates error', (t) async => shot(t, 'updates-error', updates, updates: _updates(fail: true)));
  testWidgets('mobile-10 updates notices off', (t) async => shot(t, 'updates-notices-off', updates, noticesOff: true));

  // ---- Collections --------------------------------------------------------------------------------

  const collections = CollectionsScreen();
  testWidgets('mobile-10 collections', (t) async => shot(t, 'collections', collections));
  testWidgets('mobile-10 collections custom order', (t) async => shot(t, 'collections-custom-order', collections, tablet: false, prefs: {'mm.collections.sort.u1p1': 'custom'}));
  testWidgets('mobile-10 collections new shelf smart', (t) async => shot(t, 'collections-new-shelf-smart', collections, drive: (t, w) async {
        await t.tap(find.text('New shelf'));
        await wait(t, 900);
        await t.tap(find.byType(Switch).first, warnIfMissed: false);
        await wait(t, 200);
      }));
  testWidgets('mobile-10 collections loading', (t) async => shot(t, 'collections-loading', collections, settle: const Duration(milliseconds: 40)));
  testWidgets('mobile-10 collections empty', (t) async => shot(t, 'collections-empty', collections, lib: _library(shelves: [])));
  testWidgets('mobile-10 collections offline', (t) async => shot(t, 'collections-offline', collections, lib: _library(offline: true)));
  testWidgets('mobile-10 collections error', (t) async => shot(t, 'collections-error', collections, lib: _library(fail: true)));

  // ---- One shelf ----------------------------------------------------------------------------------

  CollectionScreen shelf(int id) => CollectionScreen(collectionId: id);
  testWidgets('mobile-10 collection', (t) async => shot(t, 'collection', shelf(1)));
  testWidgets('mobile-10 collection smart', (t) async => shot(t, 'collection-smart', shelf(3), tablet: false));
  testWidgets('mobile-10 collection reorder', (t) async => shot(t, 'collection-reorder', shelf(1), tablet: false, drive: (t, w) async {
        await t.tap(find.text('Reorder'));
        await wait(t, 600);
      }));
  testWidgets('mobile-10 collection add series', (t) async => shot(t, 'collection-add-series', shelf(1), tablet: false, drive: (t, w) async {
        await t.tap(find.text('Add series'));
        await wait(t, 1000);
      }));
  testWidgets('mobile-10 collection delete dialog', (t) async => shot(t, 'collection-delete-dialog', shelf(1), tablet: false, drive: (t, w) async {
        await t.tap(find.text('More'));
        await wait(t, 500);
        await t.tap(find.text('Delete shelf'));
        await wait(t, 1300);
      }));
  testWidgets('mobile-10 collection empty', (t) async => shot(t, 'collection-empty', shelf(4), tablet: false));
  testWidgets('mobile-10 collection nothing matches', (t) async => shot(t, 'collection-nothing-matches', shelf(3), tablet: false, lib: HubLibrary(all: [_row(8).copyWith(readingStatus: 'dropped')], collections: [shelfOf(3, 'Hot right now', rules: const ShelfRules(all: [ShelfRule(field: 'reading_status', op: 'eq', value: 'reading')]))])));
  testWidgets('mobile-10 collection mode mismatch', (t) async => shot(t, 'collection-mode-mismatch', shelf(1), tablet: false, novel: true));
  testWidgets('mobile-10 collection notfound', (t) async => shot(t, 'collection-notfound', shelf(99), tablet: false));
  testWidgets('mobile-10 collection match cut mid', (t) async {
    // The plate on the Collections page and the header it becomes: the route animation at 240 ms.
    await shot(t, 'collection-match-cut-mid', collections, tablet: false, drive: (t, w) async {
      await t.tap(find.byType(CineCollectionPlate).first);
      await t.pump(const Duration(milliseconds: 240));
    });
  });

  // ---- History ------------------------------------------------------------------------------------

  const history = HistoryScreen();
  testWidgets('mobile-10 history', (t) async => shot(t, 'history', history));
  testWidgets('mobile-10 history by chapter', (t) async => shot(t, 'history-by-chapter', history, tablet: false, drive: (t, w) async {
        await t.tap(find.text('BY CHAPTER'));
        await wait(t, 900);
      }));
  testWidgets('mobile-10 history loading', (t) async => shot(t, 'history-loading', history, settle: const Duration(milliseconds: 40)));
  testWidgets('mobile-10 history empty', (t) async => shot(t, 'history-empty', history, lib: _library(history: false)));
  testWidgets('mobile-10 history offline', (t) async => shot(t, 'history-offline', history, lib: _library(offline: true)));
  testWidgets('mobile-10 history error', (t) async => shot(t, 'history-error', history, lib: _library(fail: true)));

  // ---- Bookmarks ----------------------------------------------------------------------------------

  const bookmarks = BookmarksScreen();
  testWidgets('mobile-10 bookmarks', (t) async => shot(t, 'bookmarks', bookmarks));
  testWidgets('mobile-10 bookmarks two columns', (t) async => shot(t, 'bookmarks-two-columns', bookmarks, phone: false, tablet: false, wide: true));
  testWidgets('mobile-10 bookmarks editing', (t) async => shot(t, 'bookmarks-editing', bookmarks, tablet: false, drive: (t, w) async {
        await t.tap(find.text('Add a note').first);
        await wait(t, 600);
        await t.enterText(find.byType(EditableText).first, 'The lantern is a clue.');
        await wait(t, 300);
      }));
  testWidgets('mobile-10 bookmarks loading', (t) async => shot(t, 'bookmarks-loading', bookmarks, settle: const Duration(milliseconds: 40)));
  testWidgets('mobile-10 bookmarks empty', (t) async => shot(t, 'bookmarks-empty', bookmarks, marks: const []));
  testWidgets('mobile-10 bookmarks offline', (t) async => shot(t, 'bookmarks-offline', bookmarks, offline: true));
  testWidgets('mobile-10 bookmarks error', (t) async => shot(t, 'bookmarks-error', bookmarks, marks: const [], marksError: const ApiError(statusCode: 500, code: 'boom', message: 'boom')));

  // ---- The hub ------------------------------------------------------------------------------------

  testWidgets('mobile-10 hub reduced motion', (t) async => shot(t, 'hub-reduced-motion', updates, tablet: false, reduced: true));
  testWidgets('mobile-10 hub text 2.0', (t) async => shot(t, 'hub-text-2.0', history, tablet: false, textScale: 2));
  testWidgets('mobile-10 plates in a poster wall', (t) async => shot(t, 'collection-poster-hover', shelf(1), phone: false, drive: (t, w) async {
        expect(find.byType(LibraryPoster), findsWidgets);
      }));
}
