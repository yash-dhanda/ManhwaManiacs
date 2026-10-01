import 'package:manhwamaniacs/features/library/models/annual.dart';
import 'package:manhwamaniacs/features/library/models/library_statistics.dart' show HourActivity;
import 'package:manhwamaniacs/features/library/utils/reading_stats.dart';
import 'package:manhwamaniacs/features/library/utils/wrapped_cards.dart';
import 'package:manhwamaniacs/skins/glass/screens/stats/stats_format.dart';

/// The words of one Wrapped card (glass 9.2.3 table): eyebrow, headline, footnote. Figures are drawn separately.
class WrappedCopy {
  const WrappedCopy({required this.eyebrow, required this.headline, this.footnote = ''});
  final String eyebrow;
  final String headline;
  final String footnote;
}

String _lower(String s) => s.isEmpty ? s : s.toLowerCase();

/// The busiest month by chapters ("March"), or null when the year has none.
String? busiestMonth(Annual a) {
  var best = -1;
  var at = 0;
  for (var i = 0; i < a.chaptersByMonth.length; i++) {
    if (a.chaptersByMonth[i] > best) {
      best = a.chaptersByMonth[i];
      at = i;
    }
  }
  return best <= 0 ? null : kMonths[at];
}

/// Days for card 2: `(secondsRead / 86400).round()`.
int wrappedDays(Annual a) => (a.secondsRead / 86400).round();

int wrappedHours(Annual a) => (a.secondsRead / 3600).round();

DateTime? busiestDate(Annual a) => DateTime.tryParse('${a.busiestDay?['date'] ?? ''}');

int busiestChapters(Annual a) => (a.busiestDay?['chapters'] as num?)?.toInt() ?? 0;

String _seriesTitle(Object? m) => m is Map ? '${m['title'] ?? ''}'.trim() : '';

/// The two titles of card 9 (first, last), empty when missing.
({String first, String last, String firstMonth}) firstsLastsTitles(Annual a) {
  final fl = a.firstsLasts;
  final first = fl?['first'] as Map?;
  final last = fl?['last'] as Map?;
  final at = DateTime.tryParse('${first?['read_at'] ?? ''}');
  return (first: _seriesTitle(first?['series']), last: _seriesTitle(last?['series']), firstMonth: at == null ? '' : kMonths[at.toLocal().month - 1]);
}

String _pct(double w) => '${(w * 100).round()} %';

String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

/// The copy of [card] for [a]. [profileName] goes in card 1's footnote; [together] is the co-reader line of card 11.
WrappedCopy wrappedCopy(WrappedCard card, Annual a, {String profileName = '', String? togetherName, String? togetherTitle}) {
  final year = '${a.year}';
  switch (card) {
    case WrappedCard.cover:
      return WrappedCopy(eyebrow: year, headline: wrappedTitle(a) == WrappedTitle.soFar ? 'Your $year so far' : 'Your $year in chapters', footnote: profileName);
    case WrappedCard.time:
      return const WrappedCopy(eyebrow: 'TIME', headline: 'You read for', footnote: 'Counted while a chapter was open.');
    case WrappedCard.volume:
      final m = busiestMonth(a);
      return WrappedCopy(eyebrow: 'VOLUME', headline: '${groupThousands(a.chaptersRead)} chapters · ${groupThousands(a.pagesRead)} pages', footnote: m == null ? '' : 'Busiest month: $m');
    case WrappedCard.topFive:
      final top = a.topSeries.isEmpty ? null : a.topSeries.first;
      return WrappedCopy(eyebrow: 'YOUR TOP FIVE', headline: top?.title ?? '', footnote: top == null ? '' : '${(top.secondsRead / 3600).round()} h with ${top.title}');
    case WrappedCard.genres:
      final g = a.genres;
      final words = g.take(2).map((x) => _lower(x.genre)).toList();
      return WrappedCopy(
        eyebrow: 'GENRES',
        headline: words.isEmpty ? '' : (words.length == 1 ? 'Mostly ${words[0]}' : 'Mostly ${words[0]} and ${words[1]}'),
        footnote: g.take(3).map((x) => '${_cap(x.genre)} ${_pct(x.weight)}').join(' · '),
      );
    case WrappedCard.when:
      final band = clockBand([for (var h = 0; h < a.byHour.length; h++) HourActivity(hour: h, pagesRead: a.byHour[h])]);
      final w = bandWrapped(band?.band ?? ClockBand.night);
      return WrappedCopy(eyebrow: 'WHEN', headline: w.headline, footnote: w.footnote);
    case WrappedCard.streak:
      final s = a.longestStreak;
      return WrappedCopy(
          eyebrow: 'STREAK',
          headline: '${s.days} days in a row',
          footnote: s.start == null || s.end == null ? '' : 'From ${s.start!.day} ${monthShort(s.start!)} to ${s.end!.day} ${monthShort(s.end!)}',);
    case WrappedCard.busiestDay:
      final d = busiestDate(a);
      return WrappedCopy(eyebrow: 'BUSIEST DAY', headline: d == null ? '' : longDay(d));
    case WrappedCard.firstsLasts:
      final t = firstsLastsTitles(a);
      return WrappedCopy(eyebrow: 'FIRSTS AND LASTS', headline: 'From ${t.first} to ${t.last}');
    case WrappedCard.topSource:
      final s = a.topSources.isEmpty ? null : a.topSources.first;
      return WrappedCopy(eyebrow: 'WHERE IT CAME FROM', headline: s == null ? '' : 'Most of it came from ${s.name}');
    case WrappedCard.together:
      return WrappedCopy(eyebrow: 'TOGETHER', headline: 'You and ${togetherName ?? ''} both read ${togetherTitle ?? ''}');
    case WrappedCard.summary:
      return WrappedCopy(eyebrow: year, headline: 'Your year');
  }
}

