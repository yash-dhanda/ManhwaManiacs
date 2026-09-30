import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/circle/providers/circle_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/parts/pass_it_on_sheet.dart';
import 'package:manhwamaniacs/skins/cinematic/parts/reaction_stamps.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/stock.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

/// The reactions block of a chapter's end (manga credits step 3, the novel end matter): the stamps,
/// then a `quiet` `Pass it on` when the circle has members. In a novel stock the outline is the
/// stock's `muted` at 30 %, the glyphs its ink and the selected fill its ink with the page colour as
/// the glyph. Renders nothing when the Circle is not deployed on the server.
class CircleReactionsBlock extends ConsumerWidget {
  const CircleReactionsBlock({super.key, required this.sourceId, required this.seriesKey, required this.chapterKey, required this.seriesTitle, this.chapterNumber, this.stock, this.coverUrl});

  final String sourceId, seriesKey, chapterKey, seriesTitle;
  final double? chapterNumber;
  final CineStockColors? stock;
  final String? coverUrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.cine;
    final members = ref.watch(circleMembersProvider);
    if (members.hasError && members.valueOrNull == null) return const SizedBox.shrink();
    final hasMembers = (members.valueOrNull ?? const []).isNotEmpty;
    final colors = stock == null ? null : ReactionStampColors(outline: stock!.muted.withValues(alpha: 0.3), ink: stock!.ink, muted: stock!.muted, fillText: stock!.page);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      ReactionStamps(sourceId: sourceId, seriesKey: seriesKey, chapterKey: chapterKey, chapterNumber: chapterNumber, colors: colors),
      if (hasMembers) ...[
        SizedBox(height: c.space3),
        CineButton(
          label: 'Pass it on',
          variant: CineButtonVariant.quiet,
          onPressed: () => unawaited(showPassItOnSheet(context, sourceId: sourceId, seriesKey: seriesKey, title: seriesTitle, coverUrl: coverUrl)),
        ),
      ],
    ],);
  }
}
