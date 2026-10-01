import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/library/models/library_statistics.dart';
import 'package:manhwamaniacs/features/library/utils/you_cards.dart';

void main() {
  test('wrapped card year: December and January only', () {
    expect(wrappedCardYear(DateTime(2026, 11, 30)), isNull);
    expect(wrappedCardYear(DateTime(2026, 12)), 2026);
    expect(wrappedCardYear(DateTime(2026, 12, 31, 23, 59)), 2026);
    expect(wrappedCardYear(DateTime(2027, 1, 31)), 2026);
    expect(wrappedCardYear(DateTime(2027, 2)), isNull);
  });

  test('week summary pads a short window at the front', () {
    final daily = [
      for (var i = 0; i < 5; i++) DailyActivity(date: DateTime(2026, 9, 24 + i), secondsRead: 600 * (i + 1), chaptersRead: i),
    ];
    final w = weekSummary(daily);
    expect(w.sparkline, [0, 0, 600, 1200, 1800, 2400, 3000]);
    expect(w.seconds, 9000);
    expect(w.chapters, 10);
  });

  test('week summary keeps only the last 7 days', () {
    final daily = [for (var i = 0; i < 9; i++) DailyActivity(date: DateTime(2026, 9, 20 + i), secondsRead: i, chaptersRead: 1)];
    final w = weekSummary(daily);
    expect(w.sparkline, [2, 3, 4, 5, 6, 7, 8]);
    expect(w.chapters, 7);
  });

  test('duration forms', () {
    expect(formatDuration(3 * 3600 + 12 * 60), '3 h 12 min');
    expect(formatDuration(45 * 60 + 30), '45 min');
    expect(formatDuration(0), '0 min');
    expect(formatDuration(7200), '2 h');
  });
}
