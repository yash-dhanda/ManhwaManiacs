import 'package:manhwamaniacs/core/utils/text_fold.dart';
import 'package:manhwamaniacs/features/downloads/models/download_chapter_state.dart';
import 'package:manhwamaniacs/features/downloads/models/downloaded_series_group.dart';
import 'package:manhwamaniacs/features/downloads/models/saved_chapter.dart';

/// The offline fallback of Search: downloaded series whose lower-cased, diacritics-folded title contains every query word. While the
/// 18+ gate is closed a series with any mature-stamped chapter is absent (never a placeholder). Only series with at least one ready
/// text or page chapter count; narration-only rows do not.
List<DownloadedSeriesGroup> searchDownloads(Iterable<DownloadedSeriesGroup> groups, String q, {required bool gateOpen}) {
  final words = foldDiacritics(q).toLowerCase().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  if (words.isEmpty) return const [];
  final out = <DownloadedSeriesGroup>[];
  for (final g in groups) {
    final title = foldDiacritics(g.seriesTitle ?? '').toLowerCase();
    if (!words.every(title.contains)) continue;
    final ready = g.chapters.any((c) => c.state == DownloadChapterState.complete && !c.kind.isAudio);
    if (!ready) continue;
    if (!gateOpen && g.chapters.any((SavedChapter c) => (c.mature ?? false))) continue;
    out.add(g);
  }
  return out;
}
