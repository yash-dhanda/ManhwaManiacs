@Tags(['screenshots'])
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/content_mode/content_mode.dart';
import 'package:manhwamaniacs/features/downloads/models/download_chapter_state.dart';
import 'package:manhwamaniacs/features/downloads/providers/active_download_queue_provider.dart';
import 'package:manhwamaniacs/features/downloads/queue/download_queue_controller.dart';
import 'package:manhwamaniacs/features/downloads/utils/active_download_count.dart' show glassActiveDownloadCountProvider;
import 'package:manhwamaniacs/features/library/models/collection.dart';
import 'package:manhwamaniacs/features/library/models/collection_detail.dart';
import 'package:manhwamaniacs/features/library/models/tag.dart';
import 'package:manhwamaniacs/features/library/providers/bookmarks_provider.dart';
import 'package:manhwamaniacs/features/library/providers/glass_density_provider.dart';
import 'package:manhwamaniacs/features/library/utils/glass_density.dart';
import 'package:manhwamaniacs/features/library/utils/smart_shelf.dart';
import 'package:manhwamaniacs/features/updates/models/update_settings.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/screens/downloads/series_downloads_card.dart';
import 'package:manhwamaniacs/skins/glass/shell/shell_providers.dart' show glassOfflineProvider;

import '../../features/library/shelf_fixtures.dart';
import '../../skins/glass/downloads/downloads_test.dart' show chapter, downloadOverrides, savedSeries;
import '../../skins/glass/library/library_rig.dart';
import '../../skins/glass/library/sections_test.dart' show FakeBookmarks, bookmark, historyItem;
import '../../skins/glass/updates/updates_test.dart' show FakeUpdatesRepo, notification;
import '../../support/test_overrides.dart' show contentModeOverrides;
import '../glass_shell_shots_support.dart';
import '../support/shot_harness.dart';
import '../support/skin_shots.dart';

/// The mobile/32 proof captures (glass 8.17 to 8.22): the Library hub's five sections, Updates and Downloads on invented fixtures
/// (three series per screen; the 18+ one is never sent to a gate-closed profile). Written only when `MM_PROOF_DIR` is set;
/// otherwise rasterised and discarded. Names: `{screen}-{state}-{phone|tablet|desktop}.png`.

const _phone = SkinShotSize('phone', Size(390, 844), 3.0, EdgeInsets.only(top: 47, bottom: 34));
final _tablet = kSkinShotSizes[1];
const _desktop = kSkinShotDesktop;

FakeLib _lib({int total = 0}) => FakeLib(
      series: [
        shelfSeries(1, title: 'Salt and Iron', fav: true, newCount: 3),
        shelfSeries(2, title: 'Ember Ledger', status: 'completed'),
        shelfSeries(3, title: 'Moonlit Bakery', started: false, status: 'unread'),
        for (var i = 4; i <= 9; i++) shelfSeries(i, title: 'Glass Tide $i', status: i.isEven ? 'reading' : 'on_hold', newCount: i % 3 == 0 ? 1 : null),
      ],
      collections: const [
        Collection(id: 3, name: 'Weekend reads', description: 'Short, warm, finished.', seriesCount: 3, sortOrder: 0),
        Collection(id: 4, name: 'Catching up', seriesCount: 2, sortOrder: 1, rules: ShelfRules(all: [ShelfRule(field: 'reading_status', op: 'eq', value: 'reading'), ShelfRule(field: 'new_count', op: 'gte', value: 1)])),
      ],
      members: const [
        CollectionSeriesRef(sourceId: 'shelf', seriesKey: 'series-1', sortOrder: 0),
        CollectionSeriesRef(sourceId: 'shelf', seriesKey: 'series-2', sortOrder: 1),
        CollectionSeriesRef(sourceId: 'shelf', seriesKey: 'series-3', sortOrder: 2),
      ],
      history: [for (var i = 1; i <= 6; i++) historyItem(i)],
      tags: const [Tag(id: 5, name: 'Cosy', category: 'user', colorHex: '#7AA2F7', seriesCount: 12), Tag(id: 6, name: 'Rereads', category: 'user', colorHex: '#F7768E', seriesCount: 3)],
    )..total = total == 0 ? null : total;

