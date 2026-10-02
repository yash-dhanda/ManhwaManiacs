/// Which series a key names, on a source whose keys drift.
///
/// Asura rotates the eight hex digits it appends to every series slug every
/// few days, and every generation keeps resolving. A follow keeps the key it
/// was made under while the reader opens this week's one from Browse, so
/// "the same series" has to be asked of the slug without its suffix. This is
/// the backend's rule (`connectors/asurascans/mappers.py` `series_identity`),
/// and like it an identity is only ever compared, never fetched with.
library;

import 'package:manhwamaniacs/features/library/models/followed_series.dart';

/// The one source whose keys drift.
const String asuraSourceId = 'asurascans';

final RegExp _asuraSlugSuffix = RegExp(r'-[0-9a-f]{8}$');

/// [seriesKey] with Asura's rotating suffix taken off; the key itself on every
/// other source.
String seriesIdentityOf(String sourceId, String seriesKey) {
  if (sourceId != asuraSourceId) return seriesKey;
  // `series_id_to_api_key`: surrounding whitespace, then surrounding slashes.
  final key = seriesKey.trim().replaceAll(RegExp(r'^/+|/+$'), '');
  final bare = key.replaceFirst(_asuraSlugSuffix, '');
  return bare.isEmpty ? key : bare;
}

/// A follow's identity: the server's own answer where it sent one, else the
/// same rule applied here (a library cache written before the field existed).
String followIdentity(FollowedSeries series) =>
    series.seriesIdentity ?? seriesIdentityOf(series.sourceId, series.seriesKey);

/// The follow in [rows] for the series [sourceId]/[seriesKey]: the exact key first, else the same
/// series under a rotated key.
FollowedSeries? followFor(Iterable<FollowedSeries> rows, String sourceId, String seriesKey) {
  final id = seriesIdentityOf(sourceId, seriesKey);
  FollowedSeries? same;
  for (final f in rows) {
    if (f.sourceId != sourceId) continue;
    if (f.seriesKey == seriesKey) return f;
    if (followIdentity(f) == id) same ??= f;
  }
  return same;
}

/// The current follow of the series a `/library/:id` route resolved to ([pinned]). The route's id
/// dies on unfollow and an undo follows under a new one, so the cache is asked by series; [pinned]
/// itself only while the cache has not loaded.
FollowedSeries? pinnedFollow(FollowedSeries pinned, List<FollowedSeries>? cached) =>
    cached == null ? pinned : followFor(cached, pinned.sourceId, pinned.seriesKey);
