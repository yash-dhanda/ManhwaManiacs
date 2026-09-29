import 'package:manhwamaniacs/features/downloads/models/download_chapter_state.dart';
import 'package:manhwamaniacs/features/downloads/models/downloaded_series_group.dart';
import 'package:manhwamaniacs/features/downloads/utils/mature_filter.dart';
import 'package:manhwamaniacs/features/library/models/followed_series.dart';

/// The offline edition of the shelf: the cached follows with at least one chapter saved on this
/// device, every row through the 18+ gate, so a closed gate hides mature rows without a trace.
List<FollowedSeries> offlineShelf({
  required List<FollowedSeries> cachedFollows,
  required List<DownloadedSeriesGroup> saved,
  required bool matureEnabled,
}) {
  final have = {for (final g in saved) if (g.chapters.any((c) => c.state == DownloadChapterState.complete)) '${g.sourceId} ${g.seriesKey}'};
  return filterMature(
    [for (final s in cachedFollows) if (have.contains('${s.sourceId} ${s.seriesKey}')) s],
    gateOpen: matureEnabled,
    isMature: (s) => isMatureLocal(
      resolvedRating: s.rating,
      matureOverride: s.matureOverride,
      contentRating: s.contentRating,
      sourceMature: false,
    ),
  );
}
