// ignore_for_file: avoid_dynamic_calls
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/downloads/models/saved_chapter.dart';
import 'package:manhwamaniacs/features/downloads/providers/downloads_scope.dart';
import 'package:manhwamaniacs/features/downloads/providers/mature_gate_provider.dart';
import 'package:manhwamaniacs/features/novels/novel_text/novel_text_index.dart';
import 'package:manhwamaniacs/features/novels/novel_text/novel_text_providers.dart';

import '../../../support/downloads_test_support.dart';

Future<void> saveNovel(dynamic store, String chapter, List<String> paras) async {
  final id = (sourceId: 'src', seriesKey: 's', chapterKey: chapter);
  final row = await store.ensureQueued(id: id, kind: DownloadKind.novel) as int;
  await store.updateManifestInfo(rowId: row, pageCount: 1);
  await store.saveNovelText(rowId: row, chapter: {'paragraphs': paras});
  await store.markCompleteIfAllPagesPresent(row);
}

void main() {
  initSqfliteFfiForTests();
  late TestDownloadsHarness h;
  setUp(() async => h = await TestDownloadsHarness.create());
  tearDown(() => h.dispose());

  ProviderContainer container() {
    final store = h.storeFor('u1p1');
    final c = ProviderContainer(overrides: [
      downloadsStoreProvider.overrideWithValue(store),
      matureGateOpenProvider.overrideWithValue(true),
      readingSeriesKeysProvider.overrideWithValue(const []),
    ],);
    addTearDown(c.dispose);
    return c;
  }

  test('no downloads, then backfill indexes and search answers', () async {
    final c = container();
    c.listen(novelTextSearchProvider('tower'), (_, __) {});
    expect((await c.read(novelTextSearchProvider('tower').future)).status, NovelTextStatus.noDownloads);

    final store = c.read(downloadsStoreProvider)!;
    await saveNovel(store, 'c1', ['the rabbit tower', 'plain']);
    await saveNovel(store, 'c2', ['another tower']);
    c.invalidate(downloadedNovelChaptersProvider);
    await c.read(novelTextBackfillProvider.notifier).start();
    expect(c.read(novelTextBackfillProvider), 0);
    final r = await c.read(novelTextSearchProvider('tower').future);
    expect(r.status, NovelTextStatus.ready);
    expect(r.hits, hasLength(2));
    expect((await c.read(novelTextSearchProvider('x').future)).status, NovelTextStatus.idle);
  });

  test('removing the download drops the index', () async {
    final c = container();
    final store = c.read(downloadsStoreProvider)!;
    await saveNovel(store, 'c1', ['the rabbit tower']);
    await c.read(novelTextBackfillProvider.notifier).start();
    final db = await store.database;
    expect(await NovelTextIndex(db).isIndexed('src', 's', 'c1'), isTrue);
    await store.deleteDownload((sourceId: 'src', seriesKey: 's', chapterKey: 'c1'));
    expect(await NovelTextIndex(db).isIndexed('src', 's', 'c1'), isFalse);
  });
}
