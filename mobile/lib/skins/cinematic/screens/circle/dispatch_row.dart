import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/features/circle/models/circle_models.dart';
import 'package:manhwamaniacs/features/circle/utils/dispatch.dart';
import 'package:manhwamaniacs/features/circle/utils/reaction_kinds.dart';
import 'package:manhwamaniacs/features/library/utils/cover_url.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/a11y/folio.dart';
import 'package:manhwamaniacs/skins/cinematic/parts/circle_follow.dart';
import 'package:manhwamaniacs/skins/cinematic/parts/circle_guard.dart';
import 'package:manhwamaniacs/skins/cinematic/parts/reaction_stamps.dart' show reactionGlyph;
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_avatar.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_image.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/rows/cine_row.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// `5 M`, `2 H`, `3 D`, `2 W` (the time folio of a dispatch); spoken by [folioLabel].
String dispatchFolio(DateTime at, DateTime now) {
  final gap = now.difference(at);
  if (gap.inMinutes < 1) return '1 M';
  if (gap.inMinutes < 60) return '${gap.inMinutes} M';
  if (gap.inHours < 24) return '${gap.inHours} H';
  if (gap.inDays < 14) return '${gap.inDays} D';
  return '${gap.inDays ~/ 7} W';
}

/// One dispatch (cinematic 9.3.2): actor avatar, the sentence, the time folio, the 40 x 60 cover
/// and `Read it too`. A standard row (min 56 px); a tap opens the feature page.
class DispatchRow extends ConsumerWidget {
  const DispatchRow({super.key, required this.item, required this.now, this.focusNode, this.heroTag, this.unsealIndex = 0, this.duplicateNames = false});

  final FeedItem item;
  final DateTime now;
  final FocusNode? focusNode;

  /// Set on the first dispatch of a series only (two Heroes may not share a tag in one route).
  final Object? heroTag;
  final int unsealIndex;

  /// Two members share a name: the actor also carries `@username`.
  final bool duplicateNames;

  void _open(BuildContext context) => unawaited(context.push(Routes.feature(item.sourceId, item.seriesKey)));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.cine;
    final guarded = item.kind == FeedKind.reacted &&
        circleGuarded(ref, sourceId: item.sourceId, seriesKey: item.seriesKey, chapterKey: item.chapterKey, sealed: item.sealed);
    final sentence = dispatchText(item, guarded);
    final folio = item.createdAt == null ? null : dispatchFolio(item.createdAt!, now);
    final base = ref.watch(apiBaseUrlProvider);
    final style = CineText.style(context, c.typeBody).copyWith(color: c.colorInk100);
    final parts = dispatchParts(item, guarded);
    final spans = <InlineSpan>[];
    for (final r in parts) {
      if (r.reaction != null) {
        final spec = reactionSpec(r.reaction!);
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Semantics(
            label: spec.label,
            child: ExcludeSemantics(
              child: UnsealFade(
                guarded: guarded,
                index: unsealIndex,
                child: spec.stampText != null
                    ? CineRoleText(spec.stampText!, c.typeMicro, color: c.colorInk100)
                    : reactionGlyph(spec.kind, size: 16, color: c.colorInk100),
              ),
            ),
          ),
        ),);
        continue;
      }
      var text = r.text;
      if (r.italic && duplicateNames && r.text == item.actor.name && item.actor.username != null) text = '${r.text} (@${item.actor.username})';
      spans.add(TextSpan(text: text, style: r.italic ? const TextStyle(fontStyle: FontStyle.italic) : null));
    }
    final cover = SizedBox(
      width: 40,
      height: 60,
      child: () {
        Widget img = CineImage(url: historyCoverUrl(base, item.coverUrl), title: item.title);
        if (heroTag != null) img = Hero(tag: heroTag!, child: img);
        return GestureDetector(behavior: HitTestBehavior.opaque, onTap: () => _open(context), child: ExcludeSemantics(child: img));
      }(),
    );
    return CineRowShell(
      focusNode: focusNode,
      onTap: () => _open(context),
      semanticLabel: [sentence, if (folio != null) folioLabel(folio)].join(', '),
      semanticActions: {
        if (!item.followedByViewer) const CustomSemanticsAction(label: 'Read it too'): () => unawaited(circleFollow(context, ref, sourceId: item.sourceId, seriesKey: item.seriesKey, title: item.title)),
      },
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: c.space2),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          CineAvatar(avatarKey: item.actor.avatarKey, size: 32),
          SizedBox(width: c.space3),
          Expanded(
            child: ExcludeSemantics(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text.rich(TextSpan(children: spans), style: style),
                SizedBox(height: c.space1),
                Row(children: [
                  if (folio != null) CineRoleText(folio, c.typeFolio, color: c.colorInk45),
                  if (folio != null) SizedBox(width: c.space3),
                  if (item.followedByViewer)
                    CineRoleText('FOLLOWING', c.typeCaption, color: c.colorInk45)
                  else
                    CineButton(
                      label: 'Read it too',
                      variant: CineButtonVariant.quiet,
                      size: CineButtonSize.sm,
                      onPressed: () => unawaited(circleFollow(context, ref, sourceId: item.sourceId, seriesKey: item.seriesKey, title: item.title)),
                    ),
                ],),
              ],),
            ),
          ),
          SizedBox(width: c.space3),
          cover,
        ],),
      ),
    );
  }
}
