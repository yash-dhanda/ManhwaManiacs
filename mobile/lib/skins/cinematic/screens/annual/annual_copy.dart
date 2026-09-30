import 'package:intl/intl.dart';
import 'package:manhwamaniacs/features/library/models/annual.dart';
import 'package:manhwamaniacs/features/library/models/shareable.dart';
import 'package:manhwamaniacs/features/sources/models/source_genre.dart'
    show GenreWeight;
import 'package:manhwamaniacs/skins/cinematic/screens/numbers/numbers_format.dart';

/// Every copy rule of The Annual (cinematic 9.2.4) in one place, tested in
/// `annual_copy_test.dart`.

enum AnnualPageKind {
  cover,
  time,
  chapters,
  no1,
  genres,
  clock,
  streak,
  sources,
  circle,
  colophon,
  pressRun
}

class AnnualPageSpec {
  const AnnualPageSpec(this.kind, this.hold, this.title);
  final AnnualPageKind kind;

  /// Null: the story ends here (the press-run page).
  final Duration? hold;

  /// The page name announced on a page change ("Page 3 of 11: Chapters").
  final String title;
}

const _holdShort = Duration(seconds: 6);
const _holdList = Duration(seconds: 8);
const _holdColophon = Duration(seconds: 12);

/// The shown pages in order; pages whose data is empty are skipped and the
/// segments renumber.
List<AnnualPageSpec> annualPages(Annual a) => [
      const AnnualPageSpec(AnnualPageKind.cover, _holdShort, 'Cover'),
      const AnnualPageSpec(AnnualPageKind.time, _holdShort, 'Time'),
      const AnnualPageSpec(AnnualPageKind.chapters, _holdShort, 'Chapters'),
      if (a.topSeries.isNotEmpty)
        const AnnualPageSpec(AnnualPageKind.no1, _holdList, 'Your No. 1'),
      if (a.genres.isNotEmpty)
        const AnnualPageSpec(AnnualPageKind.genres, _holdShort, 'Genres'),
      if (a.byHour.any((s) => s > 0))
        const AnnualPageSpec(AnnualPageKind.clock, _holdShort, 'The clock'),
      if (a.longestStreak.days > 0)
        const AnnualPageSpec(AnnualPageKind.streak, _holdShort, 'The streak'),
      if (a.topSources.isNotEmpty)
        const AnnualPageSpec(AnnualPageKind.sources, _holdList, 'Sources'),
      if (circleShared(a).isNotEmpty)
        const AnnualPageSpec(AnnualPageKind.circle, _holdShort, 'The circle'),
      const AnnualPageSpec(
          AnnualPageKind.colophon, _holdColophon, 'End credits',),
      const AnnualPageSpec(AnnualPageKind.pressRun, null, 'Press run'),
    ];

/// The circle members who finished at least one series together with this profile.
List<CircleMember> circleShared(Annual a) => [
      for (final m in a.circle ?? const <CircleMember>[])
        if (m.finishedTogether.isNotEmpty) m,
    ];

const _digits = [
  'zero',
  'one',
  'two',
  'three',
  'four',
  'five',
  'six',
  'seven',
  'eight',
  'nine',
];

/// One to nine spelled; numerals from 10.
String spellSmall(int n) => n >= 0 && n <= 9 ? _digits[n] : fmt(n);

/// "You read for 212 hours." (under one hour, minutes).
String timeHeadline(int seconds) {
  if (seconds >= 3600) {
    final h = seconds ~/ 3600;
    return 'You read for ${fmt(h)} ${h == 1 ? 'hour' : 'hours'}.';
  }
  final m = (seconds / 60).round();
  return 'You read for $m ${m == 1 ? 'minute' : 'minutes'}.';
}

/// The hours figure inside [timeHeadline], for the typed range.
({int start, int end}) timeFigureRange(int seconds) {
  final head = timeHeadline(seconds);
  const start = 'You read for '.length;
  final end = head.indexOf(' ', start);
  return (start: start, end: end);
}

/// "That's nine days, cover to cover."; under a day and at least 12 h, "That's
/// most of a day, cover to cover."; below 12 h, null.
String? timeDeck(int seconds) {
  if (seconds < 43200) return null;
  if (seconds < 86400) return "That's most of a day, cover to cover.";
  final d = (seconds / 86400).round();
  return "That's ${spellSmall(d)} ${d == 1 ? 'day' : 'days'}, cover to cover.";
}

