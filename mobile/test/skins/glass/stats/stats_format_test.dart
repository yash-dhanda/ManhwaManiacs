import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/library/models/library_statistics.dart';
import 'package:manhwamaniacs/features/library/utils/reading_stats.dart';
import 'package:manhwamaniacs/skins/glass/screens/stats/stats_format.dart';

DailyActivity d(int day, int pages, {int ch = 1, int s = 600}) => DailyActivity(date: DateTime(2026, 9, day), pagesRead: pages, chaptersRead: ch, secondsRead: s);

void main() {
  test('durations, thousands and plurals', () {
    expect(fmtDuration(25 * 60), '25 min');
    expect(fmtDuration(0), '0 min');
    expect(fmtDuration(412 * 3600), '412 h');
    expect(fmtDuration(12 * 3600 + 40 * 60), '12 h 40 min');
    expect(groupThousands(38410), '38,410');
    expect(groupThousands(999), '999');
    expect(plural(1, 'page'), '1 page');
    expect(plural(0, 'page'), '0 pages');
  });

  test('sentences', () {
    expect(chapterSummary([d(19, 120), d(20, 5)], 30), 'Most on Saturday 19 September: 120 pages.');
    expect(chapterSummary([d(19, 0)], 7), 'Nothing read in the last 7 days.');
    expect(dayReadout(d(1, 42, ch: 3, s: 1500)), 'Tue 1 Sep · 42 pages · 3 chapters · 25 min');
    expect(dayReadout(d(1, 1), today: true), endsWith('so far'));
    expect(dotLabel(d(22, 42)), 'Tuesday 22 September, 42 pages');
    expect(daysReadLine(18, 30), 'Read on 18 of the last 30 days');
    expect(goalLine(8, 10), '8 of 10 min today');
    expect(utcOffsetLabel(330), 'UTC+05:30');
    expect(utcOffsetLabel(-300), 'UTC-05:00');
    expect(rangeCaption(365), 'Last 365 days');
    expect(bandTitle(ClockBand.night), 'Night owl');
    expect(bandWrapped(ClockBand.evening).footnote, 'Most of it between 17:00 and 22:00.');
  });
}
