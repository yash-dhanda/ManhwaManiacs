import 'package:manhwamaniacs/features/circle/models/circle_models.dart';

/// One run of a dispatch sentence.
class DispatchRun {
  const DispatchRun(this.text, {this.italic = false, this.reaction});
  final String text;
  final bool italic;

  /// Set on the run that carries the reaction glyph (the run's text is its name).
  final ReactionKind? reaction;

  @override
  bool operator ==(Object other) => other is DispatchRun && other.text == text && other.italic == italic && other.reaction == reaction;

  @override
  int get hashCode => Object.hash(text, italic, reaction);
}

/// A chapter number without a trailing `.0`.
String chapterLabel(double n) => n == n.roundToDouble() ? n.toInt().toString() : n.toString();

/// The sentence of a dispatch (cinematic 9.3.2) as runs; names and titles are italic.
List<DispatchRun> dispatchParts(FeedItem item, bool guarded) {
  final actor = DispatchRun(item.actor.name, italic: true);
  final title = DispatchRun(item.title, italic: true);
  final n = item.chapterNumber;
  switch (item.kind) {
    case FeedKind.started:
      return [actor, const DispatchRun(' started '), title, const DispatchRun('.')];
    case FeedKind.finishedChapter:
      return [actor, DispatchRun(n == null ? ' finished a chapter of ' : ' finished chapter ${chapterLabel(n)} of '), title, const DispatchRun('.')];
    case FeedKind.finishedSeries:
      return [actor, const DispatchRun(' finished '), title, const DispatchRun('.')];
    case FeedKind.reacted:
      final of = n == null ? ' to a chapter of ' : ' to chapter ${chapterLabel(n)} of ';
      final k = item.reaction;
      if (guarded || k == null) return [actor, DispatchRun(' reacted$of'), title, const DispatchRun('.')];
      return [actor, const DispatchRun(' reacted '), DispatchRun(_name(k), reaction: k), DispatchRun(of), title, const DispatchRun('.')];
  }
}

String _name(ReactionKind k) => switch (k) {
      ReactionKind.loved => 'Loved',
      ReactionKind.shook => 'Shook',
      ReactionKind.laughed => 'Laughed',
      ReactionKind.tears => 'Tears',
      ReactionKind.chefsKiss => "Chef's kiss",
      ReactionKind.hype => 'Hype',
      ReactionKind.wrecked => 'Wrecked',
    };

/// The whole sentence as plain text (screen readers).
String dispatchText(FeedItem item, bool guarded) => dispatchParts(item, guarded).map((r) => r.text).join();

const _months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
const _days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

/// `TODAY`, `YESTERDAY`, else `MON 21 SEP`, in local time.
String dayLabel(DateTime t, DateTime now) {
  final d = t.toLocal(), n = now.toLocal();
  final a = DateTime(d.year, d.month, d.day), b = DateTime(n.year, n.month, n.day);
  final diff = b.difference(a).inDays;
  if (diff <= 0) return 'TODAY';
  if (diff == 1) return 'YESTERDAY';
  return '${_days[a.weekday - 1]} ${a.day} ${_months[a.month - 1]}';
}

/// Items grouped under their day label, in the given order (the feed is newest first).
List<({String label, List<FeedItem> items})> dayGroups(List<FeedItem> items, DateTime now) {
  final out = <({String label, List<FeedItem> items})>[];
  for (final i in items) {
    final label = i.createdAt == null ? 'TODAY' : dayLabel(i.createdAt!, now);
    if (out.isNotEmpty && out.last.label == label) {
      out.last.items.add(i);
    } else {
      out.add((label: label, items: [i]));
    }
  }
  return out;
}
