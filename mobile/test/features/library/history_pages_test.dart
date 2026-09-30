import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/library/models/reading_history_item.dart';
import 'package:manhwamaniacs/features/library/providers/history_pages_provider.dart';
import 'package:manhwamaniacs/features/library/repositories/library_repository.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';

ReadingHistoryItem _row(int i) => ReadingHistoryItem(id: i, sourceId: 's', seriesKey: 'k$i', chapterKey: 'c', lastPage: 1, pageCount: 10, isCompleted: false);

class _Repo implements LibraryRepository {
  _Repo(this.total);
  final int total;
  final List<({int limit, int offset, bool bySeries})> calls = [];
  bool fail = false;

  @override
  Future<Result<List<ReadingHistoryItem>>> readingHistory({int limit = 50, int offset = 0, bool bySeries = true}) async {
    calls.add((limit: limit, offset: offset, bySeries: bySeries));
    if (fail) return const Err(NetworkError(message: 'offline'));
    return Ok([for (var i = offset; i < offset + limit && i < total; i++) _row(i)]);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  test('nextHistoryOffset asks for more only while a page came back full', () {
    expect(nextHistoryOffset(const []), isNull);
    expect(nextHistoryOffset([List.generate(49, _row)]), isNull);
    expect(nextHistoryOffset([List.generate(50, _row)]), 50);
    expect(nextHistoryOffset([List.generate(50, _row), List.generate(50, _row)]), 100);
    expect(nextHistoryOffset([List.generate(50, _row), List.generate(7, _row)]), isNull);
  });

  test('loadEarlier appends the next 50 and stops on a short page', () async {
    final repo = _Repo(120);
    final c = ProviderContainer(overrides: [libraryRepositoryProvider.overrideWithValue(repo)]);
    addTearDown(c.dispose);
    c.listen(historyPagesProvider(true), (_, __) {});
    expect((await c.read(historyPagesProvider(true).future)).length, 1);
    final n = c.read(historyPagesProvider(true).notifier);
    expect(await n.loadEarlier(), isTrue);
    expect(await n.loadEarlier(), isTrue);
    final pages = c.read(historyPagesProvider(true)).value!;
    expect(pages.map((p) => p.length), [50, 50, 20]);
    expect(n.hasEarlier, isFalse);
    expect(repo.calls.map((x) => x.offset), [0, 50, 100]);
    expect(repo.calls.every((x) => x.bySeries), isTrue);
  });

  test('a failed page leaves the pages as they were', () async {
    final repo = _Repo(120);
    final c = ProviderContainer(overrides: [libraryRepositoryProvider.overrideWithValue(repo)]);
    addTearDown(c.dispose);
    c.listen(historyPagesProvider(false), (_, __) {});
    await c.read(historyPagesProvider(false).future);
    repo.fail = true;
    expect(await c.read(historyPagesProvider(false).notifier).loadEarlier(), isFalse);
    expect(c.read(historyPagesProvider(false)).value!.length, 1);
  });
}
