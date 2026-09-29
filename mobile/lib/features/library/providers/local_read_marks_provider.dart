import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/downloads/providers/downloads_scope.dart';
import 'package:manhwamaniacs/features/downloads/providers/mature_gate_provider.dart';
import 'package:manhwamaniacs/features/downloads/utils/mature_filter.dart';
import 'package:manhwamaniacs/features/library/utils/followed_series_cache.dart';
import 'package:manhwamaniacs/features/library/utils/local_read_marks.dart';
import 'package:manhwamaniacs/features/sources/providers/source_progress_provider.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';

/// This phone's own reading records, indexed for the library cards.
///
/// Follows the store: it rebuilds when the reader records a page and when the
/// active profile changes (the store is per profile), so a card never shows
/// one persona's position under another's shelf. A card should `select` its
/// own series' [LocalReadMark] rather than watch this whole, so a page turn
/// in the reader rebuilds only the card whose answer moved.
///
/// While the 18+ gate is closed, series the device knows to be 18+ have no mark at all.
final localReadMarksProvider = Provider<LocalReadMarks>(
  (ref) {
    final records = ref.watch(sourceProgressProvider);
    final scope = ref.watch(activeDownloadsScopeIdProvider);
    var hidden = const <(String, String)>{};
    if (scope != null && !ref.watch(matureGateOpenProvider)) {
      final shelf = readCachedFollowedSeries(
        ref.read(sharedPrefsProvider),
        followedSeriesCacheKeyFor(scope),
      );
      hidden = {
        for (final s in shelf)
          if (isMatureLocal(
            resolvedRating: s.rating,
            matureOverride: s.matureOverride,
            contentRating: s.contentRating,
            sourceMature: false,
          ))
            (s.sourceId, s.seriesKey),
      };
    }
    return LocalReadMarks(records, hidden: hidden);
  },
  name: 'localReadMarks',
);
