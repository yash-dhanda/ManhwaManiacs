import 'dart:math' as math;

import 'package:manhwamaniacs/features/novels/utils/novel_book.dart' show formatChapterNumber, goToChapterQuery, printedChapterNumber;

/// One contents row as the go-to field sees it (reading order).
typedef TocRef = ({String key, double? number, String? title});

/// The slice of a long contents list that is built (glass 8.13 Contents): rows `[start, end)`, [earlier] rows above it
/// ("Show earlier chapters (212)") and the next page below it, at most `size` ("Show more chapters (400)").
class TocWindow {
  const TocWindow({required this.start, required this.end, required this.earlier, required this.later});
  final int start, end, earlier, later;

  @override
  bool operator ==(Object other) => other is TocWindow && other.start == start && other.end == end && other.earlier == earlier && other.later == later;

  @override
  int get hashCode => Object.hash(start, end, earlier, later);

  @override
  String toString() => 'TocWindow($start, $end, earlier: $earlier, later: $later)';
}

/// [size] rows centred on [focusIndex], clamped to the list.
TocWindow tocWindow(int total, int focusIndex, {int size = 400}) {
  if (total <= 0) return const TocWindow(start: 0, end: 0, earlier: 0, later: 0);
  final focus = focusIndex.clamp(0, total - 1);
  final start = (focus - size ~/ 2).clamp(0, math.max(0, total - size)).toInt();
  final end = math.min(total, start + size);
  return TocWindow(start: start, end: end, earlier: start, later: math.min(size, total - end));
}

/// What the go-to field answers: up to 12 [matches], [more] beyond them, or a [message].
class GoToResult {
  const GoToResult({this.matches = const [], this.more = 0, this.message});
  final List<TocRef> matches;
  final int more;
  final String? message;
}

const kGoToEmpty = 'Type a chapter number.';

/// Matches by the printed chapter number, compared as decimals ("12.5" finds 12.5, never 12).
GoToResult goToMatches(List<TocRef> chapters, String query, {int limit = 12}) {
  final wanted = query.trim().isEmpty ? null : goToChapterQuery(query);
  if (wanted == null) return const GoToResult(message: kGoToEmpty);
  final all = [
    for (final c in chapters)
      if (printedChapterNumber(title: c.title, number: c.number) == wanted) c,
  ];
  if (all.isEmpty) return GoToResult(message: 'No chapter ${formatChapterNumber(wanted)} in this book.');
  return GoToResult(matches: all.take(limit).toList(), more: math.max(0, all.length - limit));
}
