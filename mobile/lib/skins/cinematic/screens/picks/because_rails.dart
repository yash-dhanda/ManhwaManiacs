import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/core/network/api_image.dart';
import 'package:manhwamaniacs/features/ai/providers/ai_providers.dart';
import 'package:manhwamaniacs/features/library/models/world_item.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/parts/quick_look_builders.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_badge.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_poster.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_rail.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/quick_look.dart';
import 'package:manhwamaniacs/skins/cinematic/recap/continue_to.dart' show featureMoreLikeThis;

/// The seed title's grapheme range in `Because you read {title}`, set in Roman inside the italic head.
({int start, int end})? becauseRoman(String heading, String seed) {
  if (seed.isEmpty || !heading.endsWith(seed)) return null;
  final end = heading.characters.length;
  return (start: end - seed.characters.length, end: end);
}

/// One `Because you read {title}` rail of posters per world-recommendation section (3.2 visible;
/// 2.3 at text scale >= 1.3 is the rail's own rule). Long-press opens Quick look with More like
/// this and Not for me.
class BecauseRail extends ConsumerWidget {
  const BecauseRail({super.key, required this.section, required this.folio, this.pickedAgo});
  final WorldSection section;
  final String? folio;
  final String? pickedAgo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dismissed = ref.watch(dismissedPicksProvider);
    final items = [for (final i in section.items) if (!dismissed.contains(pickId(i))) i];
    if (items.isEmpty) return const SizedBox.shrink();
    final heading = 'Because you read ${section.becauseTitle}';
    return CineRail(
      headingId: 'picks-because-${section.becauseTitle}',
      heading: heading,
      folio: folio,
      roman: becauseRoman(heading, section.becauseTitle),
      pickedAgo: pickedAgo,
      itemCount: items.length,
      itemBuilder: (context, i, w, node) => worldRailPoster(context, ref, items[i], index: i, node: node),
    );
  }
}

/// A poster of a world item in a rail (Picks, More like this, the credits): Quick look on
/// long-press with More like this and Not for me, [folio] under the poster (the `why` line, or
/// `SAME GENRES` for the genre fallback).
Widget worldRailPoster(BuildContext context, WidgetRef ref, WorldItem it, {required int index, FocusNode? node, String? folio}) {
  final base = ref.read(apiBaseUrlProvider);
  return CineQuickLookTarget(
    onOpen: () => openWorldQuickLook(
      context,
      ref,
      it,
      onNotForMe: () => ref.read(aiFeedbackProvider).notInterested(it),
      // Quick look's More like this opens the series' tab; a title not on the reader's sources can
      // only be liked as a pick.
      onMoreLikeThis: () {
        final a = it.available.firstOrNull;
        if (a != null) {
          unawaited(context.push<void>(featureMoreLikeThis(a.sourceId, a.seriesKey)));
        } else {
          unawaited(ref.read(aiFeedbackProvider).likedPick(it));
        }
      },
    ),
    child: CinePoster(
      title: it.title,
      url: it.coverUrl == null ? null : resolveApiResourceUrl(base, it.coverUrl!),
      folio: folio ?? (it.available.isEmpty ? 'NOT ON YOUR SOURCES' : null),
      badges: [if (it.isAdult) CineBadge.certificate(onArt: true)],
      duotone: it.available.isEmpty ? it.ambient?.duo : null,
      duo: it.ambient?.duo,
      focusNode: node,
      flickerIndex: index,
      onTap: () => openWorldItem(context, it),
    ),
  );
}
