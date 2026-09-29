import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/library/models/library_statistics.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/numbers/chart_math.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/numbers/clock_copy.dart';

DailyActivity day(int d, int ch, {int s = 0}) => DailyActivity(date: DateTime(2026, 9, d), chaptersRead: ch, secondsRead: s, sessions: ch > 0 ? 1 : 0);

void main() {
  group('nice maxima', () {
    test('the smallest step at or above the day maximum', () {
      expect(niceMax(0), 5);
      expect(niceMax(5), 5);
      expect(niceMax(6), 10);
      expect(niceMax(21), 25);
      expect(niceMax(31), 50);
      expect(niceMax(500), 500);
      expect(niceMax(501), 1000);
    });

    test('minutes ladder', () {
      expect(niceMaxMinutes(0), 10);
      expect(niceMaxMinutes(100), 120);
      expect(niceMaxMinutes(500), 600);
    });
  });

  group('bars', () {
    test('width leaves 2 px gaps', () {
      const n = 30;
      final w = barWidth(358, n);
      expect(w * n + 2 * (n - 1), closeTo(358, 1e-9));
      expect(barLeft(358, n, 1), closeTo(w + 2, 1e-9));
    });

    test('label indices: 4, 6 and 6 labels', () {
      expect(labelIndices(7), [0, 2, 4, 6]);
      expect(labelIndices(30), [0, 6, 12, 18, 24, 29]);
      expect(labelIndices(90), [0, 18, 36, 54, 72, 89]);
    });

    test('nearest bar and hit column', () {
      expect(nearestBar(0, 358, 30), 0);
      expect(nearestBar(357, 358, 30), 29);
      expect(nearestBar(-1, 358, 30), isNull);
      expect(hitColumnWidth(10, 48), 48);
      expect(hitColumnWidth(60, 44), 60);
    });
  });

  group('copy', () {
    test('axis, readout and spoken time', () {
      expect(axisTime(100), '1 H 40 M');
      expect(axisTime(120), '2 H');
      expect(axisTime(25), '25 M');
      expect(axisTime(0), '0');
      expect(readoutTime(6000), '1 h 40 m');
      expect(spokenTime(6000), '1 hour 40 minutes');
      expect(spokenTime(7200), '2 hours');
    });

    test('day readout and semantics match the spec strings', () {
      final d = day(21, 12, s: 6000);
      expect(dayReadout(d), 'Mon 21 Sep · 12 chapters · 1 h 40 m');
      expect(daySemantics(d), '21 September, 12 chapters, 1 hour 40 minutes');
      expect(axisDate(d.date), '21 SEP');
    });

    test('summary line', () {
      final daily = [day(1, 3), day(2, 0), day(3, 9)];
      expect(rangeSummary('30 days', daily, daily[2]), '30 days: 12 chapters over 2 active days. Best day 3 Sep, 9 chapters.');
      expect(rangeSummary('7 days', [day(1, 0)], null), '7 days: 0 chapters over 0 active days.');
    });
  });

  group('heatmap', () {
    test('levels by chapters', () {
      expect([0, 1, 2, 3, 5, 6, 10, 11, 40].map(heatLevel), [0, 1, 1, 2, 2, 3, 3, 4, 4]);
      expect(kHeatSides, [10, 3, 5, 7, 10]);
    });

    test('53 x 7 grid, Monday first, ends on today', () {
      final today = DateTime(2026, 9, 29); // a Tuesday
      final grid = heatGrid([day(29, 4)], today);
      expect(grid, hasLength(53));
      expect(grid.every((c) => c.length == 7), isTrue);
      final last = grid.last;
      expect(last[1]!.date, today);
      expect(last[1]!.chapters, 4);
      expect(last[2], isNull);
      final all = grid.expand((c) => c).whereType<HeatCell>().toList();
      expect(all, hasLength(365));
      expect(all.first.date, today.subtract(const Duration(days: 364)));
    });

    test('month labels sit above the first week of a month', () {
      final grid = heatGrid(const [], DateTime(2026, 9, 29));
      final labels = monthLabelColumns(grid);
      expect(labels.values.toSet().length, greaterThanOrEqualTo(12));
      expect(labels.values, contains('JAN'));
      expect(labels.values, contains('DEC'));
    });

    test('year summary', () {
      expect(heatSummary([day(1, 3), day(2, 0)]), 'Last year: read on 1 of 365 days.');
    });
  });

  group('clock copy', () {
    List<int> hours(Map<int, int> m) => [for (var h = 0; h < 24; h++) m[h] ?? 0];

    test('bands', () {
      expect([21, 22, 4, 5, 11, 12, 16, 17].map(bandOfHour), [ClockBand.evening, ClockBand.night, ClockBand.night, ClockBand.morning, ClockBand.morning, ClockBand.afternoon, ClockBand.afternoon, ClockBand.evening]);
    });

    test('night reader', () {
      final r = readClock(hours({23: 700, 0: 100, 10: 100, 15: 100}));
      expect(r.band, ClockBand.night);
      expect(numbersClockSentence(r), 'A night reader: most of it after 22:00.');
      expect(annualClockLine(r), 'A night owl: 80 % after 22:00.');
    });

    test('the other three bands', () {
      expect(numbersClockSentence(readClock(hours({8: 900, 20: 100}))), 'An early reader: most of it before noon.');
      expect(numbersClockSentence(readClock(hours({13: 900, 20: 100}))), 'An afternoon reader: most of it between 12:00 and 17:00.');
      expect(numbersClockSentence(readClock(hours({19: 900, 8: 100}))), 'An evening reader: most of it between 17:00 and 22:00.');
      expect(annualClockLine(readClock(hours({8: 640, 20: 360}))), 'An early bird: 64 % before noon.');
      expect(annualClockLine(readClock(hours({13: 520, 8: 480}))), 'An afternoon reader: 52 % between 12:00 and 17:00.');
      expect(annualClockLine(readClock(hours({19: 580, 8: 420}))), 'An evening reader: 58 % between 17:00 and 22:00.');
    });

    test('below 40 % or empty is "at all hours"', () {
      final spread = readClock(hours({for (var h = 0; h < 24; h++) h: 100}));
      expect(spread.allHours, isTrue);
      expect(numbersClockSentence(spread), 'A reader at all hours.');
      expect(annualClockLine(readClock(hours({}))), 'A reader at all hours.');
    });

    test('hour semantics', () {
      expect(hourSemantics(22, 11400), '22:00, 3 hours 10 minutes');
      expect(hourSemantics(3, 0), '03:00, 0 minutes');
    });
  });
}
