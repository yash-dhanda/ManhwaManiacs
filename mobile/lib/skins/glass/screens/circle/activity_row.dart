import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/circle/models/circle_models.dart';
import 'package:manhwamaniacs/features/circle/utils/collapse_feed.dart';
import 'package:manhwamaniacs/features/circle/utils/dispatch.dart' show chapterLabel;
import 'package:manhwamaniacs/features/circle/utils/spoiler_guard.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/skins/glass/copy/reactions.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/glass/shape.dart';
import 'package:manhwamaniacs/skins/glass/icons/glass_glyphs.g.dart';
import 'package:manhwamaniacs/skins/glass/parts/reactions/chapter_reactions.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/poster.dart' show GlassCoverImage;
import 'package:manhwamaniacs/skins/glass/primitives/press.dart';
import 'package:manhwamaniacs/skins/glass/screens/circle/circle_actions.dart';
import 'package:manhwamaniacs/skins/glass/screens/circle/circle_orb.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

/// One run of an activity sentence; [strong] is the series title (`headline` weight), [italic] a reaction name.
typedef SentenceRun = ({String text, bool strong, bool italic, ReactionKind? glyph});

/// The sentence of an activity row (glass 9.3.1): "Aarav finished chapter 142 of **Solo Leveling**", "Mira started **Omniscient
/// Reader**", "Aarav reacted *Hype* to chapter 88" (with the Fill glyph), collapsed "Aarav read chapters 140–152 of **Solo
/// Leveling**"; a guarded reaction reads only "Aarav reacted to Ch 212".
List<SentenceRun> activitySentence(FeedEntry e, {required bool guarded}) {
  final i = e.item;
  SentenceRun t(String s) => (text: s, strong: false, italic: false, glyph: null);
  final title = (text: i.title, strong: true, italic: false, glyph: null);
  final who = t(i.actor.name);
  final n = i.chapterNumber;
  switch (i.kind) {
    case FeedKind.started:
      return [who, t(' started '), title];
    case FeedKind.finishedSeries:
      return [who, t(' finished '), title];
    case FeedKind.finishedChapter:
      final r = e.range;
      if (r != null) return [who, t(' read chapters ${chapterLabel(r.$1)}–${chapterLabel(r.$2)} of '), title];
      return [who, t(n == null ? ' finished a chapter of ' : ' finished chapter ${chapterLabel(n)} of '), title];
    case FeedKind.reacted:
      final k = i.reaction;
      if (guarded || k == null) return [who, t(' reacted to ${n == null ? 'a chapter' : 'Ch ${chapterLabel(n)}'}')];
      return [who, t(' reacted '), (text: glassReaction(k).name, strong: false, italic: true, glyph: k), t(n == null ? ' to a chapter' : ' to chapter ${chapterLabel(n)}')];
  }
}

String sentenceText(List<SentenceRun> runs) => runs.map((r) => r.text).join();

/// `14:05` in local time.
String clockLabel(DateTime? t) {
  if (t == null) return '';
  final l = t.toLocal();
  return '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
}

/// An activity row (glass 9.3.1): the actor orb 32 with a `bloom` ring (opens the friend sheet), the sentence, the mode glyph and
/// time, the 44 x 66 cover (opens the series), "Read it too" on series the viewer does not follow, and the chapter's reaction
/// button. At text scale 1.6 and above the cover drops under the sentence.
class ActivityRow extends ConsumerWidget {
  const ActivityRow({super.key, required this.entry, this.focusNode, this.reactRequest, this.onFollow});
  final FeedEntry entry;
  final FocusNode? focusNode;

  /// `e`: opens the picker anchored to this row.
  final Listenable? reactRequest;
  final VoidCallback? onFollow;