/// "4,812 chapters."
String chaptersHeadline(int n) =>
    '${fmt(n)} ${n == 1 ? 'chapter' : 'chapters'}.';

/// "Your most-read: {title}."
String no1Headline(String title) => 'Your most-read: $title.';

/// "38 CHAPTERS · 12 H" (credit line under the No. 1 cover).
String no1Credit(ShareSeries s) =>
    '${s.chaptersRead} ${s.chaptersRead == 1 ? 'CHAPTER' : 'CHAPTERS'} · ${_hoursCaps(s.secondsRead)}';

/// "38 CH · 12 H" for the ranked rows.
String rankFolio(ShareSeries s) =>
    '${s.chaptersRead} CH · ${_hoursCaps(s.secondsRead)}';

String _hoursCaps(int seconds) => seconds >= 3600
    ? '${fmt(seconds ~/ 3600)} H'
    : '${(seconds / 60).round()} M';

bool _vowel(String s) => s.isNotEmpty && 'aeiou'.contains(s[0].toLowerCase());

/// "A fantasy reader, with a streak of romance." / one genre "A fantasy reader
/// through and through." ("An" before a vowel sound).
String genresLine(List<GenreWeight> genres) {
  if (genres.isEmpty) return '';
  final g = [...genres]..sort((a, b) => b.weight.compareTo(a.weight));
  final first = g.first.genre.toLowerCase();
  final a = _vowel(first) ? 'An' : 'A';
  if (g.length == 1) return '$a $first reader through and through.';
  return '$a $first reader, with a streak of ${g[1].genre.toLowerCase()}.';
}

/// "Longest streak: 31 days, in March."
String streakLine(AnnualStreak s) {
  final days = '${s.days} ${s.days == 1 ? 'day' : 'days'}';
  final m = s.month;
  return m == null || m < 1 || m > 12
      ? 'Longest streak: $days.'
      : 'Longest streak: $days, in ${DateFormat('MMMM', 'en_US').format(DateTime(2000, m))}.';
}

/// "MangaDex did the heavy lifting."
String sourcesHeadline(String name) => '$name did the heavy lifting.';

/// "You and Riya both finished Solo Leveling."
String? circleLine(Annual a) {
  final shared = circleShared(a);
  if (shared.isEmpty) return null;
  return 'You and ${shared.first.name} both finished ${shared.first.finishedTogether.first}.';
}

/// "Your Annual needs a few more weeks of reading. 5 days recorded so far."
String notEnoughLine(int recordedDays) =>
    'Your Annual needs a few more weeks of reading. $recordedDays ${recordedDays == 1 ? 'day' : 'days'} recorded so far.';

/// The two sentences of [notEnoughLine]: the notice's headline (at most 60 graphemes) and deck.
(String, String) notEnoughParts(int recordedDays) => (
      'Your Annual needs a few more weeks of reading.',
      '$recordedDays ${recordedDays == 1 ? 'day' : 'days'} recorded so far.',
    );

/// "An issue about Yash's year in reading".
String coverDeck(String profile) => "An issue about $profile's year in reading";

/// `No. 1 · 29 SEPTEMBER 2026`.
String issueLine(int issue, DateTime date) =>
    'No. $issue · ${DateFormat('d MMMM y', 'en_US').format(date).toUpperCase()}';

/// The credit lines of the colophon, label first; the NARRATED BY line is
/// omitted when no voice is recorded and WITH only when the circle shared a series.
List<(String, String)> colophonLines(Annual a) => [
      ('STARRING', a.topSeries.take(5).map((s) => s.title).join('\n')),
      if (a.topSources.isNotEmpty)
        ('SHOT ON', a.topSources.map((s) => s.name).join(', ')),
      if (a.topVoices.isNotEmpty)
        ('NARRATED BY', a.topVoices.take(3).map((v) => v.name).join(', ')),
      if (circleShared(a).isNotEmpty)
        ('WITH', circleShared(a).map((m) => m.name).join(', ')),
      ('SET IN', 'Bodoni Moda, Archivo, Newsreader and IBM Plex Mono'),
      ('PRINTED ON', 'ManhwaManiacs'),
    ];

/// "See you in 2027."
String closingLine(int year) => 'See you in ${year + 1}.';
