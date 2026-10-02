import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/reader/models/reading_progress.dart';
import 'package:manhwamaniacs/features/reader/repositories/reader_repository.dart';
import 'package:manhwamaniacs/features/sources/models/source_chapter_progress.dart';
import 'package:manhwamaniacs/features/sources/models/source_series.dart';
import 'package:manhwamaniacs/features/sources/providers/source_progress_provider.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';
import 'package:manhwamaniacs/skins/glass/screens/series/series_data.dart';

class _FailingReader implements ReaderRepository {
  @override
  Future<Result<({int saved, int advanced})>> saveProgressBatch(List<ProgressPush> pushes) async => const Err(NetworkError(message: 'down'));
  @override
  Future<Result<void>> deleteProgress({required String sourceId, required String seriesKey, required List<String> chapterKeys}) async => const Err(NetworkError(message: 'down'));
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _Local extends SourceProgressNotifier {
  final List<String> forgot = [];
  @override
  Map<String, SourceChapterProgress> build() => const {};
  @override
  Future<Map<String, SourceChapterProgress>> forget({required String sourceId, required String seriesId, required Iterable<String> chapterIds}) async {
    forgot.addAll(chapterIds);
    return const {};
  }
}

void main() {
  testWidgets('a failed Mark read or Mark unread reports null and keeps device progress', (t) async {
    late WidgetRef ref;
    final local = _Local();
    final done = SourceChapterProgress(page: 20, pageCount: 20, completed: true, updatedAt: DateTime.utc(2026));
    await t.pumpWidget(ProviderScope(
      overrides: [
        readerRepositoryProvider.overrideWithValue(_FailingReader()),
        sourceProgressProvider.overrideWith(() => local),
        sourceSeriesServerProgressProvider.overrideWith((r, k) async => {'c1': done}),
        sourceSeriesProgressProvider.overrideWith((r, k) => {'c1': done}),
      ],
      child: Consumer(builder: (c, r, _) {
        ref = r;
        return const SizedBox();
      },),
    ),);
    const c1 = SourceChapterSummary(id: 'c1', sourceId: 's', seriesId: 'x', title: 'One', number: 1, pageCount: 20);
    const d = GlassSeriesData(
      sourceId: 's',
      seriesKey: 'x',
      series: SourceSeriesSummary(id: 'x', sourceId: 's', title: 'X', chapterCount: 1, genres: [], coverUrl: ''),
      chapters: [c1],
    );
    final marks = SeriesMarks(ref, d);
    expect(await marks.markRead([c1]), isNull);
    expect(await marks.markUnread(['c1']), isNull);
    expect(local.forgot, isEmpty);
    expect(await marks.undoMarkRead(const {}, ['c1']), isFalse);
    expect(await marks.undoMarkUnread({'c1': done}), isFalse);
  });
}
