/// The device's mirror of `backend/core/content_rating.py` (`resolve_series_rating` order).
/// Skin-neutral: every skin and the legacy screens read local rows through [filterMature].
library;

const Set<String> kMatureContentRatings = {
  'pornographic',
  'erotica',
  'smut',
  'hentai',
  'adult',
  'mature',
  'nsfw',
  '18+',
  'r18',
  'r-18',
};

bool isMatureRating(String? r) =>
    r != null && kMatureContentRatings.contains(r.trim().toLowerCase());

/// The first genre whose trimmed lower-case form is a mature rating, else null.
String? ratingFromGenres(Iterable<String>? genres) {
  for (final g in genres ?? const <String>[]) {
    if (isMatureRating(g)) return g.trim().toLowerCase();
  }
  return null;
}

/// Whether a local series is 18+. Order: the server's resolved rating, then the per-series
/// override, then the content rating (or a genre hint), then the source's own flag. An `unknown`
/// resolved rating is not mature.
bool isMatureLocal({
  String? resolvedRating,
  bool? matureOverride,
  String? contentRating,
  Iterable<String>? genres,
  required bool sourceMature,
}) {
  final resolved = resolvedRating?.trim().toLowerCase();
  if (resolved == 'mature' || resolved == 'safe' || resolved == 'unknown') {
    return resolved == 'mature';
  }
  if (matureOverride != null) return matureOverride;
  final rating = contentRating ?? ratingFromGenres(genres);
  if (rating != null && rating.trim().isNotEmpty) return isMatureRating(rating);
  return sourceMature;
}

/// Drops mature rows unless the gate is open. A row whose stamp is still null counts as visible.
List<T> filterMature<T>(
  Iterable<T> rows, {
  required bool gateOpen,
  required bool Function(T) isMature,
}) =>
    gateOpen ? rows.toList() : rows.where((r) => !isMature(r)).toList();
