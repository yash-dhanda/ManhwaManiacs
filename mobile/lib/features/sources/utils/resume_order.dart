import 'package:manhwamaniacs/features/sources/models/source_chapter_progress.dart';
import 'package:manhwamaniacs/features/sources/models/source_series.dart';

/// Chapters oldest to newest, unnumbered ones last (the reading order). Stable: chapters sharing a
/// number (one per scanlation group) keep the source's order.
List<SourceChapterSummary> readingOrderOf(List<SourceChapterSummary> chapters) {
  final numbered = [for (var i = 0; i < chapters.length; i++) if (chapters[i].number != null) (i, chapters[i])]
    ..sort((a, b) {
      final c = a.$2.number!.compareTo(b.$2.number!);
      return c != 0 ? c : a.$1.compareTo(b.$1);
    });
  return [for (final (_, c) in numbered) c, ...chapters.where((c) => c.number == null)];
}

/// The chapter Continue starts from: the newest-touched one. A batch of marks shares one stamp, so a
/// tie goes to the latest in [order].
String? lastTouchedKey(List<SourceChapterSummary> order, Map<String, SourceChapterProgress> progress) {
  final index = {for (var i = 0; i < order.length; i++) order[i].id: i};
  String? last;
  DateTime? at;
  for (final e in progress.entries) {
    final t = e.value.updatedAt;
    if (at == null || t.isAfter(at) || (t == at && (index[e.key] ?? -1) > (index[last] ?? -1))) {
      last = e.key;
      at = t;
    }
  }
  return last;
}

/// Where Continue goes after finishing `order[i]`: the next chapter that is not another upload of the
/// same number and not already read; null when everything after it is read.
int? nextUnreadAfter(List<SourceChapterSummary> order, int i, Map<String, SourceChapterProgress> progress) {
  final n = order[i].number;
  for (var j = i + 1; j < order.length; j++) {
    if (n != null && order[j].number == n) continue;
    if (!(progress[order[j].id]?.completed ?? false)) return j;
  }
  return null;
}

/// The stamp for manual Mark read rows: just under the newest real progress, so a mark never becomes
/// the chapter Continue resumes from; now when there is none. One stamp for the whole batch.
DateTime manualMarkStamp(Map<String, SourceChapterProgress> progress) {
  DateTime? newest;
  for (final p in progress.values) {
    if (newest == null || p.updatedAt.isAfter(newest)) newest = p.updatedAt;
  }
  return newest?.subtract(const Duration(seconds: 1)) ?? DateTime.now().toUtc();
}
