import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/downloads/models/chapter_identity.dart';
import 'package:manhwamaniacs/features/downloads/store/bookmarks_dao.dart';
import 'package:manhwamaniacs/features/downloads/store/downloads_db.dart';
import 'package:manhwamaniacs/features/downloads/store/downloads_store.dart';
import 'package:manhwamaniacs/features/reader/models/bookmark.dart';
import 'package:manhwamaniacs/features/reader/models/reading_progress.dart';
import 'package:sqflite/sqflite.dart';

import '../../support/downloads_test_support.dart';

const _id = (sourceId: 'src', seriesKey: 'hot', chapterKey: 'c1');
const _id2 = (sourceId: 'src', seriesKey: 'hot', chapterKey: 'c2');

Bookmark _bm() => Bookmark(
      id: null,
      clientId: 'b1',
      sourceId: 'src',
      seriesKey: 'hot',
      chapterKey: 'c1',
      chapterNumber: 1,
      mediaType: BookmarkMedia.manga,
      anchorIndex: 1,
      anchorFraction: 0,
      anchorTotal: 10,
      snippet: null,
      createdAt: DateTime.utc(2026, 9, 5, 9),
      updatedAt: DateTime.utc(2026, 9, 5, 10),
    );

const _push = ProgressPush(sourceId: 'src', seriesKey: 'hot', chapterKey: 'c1', lastPage: 2);

void main() {
  initSqfliteFfiForTests();
  late TestDownloadsHarness harness;
  setUp(() async => harness = await TestDownloadsHarness.create());
  tearDown(() async => harness.dispose());

  Future<int?> matureOf(Database db, String table) async =>
      (await db.query(table)).single['mature'] as int?;

  test('a v3 database upgrades to v4 with null stamps, and re-running changes nothing', () async {
    var db = await harness.openDatabase();
    final store = harness.storeFor('u1p1');
    await store.ensureQueued(id: _id);
    await store.saveBookmark(_bm());
    await store.enqueueProgress(_push);
    // Rewind to a v3 file: drop the stamp columns and the version.
    for (final t in ['saved_chapters', 'bookmarks', 'bookmark_outbox', 'progress_outbox']) {
      await db.execute('ALTER TABLE $t DROP COLUMN mature');
    }
    await db.execute('PRAGMA user_version = 3');
    await db.close();

    db = await openDownloadsDatabase(overridePath: '${harness.tempDir.path}/downloads.db');
    for (final t in ['saved_chapters', 'bookmarks', 'bookmark_outbox', 'progress_outbox']) {
      expect(await matureOf(db, t), isNull, reason: t);
    }
    expect((await db.query('saved_chapters')).single['series_key'], 'hot');
    await db.execute('PRAGMA user_version = 3');
    await db.close();
    db = await openDownloadsDatabase(overridePath: '${harness.tempDir.path}/downloads.db');
    expect((await db.query('saved_chapters')), hasLength(1));
    await db.close();
  });

  test('new rows take the stamp from the resolver; restamping flips every store', () async {
    var mature = true;
    final store = harness.storeFor('u1p1', matureResolver: (_, __) async => mature);
    final db = await harness.openDatabase();
    await store.ensureQueued(id: _id);
    await store.saveBookmark(_bm());
    await store.enqueueProgress(_push);
    for (final t in ['saved_chapters', 'bookmarks', 'bookmark_outbox', 'progress_outbox']) {
      expect(await matureOf(db, t), 1, reason: t);
    }
    expect(await store.listChapters(hideMature: true), isEmpty);
    expect(await store.listBookmarks(hideMature: true), isEmpty);
    expect(await store.pendingProgressOutbox(hideMature: true), isEmpty);
    expect(await store.pendingProgressOutbox(), hasLength(1));

    mature = false;
    await store.stampSeries('src', 'hot', false);
    expect(await store.listChapters(hideMature: true), hasLength(1));
    expect(await store.listBookmarks(hideMature: true), hasLength(1));
    expect(await store.pendingProgressOutbox(hideMature: true), hasLength(1));
  });

  test('unstamped rows are found and stamped only where missing', () async {
    final store = harness.storeFor('u1p1');
    await store.ensureQueued(id: _id);
    await store.ensureQueued(id: _id2);
    expect(await store.unstampedSeries(), {('src', 'hot')});
    await store.stampSeriesWhereMissing('src', 'hot', true);
    expect(await store.unstampedSeries(), isEmpty);
    await store.stampSeriesWhereMissing('src', 'hot', false); // already stamped: unchanged
    expect(await store.listChapters(hideMature: true), isEmpty);
  });

  test('the queue pick skips hidden rows while the gate is closed', () async {
    final store = harness.storeFor('u1p1', matureResolver: (_, __) async => true);
    await store.ensureQueued(id: _id);
    expect(await store.pendingChapters(hideMature: true), isEmpty);
    expect(await store.pendingChapters(), hasLength(1));
  });
}
