import 'package:manhwamaniacs/features/library/models/library_statistics.dart';

/// The day with the most pages; ties go to the latest date. Null when no day has a page.
DailyActivity? bestPagesDay(List<DailyActivity> daily) {
  DailyActivity? best;
  for (final d in daily) {
    if (d.pagesRead <= 0) continue;
    if (best == null || d.pagesRead > best.pagesRead || (d.pagesRead == best.pagesRead && d.date.isAfter(best.date))) best = d;
  }
  return best;
}

/// Days with at least one page.
int daysRead(List<DailyActivity> daily) => daily.where((d) => d.pagesRead > 0).length;

/// One Monday-first week of the Year bars.
class WeekTotal {
  const WeekTotal({required this.start, required this.pages, required this.chapters, required this.seconds, required this.days});
  final DateTime start;
  final int pages;
  final int chapters;
  final int seconds;
  final int days;
}

DateTime _mondayOf(DateTime d) => DateTime(d.year, d.month, d.day - (d.weekday - 1));

/// Weekly totals, Monday first, oldest first. A partial first or last week is kept.
List<WeekTotal> weeklyTotals(List<DailyActivity> daily) {
  final out = <DateTime, List<DailyActivity>>{};
  for (final d in daily) {
    out.putIfAbsent(_mondayOf(d.date), () => []).add(d);
  }
  final keys = out.keys.toList()..sort();
  return [
    for (final k in keys)
      WeekTotal(
        start: k,
        pages: out[k]!.fold(0, (a, d) => a + d.pagesRead),
        chapters: out[k]!.fold(0, (a, d) => a + d.chaptersRead),
        seconds: out[k]!.fold(0, (a, d) => a + d.secondsRead),
        days: out[k]!.where((d) => d.pagesRead > 0).length,
      ),
  ];
}

/// Heat level of a day's pages: 0 (0), 1 (1-19), 2 (20-59), 3 (60-149), 4 (150 and more).
int heatLevel(int pages) => pages <= 0
    ? 0
    : pages < 20
        ? 1
        : pages < 60
            ? 2
            : pages < 150
                ? 3
                : 4;

enum ClockBand { night, early, day, evening }

class ClockReading {
  const ClockReading(this.band, this.peakHour);
  final ClockBand band;
  final int peakHour;
}

ClockBand bandOfHour(int hour) {
  final h = hour % 24;
  if (h >= 22 || h < 5) return ClockBand.night;
  if (h < 9) return ClockBand.early;
  if (h < 17) return ClockBand.day;
  return ClockBand.evening;
}

/// The band holding the most pages (ties go to the earlier band in `night, early, day, evening` order) and the busiest hour
/// (ties go to the earlier hour). Null when nothing was read.
ClockReading? clockBand(List<HourActivity> hours) {
  final perBand = {for (final b in ClockBand.values) b: 0};
  var peak = -1;
  var peakPages = 0;
  for (final h in hours) {
    if (h.pagesRead <= 0) continue;
    perBand[bandOfHour(h.hour)] = perBand[bandOfHour(h.hour)]! + h.pagesRead;
    if (h.pagesRead > peakPages || (h.pagesRead == peakPages && h.hour < peak)) {
      peakPages = h.pagesRead;
      peak = h.hour;
    }
  }
  if (peak < 0) return null;
  var best = ClockBand.night;
  for (final b in ClockBand.values) {
    if (perBand[b]! > perBand[best]!) best = b;
  }
  return ClockReading(best, peak);
}