List<Override> _downloads() => [
      ...downloadOverrides([savedSeries('series-1', 'Salt and Iron', 4), savedSeries('series-2', 'Ember Ledger', 2)]),
      activeDownloadQueueProvider.overrideWith((ref) async => [
            chapter(11, title: 'Salt and Iron', state: DownloadChapterState.downloading),
            chapter(12, title: 'Salt and Iron', state: DownloadChapterState.queued),
            chapter(13, series: 'series-3', title: 'Moonlit Bakery', state: DownloadChapterState.failed),
            // The 18+ fixture: the gate is closed in every capture, so it must appear in no row, count, badge or meter.
            chapter(14, series: 'series-9', title: 'Velvet Knife', state: DownloadChapterState.queued, mature: true),
          ],),
    ];

List<Override> _bookmarks() => [
      bookmarksProvider.overrideWith(() => FakeBookmarks([bookmark('a', title: 'Salt and Iron'), bookmark('b', series: 'series-2', title: 'Ember Ledger'), bookmark('c', series: 'series-3', title: 'Moonlit Bakery')])),
    ];

class _RunRepo extends FakeUpdatesRepo {
  _RunRepo() : super(notifications: [notification(1, 1, 141)]);
  @override
  Future<Result<UpdateRun>> getRun(int runId) async => Ok(UpdateRun(id: runId, trigger: 'schedule', status: 'failed', seriesChecked: 41, newChaptersFound: 3, error: 'shelf: timed out after 30 s', startedAt: DateTime.utc(2026, 9, 30, 6), finishedAt: DateTime.utc(2026, 9, 30, 6, 2)));
}

enum _Look { normal, reduced, solid, contrast }

Future<ShotSession> _open(WidgetTester t, SkinShotSize size, String route, {FakeLib? lib, List<Override> extra = const [], _Look look = _Look.normal}) async {
  final s = await openShell(t, size, start: route, settle: false, extra: [
    ...libraryOverrides(lib ?? _lib()),
    updatesRepositoryProvider.overrideWithValue(FakeUpdatesRepo(notifications: [notification(1, 1, 141), notification(2, 1, 142), notification(3, 1, 143), notification(4, 4, 18), notification(5, 2, 77, read: true)])),
    ..._bookmarks(),
    ..._downloads(),
    ...extra,
  ],);
  final p = s.container.read(glassInAppPrefsProvider.notifier);
  switch (look) {
    case _Look.reduced:
      p.setReduceMotion(true);
    case _Look.solid:
      p.setSolidGlass(true);
    case _Look.contrast:
      p.setIncreaseContrast(true);
    case _Look.normal:
      break;
  }
  for (var i = 0; i < 5; i++) {
    await s.settle(400);
  }
  return s;
}

Future<void> _end(WidgetTester t) async {
  await t.pumpWidget(const SizedBox.shrink());
  await t.pump(const Duration(minutes: 11));
}

Future<void> _shot(WidgetTester t, String name, String route, {List<SkinShotSize>? sizes, FakeLib Function()? lib, List<Override> extra = const [], _Look look = _Look.normal, Future<void> Function(ShotSession s)? act}) async {
  for (final size in sizes ?? [_phone]) {
    final s = await _open(t, size, route, lib: lib?.call(), extra: extra, look: look);
    if (act != null) await act(s);
    await s.snap(name, size);
    await _end(t);
  }
}

/// A frame captured while a gesture is held: [act] snaps it itself, then releases.
Future<void> _held(WidgetTester t, String route, Future<void> Function(ShotSession s) act) async {
  final s = await _open(t, _phone, route);
  await act(s);
  await s.settle(400);
  await _end(t);
}

