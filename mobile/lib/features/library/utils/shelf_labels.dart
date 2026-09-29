import 'package:manhwamaniacs/features/library/models/followed_series.dart';
import 'package:manhwamaniacs/features/novels/utils/novel_book.dart';

String _n(double v) => v % 1 == 0 ? '${v.toInt()}' : '$v';

/// The folio caption under a wall poster (cinematic 8.9): `NOT STARTED`, `CH 142 · 3 NEW`,
/// `CAUGHT UP`, else `CH 12 OF 40`.
String shelfFolio(FollowedSeries s) {
  final r = s.readState;
  if (r == null) return s.chapterCount > 0 ? '${s.chapterCount} CH' : '';
  if (!r.started) return 'NOT STARTED';
  final ch = r.chapterNumber ?? r.position?.toDouble();
  final head = ch == null ? 'CH' : 'CH ${_n(ch)}';
  final fresh = r.newCount ?? 0;
  if (fresh > 0) return '$head · $fresh NEW';
  if (r.newCount == 0) return 'CAUGHT UP';
  final of = r.latestNumber ?? r.total.toDouble();
  return ch == null || of <= 0 ? '${r.total} CH' : '$head OF ${_n(of)}';
}

/// `CH 12 OF 40` (no new count), for the LIST progress column.
String shelfProgress(FollowedSeries s) {
  final r = s.readState;
  if (r == null || !r.started) return 'NOT STARTED';
  final ch = r.chapterNumber ?? r.position?.toDouble();
  final of = r.latestNumber ?? r.total.toDouble();
  return ch == null || of <= 0 ? '${r.total} CH' : 'CH ${_n(ch)} OF ${_n(of)}';
}

/// LIST caption on phones: `CH 12 OF 40 · 3 NEW`.
String shelfListCaption(FollowedSeries s) {
  final fresh = s.readState?.newCount ?? 0;
  final p = shelfProgress(s);
  return fresh > 0 ? '$p · $fresh NEW' : p;
}

/// `2 H AGO`, `3 D AGO`; `—` when the row has no read time.
String lastReadCaption(DateTime? at, DateTime now) {
  if (at == null) return '—';
  final d = now.difference(at);
  if (d.inMinutes < 60) return '${d.inMinutes < 1 ? 1 : d.inMinutes} M AGO';
  if (d.inHours < 24) return '${d.inHours} H AGO';
  if (d.inDays < 7) return '${d.inDays} D AGO';
  if (d.inDays < 365) return '${d.inDays ~/ 7} W AGO';
  return '${d.inDays ~/ 365} Y AGO';
}

/// The book row's note (cinematic 8.9.1): `42% · CH 212` once started, else null (the reading
/// status stands in).
String? bookNote(FollowedSeries s) {
  final r = s.readState;
  if (r == null || !r.started) return null;
  final ch = r.chapterNumber ?? r.position?.toDouble();
  final total = r.total;
  final pct = r.position != null && total > 0 ? (r.position! * 100 / total).round() : null;
  if (pct == null && ch == null) return null;
  return [if (pct != null) '$pct%', if (ch != null) 'CH ${_n(ch)}'].join(' · ');
}

/// `412 CHAPTERS · NOVELARCHIVE`: what a follow row knows (publication status lives on the source).
String bookCredits(FollowedSeries s) => [
      if (formatChapterCount(s.chapterCount) case final c?) c.toUpperCase(),
      s.sourceId.replaceAll(RegExp(r'[-_]+'), ' ').toUpperCase(),
    ].join(' · ');
