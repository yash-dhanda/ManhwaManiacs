import 'package:manhwamaniacs/features/library/models/library_statistics.dart';
import 'package:manhwamaniacs/features/library/utils/reading_stats.dart';

// Pure words and numbers of "Your reading" (glass 9.2.1).

const kWeekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
const kMonths = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];

String weekdayShort(DateTime d) => kWeekdays[d.weekday - 1].substring(0, 3);
String monthShort(DateTime d) => kMonths[d.month - 1].substring(0, 3);

/// "Saturday 19 September".
String longDay(DateTime d) => '${kWeekdays[d.weekday - 1]} ${d.day} ${kMonths[d.month - 1]}';

/// "Sat 19 Sep".
String shortDay(DateTime d) => '${weekdayShort(d)} ${d.day} ${monthShort(d)}';

String plural(int n, String one, [String? many]) => '$n ${n == 1 ? one : (many ?? '${one}s')}';

String groupThousands(int n) {
  final s = n.abs().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return n < 0 ? '-$b' : b.toString();
}

/// "12 h 40 min", "412 h", "25 min", "0 min".
String fmtDuration(int seconds) {
  final m = (seconds / 60).round();
  if (m < 60) return '$m min';
  final h = m ~/ 60, r = m % 60;
  return r == 0 ? '$h h' : '$h h $r min';
}

/// "Last 30 days".
String rangeCaption(int days) => 'Last ${plural(days, 'day')}';

/// The summary sentence above the chapters-per-day chart.
String chapterSummary(List<DailyActivity> daily, int days) {
  final best = bestPagesDay(daily);
  if (best == null) return 'Nothing read in the last ${plural(days, 'day')}.';
  return 'Most on ${longDay(best.date)}: ${plural(best.pagesRead, 'page')}.';
}

/// The readout capsule of a day: "Mon 1 Sep · 42 pages · 3 chapters · 25 min", "so far" for today.
String dayReadout(DailyActivity d, {bool today = false}) =>
    '${shortDay(d.date)} · ${plural(d.pagesRead, 'page')} · ${plural(d.chaptersRead, 'chapter')} · ${fmtDuration(d.secondsRead)}${today ? ' · so far' : ''}';

String weekReadout(WeekTotal w) => 'Week of ${w.start.day} ${monthShort(w.start)} · ${plural(w.pages, 'page')} · ${plural(w.chapters, 'chapter')} · ${fmtDuration(w.seconds)}';

/// "Read on 18 of the last 30 days".
String daysReadLine(int read, int days) => 'Read on $read of the last $days days';

/// "8 of 10 min today".
String goalLine(int minutes, int goal) => '$minutes of $goal min today';

/// "Tuesday 22 September, 42 pages" for a dot.
String dotLabel(DailyActivity d) => '${longDay(d.date)}, ${plural(d.pagesRead, 'page')}';

/// The clock band as the card's word.
String bandTitle(ClockBand b) => switch (b) {
      ClockBand.night => 'Night owl',
      ClockBand.early => 'Early reader',
      ClockBand.day => 'Daytime reader',
      ClockBand.evening => 'Evening reader',
    };

/// The Wrapped card 6 sentences: (headline, footnote).
({String headline, String footnote}) bandWrapped(ClockBand b) => switch (b) {
      ClockBand.night => (headline: "You're a night reader", footnote: 'Most of it after 22:00.'),
      ClockBand.early => (headline: "You're an early reader", footnote: 'Most of it before 09:00.'),
      ClockBand.day => (headline: "You're a daytime reader", footnote: 'Most of it between 09:00 and 17:00.'),
      ClockBand.evening => (headline: "You're an evening reader", footnote: 'Most of it between 17:00 and 22:00.'),
    };

/// "UTC+05:30".
String utcOffsetLabel(int minutes) {
  final sign = minutes < 0 ? '-' : '+';
  final a = minutes.abs();
  return 'UTC$sign${(a ~/ 60).toString().padLeft(2, '0')}:${(a % 60).toString().padLeft(2, '0')}';
}

/// "27 Jul 2026".
String dateLabel(DateTime d) => '${d.day} ${monthShort(d)} ${d.year}';
