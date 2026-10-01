import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/library/models/world_item.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/primitives/cards/world_card.dart';
import 'package:manhwamaniacs/skins/glass/primitives/menu.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/home_actions.dart'
    show openSeries;
import 'package:manhwamaniacs/skins/glass/screens/home/home_common.dart'
    show HomeCoverImage;
import 'package:manhwamaniacs/skins/skins.dart';

/// A [WorldItem] as a Glass world card: available (opens the series, a source picker when several have it) or info-only.
Widget worldCardFor(BuildContext context, WidgetRef ref, WorldItem w,
    {bool ai = true,}) {
  final cover = HomeCoverImage(url: w.coverUrl, width: 80);
  final kind = w.badgeLine ?? '';
  final stats = [
    if (w.chaptersLabel != null) w.chaptersLabel!,
    if (w.ratingLabel != null) w.ratingLabel!,
  ].join(' · ');
  final why = w.why ?? '';
  final first = w.available.firstOrNull;
  if (first == null) {
    final p = w.platforms.firstOrNull;
    return GlassWorldCard.infoOnly(
      cover: cover,
      title: w.title,
      kind: kind,
      stats: stats,
      why: why,
      site: p?.site ?? 'the web',
      siteUrl: p?.url ?? w.anilistUrl ?? 'https://anilist.co',
      tags: w.cardGenres,
      ai: ai,
      onSearchMySources: () => unawaited(ref
          .read(skinRouterProvider)
          .push<void>(Routes.discover({'q': w.title})),),
    );
  }
  Future<void> open() async {
    final box = context.findRenderObject() as RenderBox?;
    final from = box != null && box.attached
        ? box.localToGlobal(Offset.zero) & box.size
        : null;
    if (w.available.length > 1 && from != null) {
      await showGlassMenu(context, anchor: from, title: 'Open on', entries: [
        for (final a in w.available)
          GlassMenuEntry(
              label: 'On ${a.sourceName}',
              onSelected: () => unawaited(
                  openSeries(ref, a.sourceId, a.seriesKey, from: from),),),
      ],);
    } else {
      await openSeries(ref, first.sourceId, first.seriesKey, from: from);
    }
  }

  return GlassWorldCard.available(
      cover: cover,
      title: w.title,
      kind: kind,
      stats: stats,
      why: why,
      source: first.sourceName,
      extraSources: w.available.length - 1,
      tags: w.cardGenres,
      ai: ai,
      onOpen: () => unawaited(open()),);
}
