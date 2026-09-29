import 'package:flutter/widgets.dart' show StringCharacters;

/// The Tonight headline composer (cinematic 9.1.2). Pure: the clock is an argument.

/// Which row of the 9.1.2 table.
enum HeadlineCase {
  /// 1: a followed series in progress with new chapters.
  newChapters,

  /// 2: a chapter in progress.
  inProgress,

  /// 3: a followed series paused 7-60 days.
  paused,

  /// 4: the top AI pick.
  aiPick,

  /// 4b: just onboarded (follows, nothing read).
  firstPick,

  /// 5: a new profile.
  newProfile,

  /// Caught up everywhere.
  caughtUp,
}

class HeadlineInput {
  const HeadlineInput({
    required this.kind,
    required this.now,
    this.title,
    this.chapter,
    this.page,
    this.pageCount,
    this.daysAgo,
    this.pausedDays,
    this.recapReady = false,
    this.deck,
    this.atRisk = false,
    this.streakDays = 0,
  });

  final HeadlineCase kind;
  final DateTime now;

  /// The cover series title.
  final String? title;

  /// The chapter number the button opens (the printed number, as text: `143`, `12.5`).
  final String? chapter;

  /// Case 2: the page reached and the chapter's page count.
  final int? page, pageCount;

  /// Case 2: whole days since the last read. Case 3 uses [pausedDays].
  final int? daysAgo, pausedDays;

  /// Case 3: `recap.available`.
  final bool recapReady;

  /// Case 1 and 4: the AI one-liner, or the synopsis / `why` when the AI is off.
  final String? deck;
  final bool atRisk;
  final int streakDays;
}

class HeadlineResult {
  const HeadlineResult(this.headline, this.deck, {this.titleInKicker = false});
  final String headline, deck;
  final bool titleInKicker;
}

const int kHeadlineMax = 60;

/// "This morning" 05-11, "This afternoon" 12-17, "Tonight" otherwise.
String timeWord(DateTime now) {
  final h = now.hour;
  if (h >= 5 && h <= 11) return 'This morning';
  if (h >= 12 && h <= 17) return 'This afternoon';
  return 'Tonight';
}

const _ones = [
  'zero', 'one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight', 'nine', 'ten', 'eleven', 'twelve', //
  'thirteen', 'fourteen', 'fifteen', 'sixteen', 'seventeen', 'eighteen', 'nineteen',
];
const _tens = ['', '', 'twenty', 'thirty', 'forty', 'fifty', 'sixty', 'seventy', 'eighty', 'ninety'];

String _under100(int n) {
  if (n < 20) return _ones[n];
  final t = _tens[n ~/ 10], o = n % 10;
  return o == 0 ? t : '$t-${_ones[o]}';
}

/// [n] in words ("twelve", "thirty-one", "one hundred and one"), capitalised by default because
/// the callers open a sentence with it.
String spellCount(int n, {bool capitalise = true}) {
  var s = switch (n) {
    < 0 => '${n.abs()}',
    < 100 => _under100(n),
    < 1000 => n % 100 == 0 ? '${_ones[n ~/ 100]} hundred' : '${_ones[n ~/ 100]} hundred and ${_under100(n % 100)}',
    _ => '$n',
  };
  if (capitalise && s.isNotEmpty) s = s[0].toUpperCase() + s.substring(1);
  return s;
}

int _len(String s) => s.characters.length;

String _agoWords(int days) {
  if (days <= 0) return 'today';
  if (days == 1) return 'yesterday';
  return '${days < 10 ? spellCount(days, capitalise: false) : '$days'} days ago';
}

/// The 9.1.2 table, verbatim, with the 60-grapheme fallbacks.
HeadlineResult composeHeadline(HeadlineInput i) {
  final tw = timeWord(i.now);
  final title = i.title ?? '';
  final ch = i.chapter;

  if (i.atRisk && i.streakDays >= 2 && i.kind != HeadlineCase.newProfile && i.kind != HeadlineCase.caughtUp) {
    var line = '${spellCount(i.streakDays)} days and counting. One chapter keeps it alive.';
    if (_len(line) > kHeadlineMax) line = 'Your ${i.streakDays}-day streak ends at midnight.';
    return HeadlineResult(line, 'Open any chapter before midnight to keep your streak.');
  }

  switch (i.kind) {
    case HeadlineCase.newChapters:
      final full = '$tw: chapter $ch of $title.';
      final fits = _len(full) <= kHeadlineMax;
      return HeadlineResult(fits ? full : '$tw: chapter $ch.', i.deck ?? 'New chapters are waiting on your shelf.', titleInKicker: !fits);
    case HeadlineCase.inProgress:
      final left = (i.pageCount ?? 0) - (i.page ?? 0);
      final first = '$tw: finish chapter $ch.';
      final second = left > 0 ? ' ${spellCount(left)} ${left == 1 ? 'page' : 'pages'} left.' : '';
      final full = '$first$second';
      final deck = (i.page != null && i.pageCount != null && i.pageCount! > 0)
          ? 'You were on page ${i.page} of ${i.pageCount} ${_agoWords(i.daysAgo ?? 0)}.'
          : 'You were part-way through ${_agoWords(i.daysAgo ?? 0)}.';
      return HeadlineResult(_len(full) <= kHeadlineMax ? full : first, deck);
    case HeadlineCase.paused:
      final full = '$tw: back to $title.';
      final fits = _len(full) <= kHeadlineMax;
      final days = i.pausedDays ?? i.daysAgo ?? 0;
      final deck = 'You paused $days days ago at chapter $ch.${i.recapReady ? ' Previously on is ready.' : ''}';
      return HeadlineResult(fits ? full : '$tw: back to chapter $ch.', deck, titleInKicker: !fits);
    case HeadlineCase.aiPick:
      final full = '$tw: start $title.';
      final fits = _len(full) <= kHeadlineMax;
      return HeadlineResult(fits ? full : '$tw: start chapter 1.', i.deck ?? '', titleInKicker: !fits);
    case HeadlineCase.firstPick:
      final full = '$tw: start $title.';
      final fits = _len(full) <= kHeadlineMax;
      return HeadlineResult(fits ? full : '$tw: start chapter 1.', 'Chapter 1 is waiting. The rest of your picks are below.', titleInKicker: !fits);
    case HeadlineCase.newProfile:
      return const HeadlineResult('Your first issue starts here.', 'Follow three series and this page fills itself in.');
    case HeadlineCase.caughtUp:
      return HeadlineResult("$tw: you're caught up.", "Nothing new on your shelf. Here's something else.");
  }
}
