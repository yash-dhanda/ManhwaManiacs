import 'dart:math' as math;

import 'package:intl/intl.dart';
import 'package:manhwamaniacs/features/library/models/library_statistics.dart';

/// Pure maths of the Numbers charts (cinematic 9.2.3), tested in
/// `chart_math_test.dart`.

const List<double> kChapterSteps = [5, 10, 20, 25, 50, 100, 200, 500];

/// The smallest of 5, 10, 20, 25, 50, 100, 200, 500 at or above [max]; past
/// 500, the next multiple of 500.
double niceMax(num max) {
  for (final s in kChapterSteps) {
    if (max <= s) return s;
  }
  return (max / 500).ceil() * 500.0;
}

const List<double> kMinuteSteps = [10, 20, 30, 60, 90, 120, 180, 240, 360, 480];

/// The right axis: the smallest minute step at or above [minutes].
double niceMaxMinutes(num minutes) {
  for (final s in kMinuteSteps) {
    if (minutes <= s) return s;
  }
  return (minutes / 120).ceil() * 120.0;
}

/// Bar width `(plotWidth - 2 * (n - 1)) / n` with 2 px gaps.
double barWidth(double plotWidth, int n) => n <= 0 ? 0 : (plotWidth - 2 * (n - 1)) / n;

/// Left edge of bar [i].
double barLeft(double plotWidth, int n, int i) => i * (barWidth(plotWidth, n) + 2);

/// Which bars carry a date label: every 2nd for 7 days, every 6th for 30 and
/// every 18th for 90, counted from the first day, plus the final day.
List<int> labelIndices(int n) {
  final step = n <= 7 ? 2 : (n <= 30 ? 6 : 18);
  final out = <int>[for (var i = 0; i < n; i += step) i];
  if (n > 0 && out.last != n - 1) out.add(n - 1);
  return out;
}

/// The bar a horizontal offset [dx] falls on (nearest bar centre), or null
/// when outside the plot.
int? nearestBar(double dx, double plotWidth, int n) {
  if (n <= 0 || dx < 0 || dx > plotWidth) return null;
  final step = barWidth(plotWidth, n) + 2;
  return ((dx - barWidth(plotWidth, n) / 2) / step).round().clamp(0, n - 1);
}

/// Width of the invisible hit column of a bar: at least [minHit] (44 iOS /
/// 48 Android), or the bar width, whichever is larger.
double hitColumnWidth(double barW, double minHit) => math.max(barW, minHit);

String _plural(int n, String one, String many) => n == 1 ? one : many;

/// `1 H 40 M` for the right axis; whole hours `2 H`; minutes `25 M`; `0`.
String axisTime(num minutes) {
  final m = minutes.round();
  if (m <= 0) return '0';
  final h = m ~/ 60;
  final r = m % 60;
  if (h == 0) return '$r M';
  return r == 0 ? '$h H' : '$h H $r M';
}

/// `1 h 40 m` for the readout.
String readoutTime(int seconds) {
  final m = (seconds / 60).round();
  final h = m ~/ 60;
  final r = m % 60;
  if (h == 0) return '$r m';
  return r == 0 ? '$h h' : '$h h $r m';
}

/// `1 hour 40 minutes` for the semantics label.
String spokenTime(int seconds) {
  final m = (seconds / 60).round();
  final h = m ~/ 60;
  final r = m % 60;
  final parts = <String>[
    if (h > 0) '$h ${_plural(h, 'hour', 'hours')}',
    if (r > 0 || h == 0) '$r ${_plural(r, 'minute', 'minutes')}',
  ];
  return parts.join(' ');
}

final _readoutDate = DateFormat('EEE d MMM', 'en_US');
final _labelDate = DateFormat('d MMM', 'en_US');
final _spokenDate = DateFormat('d MMMM', 'en_US');
final _bestDate = DateFormat('d MMM', 'en_US');

/// "Mon 21 Sep".
String readoutDate(DateTime d) => _readoutDate.format(d);

/// "21 SEP" under the baseline.
String axisDate(DateTime d) => _labelDate.format(d).toUpperCase();

/// "21 September".
String spokenDate(DateTime d) => _spokenDate.format(d);

