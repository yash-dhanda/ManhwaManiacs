import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/time/clock.dart';
import 'package:manhwamaniacs/features/ai/models/similar_result.dart';
import 'package:manhwamaniacs/features/ai/providers/ai_providers.dart';
import 'package:manhwamaniacs/features/library/models/world_item.dart';
import 'package:manhwamaniacs/features/library/providers/intelligence_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/ai_copy.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_progress.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_rail.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_section_header.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/typed_text.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/picks/because_rails.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/tonight/tonight_layout.dart' show pickedAgo;
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// `SAME GENRES`: the caption of a genre-fallback poster in place of a `why`.
const kSameGenres = 'SAME GENRES';

/// More like this for one series (cinematic 9.1.4), in the four states of 9.1.8: thinking (the H3,
/// a typed line, a leader dial after 1 s), unavailable (the `NOTE` copy and the same-genre rail),
/// stale (`PICKED 3 DAYS AGO` beside the H3) and empty. A `Because you read {title}` rail follows
/// when the world recommendations were seeded from this series. Used by the feature page's
/// `03 MORE LIKE THIS` tab and the reader's chapter-end credits.
class SimilarRails extends ConsumerWidget {
  const SimilarRails({super.key, required this.sourceId, required this.seriesKey, required this.title, this.heading = 'Similar', this.because = true});
  final String sourceId, seriesKey, title, heading;

  /// Adds the `Because you read {title}` rail when a recommendations section has this series as its seed.
  final bool because;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.cine;
    final res = ref.watch(similarProvider(SimilarQuery.series(sourceId, seriesKey)));
    final dismissed = ref.watch(dismissedPicksProvider);
    List<WorldItem> visible(List<WorldItem> l) => [for (final i in l) if (!dismissed.contains(pickId(i))) i];
    final now = ref.read(clockProvider)();
    final recs = because ? ref.watch(recommendationsProvider).valueOrNull : null;
    final seeded = [
      for (final s in recs?.sections ?? const <WorldSection>[])
        if (s.becauseSourceId == sourceId && s.becauseSeriesKey == seriesKey && visible(s.items).isNotEmpty) s,
    ];

    Widget rail(String id, String head, List<WorldItem> items, {String? folio, String? ago, bool genres = false}) => CineRail(
          headingId: id,
          heading: head,
          pickedAgo: ago,
          itemCount: items.length,
          itemBuilder: (context, i, w, node) => worldRailPoster(context, ref, items[i], index: i, node: node, folio: genres || items[i].why == null ? (genres ? kSameGenres : null) : items[i].why),
        );

    final body = res.when(
      loading: () => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        CineSectionHeader(headingId: 'similar-$seriesKey', heading: heading),
        SizedBox(height: c.space3),
        Row(children: [
          Expanded(child: TypedText.plain(kAiThinkingSimilar, style: CineText.style(context, c.typePull).copyWith(color: c.colorInk100))),
          SizedBox(width: c.space3),
          const CineLeaderDial(size: 24, showAfter: Duration(seconds: 1)),
        ],),
      ],),
      error: (_, __) => const SizedBox.shrink(),
      data: (r) {
        final items = visible(r.items);
        if (!r.available) {
          return _Unavailable(sourceId: sourceId, seriesKey: seriesKey, heading: heading, reason: r.reason, seeded: r.isGenres ? items : null, rail: rail);
        }
        if (items.isEmpty) {
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            CineSectionHeader(headingId: 'similar-$seriesKey', heading: heading),
            SizedBox(height: c.space3),
            CineRoleText('Nothing similar on your sources yet.', c.typeBodyItalic, color: c.colorInk45),
          ],);
        }
        return rail('similar-$seriesKey', heading, items, ago: pickedAgo(r.generatedAt, now), genres: r.isGenres);
      },
    );
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
      body,
      for (final s in seeded) ...[SizedBox(height: c.space6), BecauseRail(section: s, folio: null)],
    ],);
  }
}

class _Unavailable extends ConsumerWidget {
  const _Unavailable({required this.sourceId, required this.seriesKey, required this.heading, required this.reason, required this.seeded, required this.rail});
  final String sourceId, seriesKey, heading, reason;
  final List<WorldItem>? seeded;
  final Widget Function(String id, String head, List<WorldItem> items, {String? folio, String? ago, bool genres}) rail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.cine;
    final dismissed = ref.watch(dismissedPicksProvider);
    // The server already answers the desk being closed with the same-genre items; otherwise ask for them.
    final fallback = seeded ?? ref.watch(similarProvider(SimilarQuery.series(sourceId, seriesKey, fallbackGenres: true))).valueOrNull?.items;
    final items = [for (final i in fallback ?? const <WorldItem>[]) if (!dismissed.contains(pickId(i))) i];
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      CineSectionHeader(headingId: 'similar-$seriesKey', heading: heading),
      SizedBox(height: c.space3),
      Semantics(
        container: true,
        liveRegion: true,
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          CineRoleText('NOTE', c.typeKicker, color: c.colorSpot),
          SizedBox(width: c.space2),
          Expanded(child: CineRoleText(aiUnavailableLine(reason, 'Here are series from the same genres.'), c.typeCaption, color: c.colorInk60)),
        ],),
      ),
      if (items.isNotEmpty) ...[SizedBox(height: c.space3), rail('similar-genres-$seriesKey', heading, items, genres: true)],
    ],);
  }
}
