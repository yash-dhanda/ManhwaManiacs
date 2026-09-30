import 'package:manhwamaniacs/features/circle/models/circle_models.dart';
import 'package:manhwamaniacs/features/circle/utils/reaction_kinds.dart';

/// What a row of the reader's CIRCLE tab says about a member (cinematic 9.3.3, the spoiler guard).
enum CircleRowKind {
  /// Their reaction on this chapter, by label.
  label,

  /// A reaction the viewer has not earned yet: only "reacted to Ch. 142".
  guarded,

  /// Further on: "Riya is on Ch. 150", no detail.
  further,

  /// On this chapter, no reaction.
  here,
}

class CircleRow {
  const CircleRow({required this.member, required this.kind, this.label, this.chapterNumber});
  final CircleMemberRef member;
  final CircleRowKind kind;

  /// `LOVED`, `CHEF'S KISS`... for [CircleRowKind.label].
  final String? label;
  final double? chapterNumber;
}

/// The kicker of a reaction kind.
String reactionLabel(ReactionKind? kind) => kind == null ? '' : reactionSpec(kind).label.toUpperCase();

String _num(double? n) => n == null ? '' : (n == n.roundToDouble() ? n.toStringAsFixed(0) : n.toString());

/// `Ch. 142`.
String chapterShort(double? n) => n == null ? 'a later chapter' : 'Ch. ${_num(n)}';

/// The CIRCLE tab's rows for the chapter open at [openKey] / [openNumber]. While the viewer has
/// not finished it ([completedOpen] false and the server still seals it) a reaction on it or on any
/// later chapter shows only that the member reacted; members further on show where they are.
List<CircleRow> circleRows(CircleSeriesData data, {required String openKey, required double? openNumber, required bool completedOpen}) {
  final members = <int, CircleMemberRef>{
    for (final r in data.readers) r.member.profileId: r.member,
    for (final c in data.chapters)
      for (final b in c.by) b.member.profileId: b.member,
  };
  final rows = <CircleRow>[];
  for (final m in members.values) {
    final reader = data.readers.where((r) => r.member.profileId == m.profileId).firstOrNull;
    final reactions = [
      for (final c in data.chapters)
        for (final b in c.by)
          if (b.member.profileId == m.profileId) (chapter: c, kind: b.kind),
    ];
    bool isOpen(CircleChapterReactions c) => c.chapterKey == openKey || (openNumber != null && c.chapterNumber == openNumber);
    bool isLater(CircleChapterReactions c) => !isOpen(c) && (c.chapterNumber == null || (openNumber != null && c.chapterNumber! > openNumber));
    final onOpen = reactions.where((r) => isOpen(r.chapter)).firstOrNull;
    if (onOpen != null) {
      final earned = completedOpen || !onOpen.chapter.sealed;
      rows.add(earned
          ? CircleRow(member: m, kind: CircleRowKind.label, label: reactionLabel(onOpen.kind), chapterNumber: onOpen.chapter.chapterNumber)
          : CircleRow(member: m, kind: CircleRowKind.guarded, chapterNumber: openNumber),);
      continue;
    }
    final later = reactions.where((r) => isLater(r.chapter)).firstOrNull;
    if (later != null) {
      rows.add(CircleRow(member: m, kind: CircleRowKind.guarded, chapterNumber: later.chapter.chapterNumber));
      continue;
    }
    final at = reader?.chapterNumber;
    if (at != null && openNumber != null && at > openNumber) {
      rows.add(CircleRow(member: m, kind: CircleRowKind.further, chapterNumber: at));
    } else if (at != null && (openNumber == null || at == openNumber)) {
      rows.add(CircleRow(member: m, kind: CircleRowKind.here, chapterNumber: at));
    }
  }
  return rows;
}
