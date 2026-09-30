import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/library/models/reading_history_item.dart';
import 'package:manhwamaniacs/features/library/utils/history_continue.dart';
import 'package:manhwamaniacs/features/sources/models/source_series.dart';
import 'package:manhwamaniacs/features/sources/repositories/sources_repository.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

ReadingHistoryItem _item({required bool done, String chapter = 'c1', int page = 12}) =>
    ReadingHistoryItem(id: 1, sourceId: 's', seriesKey: 'k', chapterKey: chapter, lastPage: page, pageCount: 40, isCompleted: done);

class _Sources implements SourcesRepository {
  _Sources(this.chapters);
  final List<SourceChapterSummary> chapters;
  int calls = 0;
  @override
  Future<Result<List<SourceChapterSummary>>> getChapters(String sourceId, String seriesKey) async {
    calls++;
    return Ok(chapters);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

SourceChapterSummary _ch(String id, double n) => SourceChapterSummary(id: id, sourceId: 's', seriesId: 'k', title: 'Ch $n', number: n, pageCount: 10);

Future<(HistoryContinue, int)> _run(ReadingHistoryItem item, List<SourceChapterSummary> chapters) async {
  SharedPreferences.setMockInitialValues({});
  final repo = _Sources(chapters);
  final c = ProviderContainer(overrides: [
    sourcesRepositoryProvider.overrideWithValue(repo),
    sharedPrefsProvider.overrideWithValue(await SharedPreferences.getInstance()),
  ],);
  addTearDown(c.dispose);
  final r = await c.read(historyContinueProvider)(item);
  return (r, repo.calls);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('an unfinished chapter resumes at its stored page without asking for the chapter list', () async {
    final (r, calls) = await _run(_item(done: false), const []);
    expect((r.chapterKey, r.page, r.toSeriesPage, calls), ('c1', 12, false, 0));
  });

  test('a finished chapter moves on to the next one from page 1', () async {
    final (r, calls) = await _run(_item(done: true), [_ch('c1', 1), _ch('c2', 2)]);
    expect((r.chapterKey, r.page, r.toSeriesPage, calls), ('c2', 1, false, 1));
  });

  test('caught up falls back to the series page', () async {
    final (r, _) = await _run(_item(done: true, chapter: 'c2'), [_ch('c1', 1), _ch('c2', 2)]);
    expect((r.chapterKey, r.page, r.toSeriesPage), (null, null, true));
  });
}
