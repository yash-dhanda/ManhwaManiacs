// ignore_for_file: require_trailing_commas, directives_ordering
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/features/downloads/models/chapter_identity.dart';
import 'package:manhwamaniacs/features/downloads/providers/active_download_queue_provider.dart';
import 'package:manhwamaniacs/features/downloads/providers/downloaded_series_provider.dart';
import 'package:manhwamaniacs/features/downloads/providers/downloads_scope.dart';
import 'package:manhwamaniacs/features/downloads/providers/mature_stamper.dart';
import 'package:manhwamaniacs/features/downloads/services/offline_reader.dart';
import 'package:manhwamaniacs/features/downloads/store/bookmarks_dao.dart';
import 'package:manhwamaniacs/features/downloads/models/saved_chapter.dart';
import 'package:manhwamaniacs/features/downloads/store/downloads_store.dart';
import 'package:manhwamaniacs/features/library/utils/followed_series_cache.dart';
import 'package:manhwamaniacs/features/reader/models/bookmark.dart';
import 'package:manhwamaniacs/features/reader/models/reading_progress.dart';

import '../../support/downloads_test_support.dart';
import 'mature_gate_support.dart';

const _c1 = (sourceId: 'src', seriesKey: 'hot', chapterKey: 'c1');
const _c2 = (sourceId: 'src', seriesKey: 'hot', chapterKey: 'c2');
const _c3 = (sourceId: 'src', seriesKey: 'hot', chapterKey: 'c3');
const _plain = (sourceId: 'src', seriesKey: 'plain', chapterKey: 'p1');

Future<int> _complete(DownloadsStore s, ChapterIdentity id, {DownloadKind kind = DownloadKind.manga}) async {
  final row = await s.ensureQueued(id: id, kind: kind, seriesTitle: id.seriesKey);
  await s.updateManifestInfo(rowId: row, pageCount: 1);
  if (kind == DownloadKind.audio) {
    await s.saveAudio(rowId: row, bytes: List.filled(64, 1));
  } else {
    await s.savePage(rowId: row, pageNumber: 1, bytes: [1, 2, 3]);
  }
  await s.markCompleteIfAllPagesPresent(row);
  return row;
}

