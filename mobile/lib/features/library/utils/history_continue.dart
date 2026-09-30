import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/content_mode/content_mode.dart';
import 'package:manhwamaniacs/features/content_mode/content_mode_controller.dart';
import 'package:manhwamaniacs/features/library/models/reading_history_item.dart';
import 'package:manhwamaniacs/features/library/utils/resume_location.dart';
import 'package:manhwamaniacs/features/sources/models/source_series.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';

/// Where a history row's Continue lands, skin-neutral: the screen maps it to its own reader
/// target. [toSeriesPage] means there is no chapter to name (caught up, a stale key, a failed
/// request): open the book's page instead.
typedef HistoryContinue = ({
  String sourceId,
  String seriesKey,
  String? chapterKey,
  int? page,
  bool isNovel,
  bool toSeriesPage,
});

/// Continue, by the one rule the continue-reading strip shares (`resume_location.dart`): an
/// unfinished chapter reopens at its stored position, a finished one moves on to the chapter
/// after it. Only a finished chapter needs the chapter list, so only that case waits on a request.
Future<HistoryContinue> resolveHistoryContinue(Ref ref, ReadingHistoryItem item) async {
  var chapters = const <SourceChapterSummary>[];
  if (item.isCompleted) {
    final result = await ref.read(sourcesRepositoryProvider).getChapters(item.sourceId, item.seriesKey);
    if (result.isOk) chapters = result.value;
  }
  final isNovel = ref.read(contentModeScopeProvider).modeOf(item.sourceId) == ContentMode.novel;
  final point = resumePointFor(
    chapterKey: item.chapterKey,
    lastPage: item.lastPage,
    isCompleted: item.isCompleted,
    chapters: chapters,
  );
  return (
    sourceId: item.sourceId,
    seriesKey: item.seriesKey,
    chapterKey: point?.chapterKey,
    page: point?.page,
    isNovel: isNovel,
    toSeriesPage: point == null,
  );
}

/// [resolveHistoryContinue] bound to a `Ref`, so a widget calls it with `ref.read`.
final historyContinueProvider = Provider<Future<HistoryContinue> Function(ReadingHistoryItem)>(
  (ref) => (item) => resolveHistoryContinue(ref, item),
  name: 'historyContinue',
);