  bool _guarded(WidgetRef ref, FeedItem i) {
    final own = i.actor.profileId == ref.watch(activeProfileProvider)?.id;
    if (i.kind != FeedKind.reacted || i.chapterKey == null) return false;
    final fin = ref.watch(finishedChaptersProvider((sourceId: i.sourceId, seriesKey: i.seriesKey)));
    return guardedFor(fin, chapterKey: i.chapterKey!, isOwn: own, sealed: i.sealed);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i = entry.item;
    final guarded = _guarded(ref, i);
    final runs = activitySentence(entry, guarded: guarded);
    final novel = i.contentKind == 'novel';
    final stacked = MediaQuery.textScalerOf(context).scale(10) / 10 >= 1.6;
    final body = roleStyle(context, gt.typeBody).copyWith(color: gt.colorLabel1);
    final sentence = Text.rich(
      TextSpan(children: [
        for (final r in runs) ...[
          TextSpan(text: r.text, style: r.strong ? roleStyle(context, gt.typeHeadline).copyWith(color: gt.colorLabel1) : (r.italic ? body.copyWith(fontStyle: FontStyle.italic, color: gt.colorBloom) : body)),
          if (r.glyph != null) WidgetSpan(alignment: PlaceholderAlignment.middle, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 3), child: Icon(glassReaction(r.glyph!).fill, size: 18, color: gt.colorBloom))),
        ],
      ],),
      style: body,
    );
    final meta = Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(novel ? GlassGlyph.bookOpen.regular : GlassGlyphs.stripScrollRegular, size: 16, color: gt.colorLabel2),
      const SizedBox(width: 6),
      GlassText(clockLabel(i.createdAt), role: gt.typeCaption1, color: gt.colorLabel3),
    ],);
    final cover = Builder(
      builder: (c) => GlassPressable(
        material: GlassMaterial.content,
        shape: const GlassShape.superellipse(8),
        semanticsLabel: 'Open ${i.title}',
        onTap: () => unawaited(openCircleSeries(ref, i.sourceId, i.seriesKey, from: rectOf(c))),
        builder: (_, __) => ClipRRect(borderRadius: BorderRadius.circular(8), child: SizedBox(width: 44, height: 66, child: i.coverUrl == null ? ColoredBox(color: gt.colorSurface2) : GlassCoverImage(url: i.coverUrl!, width: 44))),
      ),
    );
    final chapterItem = i.chapterKey != null && (i.kind == FeedKind.reacted || i.kind == FeedKind.finishedChapter);
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(label: sentenceText(runs), excludeSemantics: true, child: sentence),
        const SizedBox(height: 4),
        meta,
        if (!i.followedByViewer && i.actor.profileId != ref.watch(activeProfileProvider)?.id)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: GlassButton(label: 'Read it too', variant: GlassButtonVariant.plain, size: GlassButtonSize.small, onPressed: () => unawaited(followFromCircle(ref, sourceId: i.sourceId, seriesKey: i.seriesKey, title: i.title, actorId: i.actor.profileId).then((ok) => ok ? onFollow?.call() : null))),
          ),
      ],
    );
    return Focus(
      focusNode: focusNode,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: GlassFrame.screenMargin(context), vertical: 10),
        child: stacked
            ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [CircleOrbButton(member: i.actor, size: 32, semanticsLabel: '${i.actor.name}, open their Circle page'), const Spacer(), if (chapterItem) _react(i)]),
                const SizedBox(height: 8),
                text,
                const SizedBox(height: 8),
                cover,
              ],)
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleOrbButton(member: i.actor, size: 32, semanticsLabel: '${i.actor.name}, open their Circle page'),
                  const SizedBox(width: 12),
                  Expanded(child: text),
                  const SizedBox(width: 12),
                  Column(mainAxisSize: MainAxisSize.min, children: [cover, if (chapterItem) _react(i)]),
                ],
              ),
      ),
    );
  }

  Widget _react(FeedItem i) => GlassChapterReactions(sourceId: i.sourceId, seriesKey: i.seriesKey, chapterKey: i.chapterKey!, chapterNumber: i.chapterNumber, strip: false, openRequest: reactRequest);
}
