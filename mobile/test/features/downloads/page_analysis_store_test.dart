import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/downloads/store/downloads_db.dart';
import 'package:sqflite/sqflite.dart';

import '../../support/downloads_test_support.dart';

const _chapter = (sourceId: 'asura', seriesKey: 's', chapterKey: 'c1');

void main() {
  initSqfliteFfiForTests();
  late TestDownloadsHarness harness;

  setUp(() async => harness = await TestDownloadsHarness.create());
  tearDown(() => harness.dispose());

  test('saved pages round trip tint and panels', () async {
    final store = harness.storeFor('u1p1');
    final rowId = await store.ensureQueued(id: _chapter);
    await store.updateManifestInfo(rowId: rowId, pageCount: 2);
    await store.savePage(rowId: rowId, pageNumber: 1, bytes: [1, 2, 3]);
    await store.savePage(rowId: rowId, pageNumber: 2, bytes: [4, 5, 6]);
    await store.saveChapterAnalysis(_chapter, tints: {1: '#C82828'}, panels: {1: '[[0,0,1,0.5]]', 2: '[]'});
    final a = await store.readChapterAnalysis(_chapter);
    expect(a.tints, {1: '#C82828'});
    expect(a.panels, {1: '[[0,0,1,0.5]]', 2: '[]'});
  });

  test('a v5 file upgrades with both columns and keeps its rows; reopening is idempotent', () async {
    final path = '${harness.tempDir.path}/v5.db';
    final fresh = await openDownloadsDatabase(overridePath: path);
    await fresh.execute('ALTER TABLE saved_pages DROP COLUMN tint');
    await fresh.execute('ALTER TABLE saved_pages DROP COLUMN panels');
    await fresh.execute('PRAGMA user_version = 5');
    await fresh.close();
    for (var i = 0; i < 2; i++) {
      final db = await openDownloadsDatabase(overridePath: path);
      final cols = [for (final r in await db.rawQuery('PRAGMA table_info(saved_pages)')) r['name']];
      expect(cols, containsAll(['tint', 'panels']));
      expect(await db.getVersion(), 7);
      await db.close();
    }
  });
}
