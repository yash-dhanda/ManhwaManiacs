import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/downloads/store/downloads_db.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../support/downloads_test_support.dart';

void main() {
  initSqfliteFfiForTests();
  late TestDownloadsHarness harness;

  setUp(() async => harness = await TestDownloadsHarness.create());
  tearDown(() => harness.dispose());

  Map<String, Object?> session(String chapter, {int seconds = 60}) => {
        'source_id': 's',
        'series_key': 'b',
        'chapter_key': chapter,
        'seconds': seconds,
        'voice_ids': ['v1', 'v2'],
        'started_at': '2026-09-30T12:00:00.000Z',
      };

  test('sessions queue per scope, oldest first, and clear by id', () async {
    final a = harness.storeFor('u1p1');
    final b = harness.storeFor('u1p2');
    await a.enqueueListenSession(session('c1'));
    await a.enqueueListenSession(session('c2', seconds: 90));
    await b.enqueueListenSession(session('other'));

    final pending = await a.pendingListenSessions();
    expect(pending.map((e) => e.$2['chapter_key']), ['c1', 'c2']);
    expect(pending.first.$2['voice_ids'], ['v1', 'v2']);
    expect(pending.first.$2['started_at'], '2026-09-30T12:00:00.000Z');
    expect((await b.pendingListenSessions()).single.$2['chapter_key'], 'other');

    await a.clearListenSessions([pending.first.$1]);
    expect((await a.pendingListenSessions()).single.$2['chapter_key'], 'c2');
    // Another scope's ids are never touched.
    await a.clearListenSessions([(await b.pendingListenSessions()).single.$1]);
    expect(await b.pendingListenSessions(), hasLength(1));
  });

  group('schema v4 -> v5 migration', () {
    Future<void> createV4(String path) async {
      final db = await openDatabase(
        path,
        version: 4,
        onCreate: (db, _) async {
          await db.execute(
            'CREATE TABLE progress_outbox (id INTEGER PRIMARY KEY AUTOINCREMENT, scope_id TEXT NOT NULL, payload_json TEXT NOT NULL, created_at TEXT NOT NULL, mature INTEGER)',
          );
        },
      );
      await db.close();
    }

    test('adds the outbox and keeps existing tables', () async {
      final path = '${harness.tempDir.path}/v4.db';
      await createV4(path);
      final upgraded = await openDownloadsDatabase(overridePath: path);
      addTearDown(upgraded.close);
      expect(await upgraded.getVersion(), 5);
      final cols = (await upgraded.rawQuery('PRAGMA table_info(${DownloadsSchema.listenSessionOutbox})')).map((r) => r['name']).toSet();
      expect(cols, {'id', 'scope_id', 'source_id', 'series_key', 'chapter_key', 'seconds', 'voice_ids', 'started_at', 'created_at'});
      expect(await upgraded.query('progress_outbox'), isEmpty);
    });

    test('a downgrade-reopen re-runs the step without failing', () async {
      final path = '${harness.tempDir.path}/roundtrip.db';
      final current = await openDownloadsDatabase(overridePath: path);
      await current.insert(DownloadsSchema.listenSessionOutbox, {'scope_id': 'u1p1', 'seconds': 12});
      await current.close();
      final older = await openDatabase(path, version: 3);
      expect(await older.getVersion(), 3);
      await older.close();
      final reopened = await openDownloadsDatabase(overridePath: path);
      addTearDown(reopened.close);
      expect(await reopened.getVersion(), 5);
      expect(await reopened.query(DownloadsSchema.listenSessionOutbox), hasLength(1));
    });
  });
}