void main() {
  setUpAll(loadAppFonts);
  final all = [_phone, _tablet, _desktop];

  group('shelf', () {
    testWidgets('default on three frames', (t) => _shot(t, 'shelf-default', '/library', sizes: all));
    testWidgets('list', (t) => _shot(t, 'shelf-list', '/library', act: (s) async {
          s.container.read(glassDensityProvider.notifier).setPhone(GlassPhoneDensity.list);
          await s.settle(800);
        },),);
    testWidgets('five columns', (t) => _shot(t, 'shelf-5-columns', '/library', act: (s) async {
          s.container.read(glassDensityProvider.notifier).setPhone(GlassPhoneDensity.c5);
          await s.settle(800);
        },),);
    testWidgets('select mode with the toolbar', (t) => _shot(t, 'shelf-select', '/library', act: (s) async {
          await t.tap(find.bySemanticsLabel(RegExp(r'^Select$')).first);
          await s.settle(300);
          await t.tap(find.text('Salt and Iron').first);
          await t.tap(find.text('Ember Ledger').first);
          await s.settle(600);
        },),);
    testWidgets('context menu lifted', (t) => _shot(t, 'shelf-context-menu', '/library', act: (s) async {
          final g = await t.startGesture(t.getCenter(find.text('Ember Ledger').first) - const Offset(0, 80));
          await s.settle();
          await g.up();
          await s.settle(500);
        },),);
    testWidgets('Filters sheet', (t) => _shot(t, 'shelf-filters-sheet', '/library?sheet=filters'));
    testWidgets('Manage tags', (t) => _shot(t, 'shelf-manage-tags', '/library?sheet=manage-tags'));
    testWidgets('Density sheet', (t) => _shot(t, 'shelf-density-sheet', '/library?sheet=density'));
    testWidgets('browse all capped', (t) => _shot(t, 'browse-all-capped', '/library/browse', lib: () => _lib(total: 412)));
    testWidgets('novels shelf', (t) => _shot(t, 'shelf-novels', '/library', extra: contentModeOverrides(mode: ContentMode.novel, novelsEnabled: true)));
    testWidgets('empty', (t) => _shot(t, 'shelf-empty', '/library', lib: FakeLib.new));
    testWidgets('error', (t) => _shot(t, 'shelf-error', '/library', lib: () => _lib()..down = true));
    testWidgets('offline', (t) => _shot(t, 'shelf-offline', '/library', lib: () => _lib()..down = true, extra: [glassOfflineProvider.overrideWithValue(true)]));
    testWidgets('mid-pinch', (t) => _held(t, '/library', (s) async {
          final c = t.getCenter(find.text('Ember Ledger').first);
          final a = await t.startGesture(c - const Offset(40, 60), pointer: 7);
          final b = await t.startGesture(c + const Offset(40, -60), pointer: 8);
          await s.settle(16);
          await a.moveBy(const Offset(-30, 0));
          await b.moveBy(const Offset(30, 0));
          await s.settle(16);
          await s.snap('shelf-pinch-mid', _phone);
          await a.up();
          await b.up();
        },),);
    testWidgets('Downloading accessory over a scrolled shelf', (t) => _shot(t, 'dock-downloading-accessory', '/library', extra: [glassActiveDownloadCountProvider.overrideWithValue(3)], act: (s) async {
          await t.drag(find.text('Ember Ledger').first, const Offset(0, -300));
          await s.settle(600);
        },),);
    testWidgets('dock badge', (t) async {
      final s = await _open(t, _phone, '/library', extra: [glassActiveDownloadCountProvider.overrideWithValue(12)]);
      await s.snap('dock-library-badge', _phone);
      await _end(t);
    });
    for (final look in [_Look.reduced, _Look.solid, _Look.contrast]) {
      testWidgets('default ${look.name}', (t) => _shot(t, 'shelf-default-${look.name}', '/library', look: look));
    }
  });

  group('collections', () {
    testWidgets('list', (t) => _shot(t, 'collections-list', '/library/collections', sizes: all));
    testWidgets('New collection sheet', (t) => _shot(t, 'collections-new-sheet', '/library/collections?sheet=collection-new'));
    testWidgets('empty', (t) => _shot(t, 'collections-empty', '/library/collections', lib: FakeLib.new));
    testWidgets('detail', (t) => _shot(t, 'collection-default', '/library/collections/3', sizes: all));
    testWidgets('Fan open mid-flight', (t) async {
      final s = await openShell(t, _phone, start: '/library/collections/3', settle: false, extra: [...libraryOverrides(_lib()), updatesRepositoryProvider.overrideWithValue(FakeUpdatesRepo()), ..._bookmarks(), ..._downloads()]);
      await s.settle(16);
      await s.settle(180);
      await s.snap('collection-fan-open-mid', _phone);
      await _end(t);
    });
    testWidgets('detail auto rules', (t) => _shot(t, 'collection-auto', '/library/collections/4'));
    testWidgets('detail empty', (t) => _shot(t, 'collection-empty', '/library/collections/3', lib: () => _lib()..members = const []));
    testWidgets('Add series sheet', (t) => _shot(t, 'collection-add-series', '/library/collections/3?sheet=add-series&collection=3'));
    for (final look in [_Look.reduced, _Look.solid, _Look.contrast]) {
      testWidgets('list ${look.name}', (t) => _shot(t, 'collections-list-${look.name}', '/library/collections', look: look));
    }
  });

  group('history and bookmarks', () {
    testWidgets('history by series', (t) => _shot(t, 'history-by-series', '/library/history', sizes: all));
    testWidgets('history timeline', (t) => _shot(t, 'history-timeline', '/library/history', act: (s) async {
          await t.tap(find.text('Timeline').first);
          await s.settle(800);
        },),);
    testWidgets('history empty', (t) => _shot(t, 'history-empty', '/library/history', lib: FakeLib.new));
    testWidgets('bookmarks default', (t) => _shot(t, 'bookmarks-default', '/library/bookmarks', sizes: all));
    testWidgets('bookmarks filtered', (t) => _shot(t, 'bookmarks-filtered', '/library/bookmarks?source=shelf&series=series-1'));
    testWidgets('history offline', (t) => _shot(t, 'history-offline', '/library/history', lib: () => _lib()..down = true, extra: [glassOfflineProvider.overrideWithValue(true)]));
    testWidgets('bookmarks offline', (t) => _shot(t, 'bookmarks-offline', '/library/bookmarks', extra: [glassOfflineProvider.overrideWithValue(true)]));
    testWidgets('bookmarks empty', (t) => _shot(t, 'bookmarks-empty', '/library/bookmarks', extra: [bookmarksProvider.overrideWith(() => FakeBookmarks(const []))]));
  });

  group('updates', () {
    testWidgets('all', (t) => _shot(t, 'updates-all', '/updates', sizes: all));
    testWidgets('unread', (t) => _shot(t, 'updates-unread', '/updates?tab=unread'));
    testWidgets('followed', (t) => _shot(t, 'updates-followed', '/updates?tab=followed'));
    testWidgets('run sheet', (t) => _shot(t, 'updates-run-sheet', '/updates?sheet=run&run=7', extra: [updatesRepositoryProvider.overrideWithValue(_RunRepo())]));
    testWidgets('all read', (t) => _shot(t, 'updates-all-read', '/updates', extra: [updatesRepositoryProvider.overrideWithValue(FakeUpdatesRepo(notifications: [notification(5, 2, 77, read: true)]))]));
  });

  group('downloads', () {
    testWidgets('chapters', (t) => _shot(t, 'downloads-chapters', '/downloads', sizes: all));
    testWidgets('queue', (t) => _shot(t, 'downloads-queue', '/downloads?tab=queue', sizes: all));
    testWidgets('storage', (t) => _shot(t, 'downloads-storage', '/downloads?tab=storage', sizes: all));
    testWidgets('Drain mid-flight', (t) => _shot(t, 'downloads-drain-mid', '/downloads', act: (s) async {
          t.state<GlassSeriesDownloadsCardState>(find.byType(GlassSeriesDownloadsCard).first).drain();
          await s.settle(140);
        },),);
    testWidgets('queue paused by you', (t) => _shot(t, 'downloads-queue-paused', '/downloads?tab=queue', act: (s) async {
          s.container.read(downloadQueueControllerProvider.notifier).pause();
          await s.settle(600);
        },),);
    testWidgets('queue reorder lift', (t) => _held(t, '/downloads?tab=queue', (s) async {
          final g = await t.startGesture(t.getCenter(find.textContaining('Chapter 12').last));
          await s.settle();
          await g.moveBy(const Offset(0, 24));
          await s.settle(100);
          await s.snap('downloads-queue-reorder-lift', _phone);
          await g.up();
        },),);
    testWidgets('Save to Files sheet', (t) => _shot(t, 'downloads-save-files-sheet', '/downloads?sheet=save-files&series=shelf:series-1'));
    testWidgets('empty', (t) => _shot(t, 'downloads-empty', '/downloads', extra: downloadOverrides(const [])));
    for (final look in [_Look.reduced, _Look.solid, _Look.contrast]) {
      testWidgets('chapters ${look.name}', (t) => _shot(t, 'downloads-chapters-${look.name}', '/downloads', look: look));
    }
  });
}
