import 'package:manhwamaniacs/features/reader/models/reading_progress.dart';

/// "11 H 20 M", "45 M", or "—" when nothing was timed.
String timeHere(List<ReadingProgress> rows) {
  final secs = rows.fold<int>(0, (a, r) => a + r.timeSpentSeconds);
  final mins = secs ~/ 60;
  if (mins <= 0) return '—';
  final h = mins ~/ 60, m = mins % 60;
  return h == 0 ? '$m M' : '$h H $m M';
}
