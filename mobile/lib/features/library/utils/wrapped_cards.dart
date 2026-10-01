import 'package:manhwamaniacs/features/library/models/annual.dart';
import 'package:manhwamaniacs/features/library/models/shareable.dart';
import 'package:manhwamaniacs/features/sources/models/source_genre.dart' show GenreWeight;

/// The twelve Wrapped cards in §9.2.3 order.
enum WrappedCard {
  cover,
  time,
  volume,
  topFive,
  genres,
  when,
  streak,
  busiestDay,
  firstsLasts,
  topSource,
  together,
  summary;

  /// 1 to 12.
  int get number => index + 1;
}

enum WrappedTitle { soFar, inChapters }

/// Genre words no share card may draw (§8.7).
const kMatureGenres = ['Adult', 'Ecchi', 'Hentai', 'Mature', 'Smut'];

bool isMatureGenre(String g) => kMatureGenres.any((m) => m.toLowerCase() == g.trim().toLowerCase());

/// The cards to show, in order; empty ones are omitted. Card 11 needs [profileShares] and a circle member who finished a series with this profile.
List<WrappedCard> wrappedCards(Annual a, {required bool profileShares}) => [
      WrappedCard.cover,
      WrappedCard.time,
      WrappedCard.volume,
      if (a.topSeries.isNotEmpty) WrappedCard.topFive,
      if (a.genres.isNotEmpty) WrappedCard.genres,
      if (a.byHour.any((s) => s > 0)) WrappedCard.when,
      if (a.longestStreak.days > 0) WrappedCard.streak,
      if (a.busiestDay != null) WrappedCard.busiestDay,
      if (a.firstsLasts != null) WrappedCard.firstsLasts,
      if (a.topSources.isNotEmpty) WrappedCard.topSource,
      if (profileShares && (a.circle ?? const []).any((m) => m.finishedTogether.isNotEmpty)) WrappedCard.together,
      WrappedCard.summary,
    ];

/// Fewer than seven recorded days: no recap yet.
bool notEnoughData(Annual a) => a.recordedDays < 7;

/// "Your 2026 so far" while the year is partial, else "Your 2026 in chapters".
WrappedTitle wrappedTitle(Annual a) => a.partial ? WrappedTitle.soFar : WrappedTitle.inChapters;

/// What the share side of one card may draw.
class ShareData {
  const ShareData({this.series = const [], this.genres = const [], this.source, this.first, this.last});
  final List<ShareSeries> series;
  final List<GenreWeight> genres;
  final AnnualSource? source;
  final ShareSeries? first;
  final ShareSeries? last;
}

ShareSeries? _series(Object? raw, Set<String> matureSources) {
  if (raw is! Map<String, dynamic>) return null;
  final s = ShareSeries.fromJson(raw);
  return s.title.isEmpty || matureSources.contains(s.sourceId) ? null : s;
}

/// The data card [c] may put on a PNG, from `a.shareable` (and the server's non-mature busiest-day and firsts-lasts lists, filtered
/// again here); null when the card has no share side: card 11 always, and a card left with nothing eligible. Mature genres are
/// dropped, and a mature top source is skipped for the next eligible one ([matureSources] are the source ids the catalogue marks mature).
ShareData? shareEligible(WrappedCard c, Annual a, {Set<String> matureSources = const {}}) {
  final sh = a.shareable;
  final top = [for (final s in sh?.topSeries ?? const <ShareSeries>[]) if (!matureSources.contains(s.sourceId)) s];
  final genres = [for (final g in sh?.genreWeights ?? const <GenreWeight>[]) if (!isMatureGenre(g.genre)) g];
  switch (c) {
    case WrappedCard.together:
      return null;
    case WrappedCard.cover:
      return top.isEmpty ? null : ShareData(series: top.take(3).toList());
    case WrappedCard.time:
    case WrappedCard.volume:
    case WrappedCard.when:
    case WrappedCard.streak:
      return const ShareData();
    case WrappedCard.topFive:
      return top.isEmpty ? null : ShareData(series: top.take(5).toList());
    case WrappedCard.genres:
      return genres.isEmpty ? null : ShareData(genres: genres.take(8).toList());
    case WrappedCard.busiestDay:
      final list = a.busiestDay?['series'];
      final series = list is List ? [for (final s in list) _series(s, matureSources)].whereType<ShareSeries>().toList() : <ShareSeries>[];
      return ShareData(series: series.take(5).toList());
    case WrappedCard.firstsLasts:
      final fl = a.firstsLasts;
      final first = _series((fl?['first'] as Map?)?['series'], matureSources);
      final last = _series((fl?['last'] as Map?)?['series'], matureSources);
      return first == null && last == null ? null : ShareData(first: first, last: last);
    case WrappedCard.topSource:
      final src = a.topSources.where((s) => !matureSources.contains(s.sourceId)).toList();
      return src.isEmpty ? null : ShareData(source: src.first);
    case WrappedCard.summary:
      return ShareData(series: top.take(3).toList(), genres: genres.take(3).toList());
  }
}
