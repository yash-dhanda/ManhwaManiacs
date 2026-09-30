import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/circle/models/circle_models.dart';
import 'package:manhwamaniacs/features/circle/providers/circle_providers.dart';
import 'package:manhwamaniacs/features/circle/utils/dispatch.dart' show chapterLabel;
import 'package:manhwamaniacs/features/circle/utils/reaction_kinds.dart';
import 'package:manhwamaniacs/skins/cinematic/feedback.dart';
import 'package:manhwamaniacs/skins/cinematic/focus_ring.dart';
import 'package:manhwamaniacs/skins/cinematic/parts/circle_guard.dart';
import 'package:manhwamaniacs/skins/cinematic/parts/reaction_stamps.dart' show reactionGlyph;
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_avatar.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/sheet_route.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// The reactions on [chapterKey] (by key, else by number) among a series' chapters.
ChapterReactions? reactionsForChapter(List<ChapterReactions> all, String chapterKey, double? number) {
  for (final c in all) {
    if (c.chapterKey == chapterKey) return c;
  }
  if (number != null) {
    for (final c in all) {
      if (c.chapterNumber == number) return c;
    }
  }
  return null;
}

/// `3` then the `users-three` glyph on a chapter row when it has circle reactions (cinematic 8.17);
/// spoken "3 circle reactions". A 450 ms long-press opens the list of who reacted.
class ChapterReactionFolio extends ConsumerWidget {
  const ChapterReactionFolio({super.key, required this.sourceId, required this.seriesKey, required this.chapterKey, this.chapterNumber});
  final String sourceId, seriesKey, chapterKey;
  final double? chapterNumber;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(chapterReactionsProvider((sourceId: sourceId, seriesKey: seriesKey))).valueOrNull;
    final cr = all == null ? null : reactionsForChapter(all, chapterKey, chapterNumber);
    if (cr == null || cr.total <= 0) return const SizedBox.shrink();
    final c = context.cine;
    final label = '${cr.total} circle ${cr.total == 1 ? 'reaction' : 'reactions'}';
    void open() {
      cineFeedback(context, HapticEvent.longpressOpen);
      unawaited(showChapterReactors(context, sourceId: sourceId, seriesKey: seriesKey, reactions: cr));
    }

    return Semantics(
      label: label,
      excludeSemantics: true,
      onLongPress: open,
      child: CinePressable(
        hit: false,
        onLongPress: open,
        builder: (_, __) => Padding(
          padding: EdgeInsets.only(right: c.space2),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            CineRoleText('${cr.total}', c.typeFolio, color: c.colorInk45),
            const SizedBox(width: 2),
            CineGlyphIcon(CineGlyph.usersThree, size: 16, color: c.colorInk45),
          ],),
        ),
      ),
    );
  }
}

/// Who reacted to a chapter: "Riya · Loved", or, while it is guarded, "Riya reacted to Ch. 142".
Future<void> showChapterReactors(BuildContext context, {required String sourceId, required String seriesKey, required ChapterReactions reactions}) => showCineSheet<void>(
      context,
      kicker: 'REACTIONS',
      title: reactions.chapterNumber == null ? 'This chapter' : 'Chapter ${chapterLabel(reactions.chapterNumber!)}',
      builder: (ctx) => Material(type: MaterialType.transparency, child: ChapterReactorsList(sourceId: sourceId, seriesKey: seriesKey, reactions: reactions)),
    );

class ChapterReactorsList extends ConsumerWidget {
  const ChapterReactorsList({super.key, required this.sourceId, required this.seriesKey, required this.reactions});
  final String sourceId, seriesKey;
  final ChapterReactions reactions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.cine;
    final n = reactions.chapterNumber;
    final ch = n == null ? 'a chapter' : 'Ch. ${chapterLabel(n)}';
    final live = ref.watch(chapterReactionsProvider((sourceId: sourceId, seriesKey: seriesKey))).valueOrNull;
    final cr = live == null ? reactions : (reactionsForChapter(live, reactions.chapterKey, reactions.chapterNumber) ?? reactions);
    final guarded = circleGuarded(ref, sourceId: sourceId, seriesKey: seriesKey, chapterKey: cr.chapterKey, sealed: cr.sealed);
    return Padding(
      padding: EdgeInsets.fromLTRB(c.space4, 0, c.space4, c.space6),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        for (final b in cr.by)
          Semantics(
            container: true,
            label: guarded ? '${b.name} reacted to $ch' : '${b.name}, ${b.kind == null ? '' : reactionSpec(b.kind!).label}',
            excludeSemantics: true,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Row(children: [
                CineAvatar(avatarKey: b.avatarKey, size: 32),
                SizedBox(width: c.space3),
                Expanded(child: CineRoleText(guarded ? '${b.name} reacted to $ch' : '${b.name} · ${b.kind == null ? '' : reactionSpec(b.kind!).label}', c.typeUi)),
                if (!guarded && b.kind != null) reactionGlyph(b.kind!, size: 16, color: c.colorInk100),
              ],),
            ),
          ),
      ],),
    );
  }
}