/// "14 Sep" for the best-day line.
String bestDate(DateTime d) => _bestDate.format(d);

/// "Mon 21 Sep · 12 chapters · 1 h 40 m".
String dayReadout(DailyActivity d) => '${readoutDate(d.date)} · ${d.chaptersRead} ${_plural(d.chaptersRead, 'chapter', 'chapters')} · ${readoutTime(d.secondsRead)}';

/// "21 September, 12 chapters, 1 hour 40 minutes".
String daySemantics(DailyActivity d) => '${spokenDate(d.date)}, ${d.chaptersRead} ${_plural(d.chaptersRead, 'chapter', 'chapters')}, ${spokenTime(d.secondsRead)}';

/// The lead of the summary line: `7 days`, `30 days`, `90 days`, `Last year`.
String rangeSentenceLabel(int days) => days >= 365 ? 'Last year' : '$days days';

/// "30 days: 184 chapters over 22 active days. Best day 14 Sep, 31 chapters."
String rangeSummary(String rangeLabel, List<DailyActivity> daily, DailyActivity? best) {
  final chapters = daily.fold<int>(0, (a, d) => a + d.chaptersRead);
  final active = daily.where((d) => d.chaptersRead > 0 || d.sessions > 0).length;
  final head = '$rangeLabel: $chapters ${_plural(chapters, 'chapter', 'chapters')} over $active active ${_plural(active, 'day', 'days')}.';
  if (best == null) return head;
  return '$head Best day ${bestDate(best.date)}, ${best.chaptersRead} ${_plural(best.chaptersRead, 'chapter', 'chapters')}.';
}

// ---- heatmap ----------------------------------------------------------------

/// 0 for none; 1-2 -> 1; 3-5 -> 2; 6-10 -> 3; 11+ -> 4.
int heatLevel(int chapters) => chapters <= 0
    ? 0
    : chapters <= 2
        ? 1
        : chapters <= 5
            ? 2
            : chapters <= 10
                ? 3
                : 4;

/// The level-1..4 square side in px.
const List<double> kHeatSides = [10, 3, 5, 7, 10];

class HeatCell {
  const HeatCell({required this.date, required this.chapters, required this.seconds});
  final DateTime date;
  final int chapters;
  final int seconds;
  int get level => heatLevel(chapters);
}

/// 53 columns (weeks, Monday first) x 7 rows for the year ending [today]; a
/// null cell is a day outside the range.
List<List<HeatCell?>> heatGrid(List<DailyActivity> daily, DateTime today) {
  final t = DateTime(today.year, today.month, today.day);
  final byDay = {for (final d in daily) DateTime(d.date.year, d.date.month, d.date.day): d};
  final start = t.subtract(const Duration(days: 364));
  final firstMonday = start.subtract(Duration(days: start.weekday - 1));
  final columns = <List<HeatCell?>>[];
  for (var w = 0; w < 53; w++) {
    final col = <HeatCell?>[];
    for (var r = 0; r < 7; r++) {
      final day = DateTime(firstMonday.year, firstMonday.month, firstMonday.day + w * 7 + r);
      if (day.isBefore(start) || day.isAfter(t)) {
        col.add(null);
      } else {
        final a = byDay[day];
        col.add(HeatCell(date: day, chapters: a?.chaptersRead ?? 0, seconds: a?.secondsRead ?? 0));
      }
    }
    columns.add(col);
  }
  return columns;
}

/// The column holding the first cell of each month, for the `JAN`..`DEC` labels.
Map<int, String> monthLabelColumns(List<List<HeatCell?>> grid) {
  final out = <int, String>{};
  final seen = <int>{};
  for (var c = 0; c < grid.length; c++) {
    for (final cell in grid[c]) {
      if (cell != null && cell.date.day <= 7 && seen.add(cell.date.month * 100 + cell.date.year)) {
        out[c] = DateFormat('MMM', 'en_US').format(cell.date).toUpperCase();
        break;
      }
    }
  }
  return out;
}

/// "Last year: read on 212 of 365 days."
String heatSummary(List<DailyActivity> daily) {
  final active = daily.where((d) => d.chaptersRead > 0 || d.sessions > 0).length;
  return 'Last year: read on $active of 365 days.';
}
