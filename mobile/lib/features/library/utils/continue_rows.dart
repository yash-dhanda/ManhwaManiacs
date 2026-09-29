import 'package:manhwamaniacs/core/network/api_image.dart';
import 'package:manhwamaniacs/features/library/models/continue_reading_item.dart';
import 'package:manhwamaniacs/features/library/models/followed_series.dart';
import 'package:manhwamaniacs/features/library/utils/cover_url.dart';
import 'package:manhwamaniacs/features/library/utils/series_identity.dart';

/// Which follow a continue row resumes: the one under the row's own key,
/// else — on Asura, which rotates its slug suffixes — the one naming the same
/// series under another suffix. The reader stores progress under the key it
/// was opened with, and Browse opens this week's key while the follow keeps
/// the one it was made under.
class ContinueFollowLookup {
  ContinueFollowLookup(Iterable<FollowedSeries> followed) {
    for (final series in followed) {
      _byKey.putIfAbsent(
        _pair(series.sourceId, series.seriesKey),
        () => series,
      );
      _byIdentity.putIfAbsent(
        _pair(series.sourceId, followIdentity(series)),
        () => series,
      );
    }
  }

  final Map<(String, String), FollowedSeries> _byKey = {};
  final Map<(String, String), FollowedSeries> _byIdentity = {};

  static (String, String) _pair(String sourceId, String key) => (sourceId, key);

  /// The follow [item] belongs to, or null when none does.
  FollowedSeries? find(ContinueReadingItem item) =>
      _byKey[_pair(item.sourceId, item.seriesKey)] ??
      _byIdentity[_pair(
        item.sourceId,
        seriesIdentityOf(item.sourceId, item.seriesKey),
      )];
}

/// The card's first line: the payload's title, else the follow's, else null
/// (the card then leads with the chapter, as it always did).
String? continueRowTitle(ContinueReadingItem item, FollowedSeries? follow) {
  final fromPayload = item.title;
  if (fromPayload != null && fromPayload.isNotEmpty) return fromPayload;
  final fromFollow = follow?.title.trim();
  return fromFollow == null || fromFollow.isEmpty ? null : fromFollow;
}

/// The card's art, absolute: the payload's cover, else the follow's, else
/// null — a text-only card, rather than a broken-image box.
String? continueRowCoverUrl(
  String apiBaseUrl,
  ContinueReadingItem item,
  FollowedSeries? follow,
) {
  final fromPayload = item.coverUrl;
  if (fromPayload != null && fromPayload.isNotEmpty) {
    return resolveApiResourceUrl(apiBaseUrl, fromPayload);
  }
  return follow == null ? null : followedSeriesCoverUrl(apiBaseUrl, follow);
}
