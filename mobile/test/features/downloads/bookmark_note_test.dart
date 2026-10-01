import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/downloads/providers/bookmark_outbox_provider.dart';
import 'package:manhwamaniacs/features/downloads/store/bookmarks_dao.dart';
import 'package:manhwamaniacs/features/downloads/store/downloads_store.dart';
import 'package:manhwamaniacs/features/reader/models/bookmark.dart';
import 'package:manhwamaniacs/features/reader/repositories/reader_repository.dart';

import '../../support/downloads_test_support.dart';

class _Repo implements ReaderRepository {
  final List<BookmarkOp> pushed = [];
  int rejected = 0;
  List<Bookmark> remote = const [];

  @override
  Future<Result<BookmarkSyncResult>> syncBookmarks(List<BookmarkOp> ops) async {
    pushed.addAll(ops);
    return Ok(BookmarkSyncResult(
      received: ops.length,
      created: 0,
      updated: ops.length,
      tombstoned: 0,
      rejected: rejected,
      serverIds: const {},
    ),);
  }

  @override
  Future<Result<List<Bookmark>>> listBookmarks({String? sourceId, String? seriesKey, DateTime? since, bool includeDeleted = false, int? limit, int offset = 0}) async => Ok(remote);

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

Bookmark _b() => Bookmark(
      clientId: 'c1',
      sourceId: 'demo',
      seriesKey: 'k',
      chapterKey: '14',
      chapterNumber: 14,
      anchorIndex: 7,
      anchorFraction: 0.5,
      anchorTotal: 11,
      createdAt: DateTime.utc(2026, 9, 5),
      updatedAt: DateTime.utc(2026, 9, 5),
    );

void main() {
  initSqfliteFfiForTests();
  late TestDownloadsHarness harness;
  late DownloadsStore store;
  setUp(() async {
    harness = await TestDownloadsHarness.create();
    store = harness.storeFor('u1p1');
  });
  tearDown(() async => harness.dispose());

  BookmarkOutboxController controller(_Repo repo) => BookmarkOutboxController(store: store, repository: repo, activeScopeId: () => 'u1p1');

  test('a note goes out as one upsert carrying the note and every position field', () async {
    await store.saveBookmark(_b());
    final repo = _Repo();
    final c = controller(repo);
    await c.flush();
    repo.pushed.clear();
    final saved = await c.setNote(_b(), '  the door was open  ');
    expect(saved?.note, 'the door was open');
    final op = repo.pushed.single.toJson();
    expect(op['op'], 'upsert');
    expect(op['note'], 'the door was open');
    expect((op['client_id'], op['anchor_index'], op['anchor_total'], op['chapter_key']), ('c1', 7, 11, '14'));
  });

  test('a refused edit whose bookmark the server has tombstoned throws BookmarkDeletedElsewhere', () async {
    await store.saveBookmark(_b());
    final repo = _Repo()
      ..rejected = 1
      ..remote = [_b().copyWith(deleted: true, deletedAt: DateTime.utc(2026, 9, 6), updatedAt: DateTime.utc(2026, 9, 6))];
    await expectLater(controller(repo).setNote(_b(), 'x'), throwsA(isA<BookmarkDeletedElsewhere>()));
  });

  test('the 409 code maps to the typed check', () {
    expect(isBookmarkDeleted(const ApiError(statusCode: 409, code: 'bookmark_deleted', message: 'gone')), isTrue);
    expect(isBookmarkDeleted(const ApiError(statusCode: 409, code: 'other', message: 'x')), isFalse);
  });

  test('restore is an upsert of every field under a fresh client id', () async {
    final repo = _Repo();
    final c = controller(repo);
    final withNote = _b().copyWith(note: 'keep me');
    await store.saveBookmark(withNote);
    await c.remove('c1');
    repo.pushed.clear();
    final back = await c.restore(withNote);
    expect(back!.clientId, isNot('c1'));
    final op = repo.pushed.single.toJson();
    expect((op['op'], op['note'], op['anchor_index'], op['chapter_key']), ('upsert', 'keep me', 7, '14'));
    expect((await store.listBookmarks()).map((b) => b.clientId), [back.clientId]);
  });
}