void main() {
  initSqfliteFfiForTests();

  test('local copies follow the gate: absent when closed, back when open, and the override decides', () async {
    // "hot" is served as mature only because its follow row says mature_override: true.
    final rig = await gateRig(follows: [
      follow(1, 'hot', rating: 'mature', override: true),
      follow(2, 'plain', rating: 'safe'),
    ]);
    addTearDown(() async {
      rig.container.dispose();
      await rig.harness.dispose();
    });
    final c = rig.container;
    final store = c.read(downloadsStoreProvider)!;
    c
      ..listen(activeDownloadQueueProvider, (_, __) {})
      ..listen(activeDownloadCountProvider, (_, __) {})
      ..listen(downloadedSeriesProvider, (_, __) {});

    // Gate open: save two chapters and a narration of "hot", queue a third, add a bookmark and a
    // progress row; "plain" is a control.
    await _complete(store, _c1);
    await _complete(store, _c2);
    await _complete(store, audioIdentity(_c1), kind: DownloadKind.audio);
    await _complete(store, _plain);
    await store.ensureQueued(id: _c3);
    await store.saveBookmark(Bookmark(
      clientId: 'b1',
      sourceId: 'src',
      seriesKey: 'hot',
      chapterKey: 'c1',
      chapterNumber: 1,
      anchorTotal: 5,
      createdAt: DateTime.utc(2026, 9, 5),
      updatedAt: DateTime.utc(2026, 9, 5),
    ));
    await store.enqueueProgress(const ProgressPush(sourceId: 'src', seriesKey: 'hot', chapterKey: 'c1', lastPage: 1));
    final prefs = rig.prefs;
    final followKey = followedSeriesCacheKeyFor(GateRig.scope);
    final bytesOpen = await store.scopeBytes();

    // The queue revision is what re-fetches these in the app; the fixed queue never bumps it.
    Future<List<String>> shelf() async {
      c.invalidate(downloadedSeriesProvider);
      return [for (final g in await c.read(downloadedSeriesProvider.future)) g.seriesKey];
    }

    // Open: everything is there, the queued chapter is startable.
    expect(await shelf(), containsAll(['hot', 'plain']));
    c.invalidate(activeDownloadQueueProvider);
    expect((await c.read(activeDownloadQueueProvider.future)).map((r) => r.chapterKey), contains('c3'));
    expect(c.read(activeDownloadCountProvider), greaterThan(0));
    expect(await store.pendingChapters(), isNotEmpty);
    expect(readCachedFollowedSeries(prefs, followKey), hasLength(2));

    // Closed: none of it, nothing says so, the total is unchanged, the queue skips it.
    rig.gate(false);
    expect(await shelf(), ['plain']);
    c.invalidate(activeDownloadQueueProvider);
    expect(await c.read(activeDownloadQueueProvider.future), isEmpty);
    expect(c.read(activeDownloadCountProvider), 0);
    expect(await store.listBookmarks(hideMature: true), isEmpty);
    expect(await store.pendingProgressOutbox(hideMature: true), isEmpty);
    expect(await store.pendingProgressOutbox(), hasLength(1), reason: 'the outbox still flushes every row');
    expect(await store.pendingChapters(hideMature: true), isEmpty, reason: 'the queued chapter is not started');
    expect(readCachedFollowedSeries(prefs, followKey, gateOpen: false).map((s) => s.seriesKey), ['plain']);
    expect(await store.readSavedNarration(_c1, hideMature: true), isNull);
    expect(
      () => buildOfflineReaderChapter(store, _c1, hideMature: true),
      throwsA(isA<ApiError>().having((e) => e.code, 'code', 'series_not_found')),
    );
    expect(await store.scopeBytes(), bytesOpen);

    // Reopened: everything returns and the queued chapter is startable again.
    rig.gate(true);
    c.invalidate(activeDownloadQueueProvider);
    expect(await shelf(), containsAll(['hot', 'plain']));
    expect((await c.read(activeDownloadQueueProvider.future)).map((r) => r.chapterKey), contains('c3'));
    expect(await store.pendingChapters(), isNotEmpty);
    expect(await store.listBookmarks(), hasLength(1));
    expect(readCachedFollowedSeries(prefs, followKey), hasLength(2));

    // The override flips to "not 18+": restamped everywhere, visible with the gate closed.
    rig.gate(false);
    expect(await shelf(), ['plain']);
    await c.read(matureStamperProvider).restampSeries('src', 'hot', false, rating: 'safe', matureOverride: false, overrideGiven: true);
    expect(await shelf(), containsAll(['hot', 'plain']));
    expect(await store.listBookmarks(hideMature: true), hasLength(1));
    expect(await store.pendingProgressOutbox(hideMature: true), hasLength(1));
    expect(readCachedFollowedSeries(prefs, followKey, gateOpen: false), hasLength(2));
    expect(await store.scopeBytes(), bytesOpen);
  });

  test('nothing says that files are hidden: the lists match a world where the series never existed', () async {
    final hidden = await gateRig(follows: [follow(1, 'hot', rating: 'mature')]);
    final never = await gateRig();
    addTearDown(() async {
      hidden.container.dispose();
      never.container.dispose();
      await hidden.harness.dispose();
      await never.harness.dispose();
    });
    final a = hidden.container.read(downloadsStoreProvider)!;
    await _complete(a, _c1);
    await _complete(a, _plain);
    final b = never.container.read(downloadsStoreProvider)!;
    await _complete(b, _plain);
    hidden.gate(false);
    never.gate(false);
    List<String> keys(List<dynamic> g) => [for (final x in g) '${x.seriesKey}:${x.chapters.length}'];
    hidden.container.invalidate(downloadedSeriesProvider);
    never.container.invalidate(downloadedSeriesProvider);
    expect(keys(await hidden.container.read(downloadedSeriesProvider.future)), keys(await never.container.read(downloadedSeriesProvider.future)));
    expect(hidden.container.read(activeDownloadCountProvider), never.container.read(activeDownloadCountProvider));
    expect((await hidden.container.read(activeDownloadQueueProvider.future)).length, (await never.container.read(activeDownloadQueueProvider.future)).length);
  });
}
