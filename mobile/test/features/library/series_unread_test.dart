import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/library/utils/series_unread.dart';
import 'package:manhwamaniacs/features/reader/models/reading_progress.dart';
import 'package:manhwamaniacs/features/reader/repositories/reader_repository.dart';
import 'package:manhwamaniacs/features/sources/models/source_chapter_progress.dart';
import 'package:manhwamaniacs/features/sources/providers/source_progress_provider.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';

final _at = DateTime.utc(2026, 3, 4);

class _Reader implements ReaderRepository {
  final deleted = <String>[];
  final pushed = <ProgressPush>[];
  @override
  Future<Result<List<ReadingProgress>>> seriesProgress({required String sourceId, required String seriesKey}) async => Ok([
        ReadingProgress(id: 1, sourceId: sourceId, seriesKey: seriesKey, chapterKey: 'c1', chapterNumber: 1, lastPage: 20, pageCount: 20, scrollOffsetPx: 0, isCompleted: true, lastReadAt: _at, timeSpentSeconds: 60),
      ]);
  @override
  Future<Result<void>> deleteProgress({required String sourceId, required String seriesKey, required List<String> chapterKeys}) async {
    deleted.addAll(chapterKeys);
    return const Ok(null);
  }

  @override
  Future<Result<({int saved, int advanced})>> saveProgressBatch(List<ProgressPush> pushes) async {
    pushed.addAll(pushes);
    return Ok((saved: pushes.length, advanced: 0));
  }

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _Local extends SourceProgressNotifier {
  final forgot = <String>[];
  Map<String, SourceChapterProgress>? restored;
  @override
  Map<String, SourceChapterProgress> build() => const {};
  @override
  Future<Map<String, SourceChapterProgress>> forget({required String sourceId, required String seriesId, required Iterable<String> chapterIds}) async {
    forgot.addAll(chapterIds);
    return {'c1': SourceChapterProgress(page: 20, pageCount: 20, completed: true, updatedAt: _at)};
  }

  @override
  Future<void> restoreRecords({required String sourceId, required String seriesId, required Map<String, SourceChapterProgress> records}) async =>
      restored = records;
}

void main() {
  test('bulk Mark unread clears the phone records too; Undo keeps the read times and restores them', () async {
    final reader = _Reader();
    final local = _Local();
    final c = ProviderContainer(overrides: [
      readerRepositoryProvider.overrideWithValue(reader),
      sourceProgressProvider.overrideWith(() => local),
    ],);
    addTearDown(c.dispose);
    final r = await markSeriesUnread(c, sourceId: 's', seriesKey: 'x', keys: ['c1', 'c2']);
    expect(reader.deleted, ['c1', 'c2']);
    expect(local.forgot, ['c1', 'c2']);
    await r.value();
    expect(reader.pushed.single.chapterKey, 'c1');
    expect(reader.pushed.single.lastReadAt, _at);
    expect(local.restored!.keys, ['c1']);
  });
}