/// The card title for the progress label: "Card 3 of 12: Volume".
String cardLabel(WrappedCard c, int index, int total) => 'Card ${index + 1} of $total: ${_cap(_name(c))}';

String _name(WrappedCard c) => switch (c) {
      WrappedCard.cover => 'cover',
      WrappedCard.time => 'time',
      WrappedCard.volume => 'volume',
      WrappedCard.topFive => 'top five',
      WrappedCard.genres => 'genres',
      WrappedCard.when => 'when',
      WrappedCard.streak => 'streak',
      WrappedCard.busiestDay => 'busiest day',
      WrappedCard.firstsLasts => 'firsts and lasts',
      WrappedCard.topSource => 'top source',
      WrappedCard.together => 'together',
      WrappedCard.summary => 'summary',
    };

/// The words of [card]'s share side: the same table, but every title, source and genre word comes from [d] (the card's
/// `shareEligible` data, drawn from `shareable` only), never from the on-screen lists (glass 9.2.4, 14.11).
WrappedCopy shareCopy(WrappedCard card, Annual a, ShareData d) {
  final base = wrappedCopy(card, a);
  switch (card) {
    case WrappedCard.topFive:
      final top = d.series.firstOrNull;
      return WrappedCopy(eyebrow: base.eyebrow, headline: top?.title ?? '', footnote: top == null || top.secondsRead <= 0 ? '' : '${(top.secondsRead / 3600).round()} h with ${top.title}');
    case WrappedCard.genres:
      final words = d.genres.take(2).map((x) => _lower(x.genre)).toList();
      return WrappedCopy(
        eyebrow: base.eyebrow,
        headline: words.isEmpty ? '' : (words.length == 1 ? 'Mostly ${words[0]}' : 'Mostly ${words[0]} and ${words[1]}'),
        footnote: d.genres.take(3).map((x) => '${_cap(x.genre)} ${_pct(x.weight)}').join(' · '),
      );
    case WrappedCard.firstsLasts:
      final f = d.first?.title, l = d.last?.title;
      return WrappedCopy(eyebrow: base.eyebrow, headline: f != null && l != null ? 'From $f to $l' : (f ?? l ?? ''));
    case WrappedCard.topSource:
      return WrappedCopy(eyebrow: base.eyebrow, headline: d.source == null ? '' : 'Most of it came from ${d.source!.name}');
    case WrappedCard.cover:
    case WrappedCard.time:
    case WrappedCard.volume:
    case WrappedCard.when:
    case WrappedCard.streak:
    case WrappedCard.busiestDay:
    case WrappedCard.summary:
      return base;
    case WrappedCard.together:
      return const WrappedCopy(eyebrow: '', headline: '');
  }
}
