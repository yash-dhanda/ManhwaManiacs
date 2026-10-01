import 'package:manhwamaniacs/features/library/models/library_statistics.dart';

/// The year the You hub's "Your {year} in chapters" card shows (glass 8.24): the current year through December, the previous
/// one through January, otherwise null (no card).
int? wrappedCardYear(DateTime nowLocal) => switch (nowLocal.month) {
      12 => nowLocal.year,
      1 => nowLocal.year - 1,
      _ => null,
    };

/// This week's figures for the Reading card.
class WeekSummary {
  const WeekSummary({required this.seconds, required this.chapters, required this.sparkline});
  final int seconds, chapters;

  /// Seconds per day, oldest first, always 7 points.
  final List<int> sparkline;
}

/// The last 7 entries of `daily` (missing days padded with 0 at the front).
WeekSummary weekSummary(List<DailyActivity> daily) {
  final last = daily.length > 7 ? daily.sublist(daily.length - 7) : daily;
  final points = [for (var i = last.length; i < 7; i++) 0, for (final d in last) d.secondsRead];
  return WeekSummary(
    seconds: last.fold(0, (a, d) => a + d.secondsRead),
    chapters: last.fold(0, (a, d) => a + d.chaptersRead),
    sparkline: points,
  );
}

/// "3 h 12 min", "3 h", "45 min", "0 min".
String formatDuration(int seconds) {
  final m = seconds ~/ 60, h = m ~/ 60, r = m % 60;
  if (h == 0) return '$m min';
  return r == 0 ? '$h h' : '$h h $r min';
}
