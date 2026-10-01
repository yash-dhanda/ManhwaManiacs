import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/ai/models/similar_result.dart';
import 'package:manhwamaniacs/features/ai/providers/ai_providers.dart';
import 'package:manhwamaniacs/features/library/models/world_item.dart';
import 'package:manhwamaniacs/skins/glass/parts/ai/not_interested.dart';
import 'package:manhwamaniacs/skins/glass/parts/ai/world_card_for.dart';
import 'package:manhwamaniacs/skins/glass/primitives/ai/machine_badge.dart';
import 'package:manhwamaniacs/skins/glass/primitives/ai/thinking_orbit.dart';
import 'package:manhwamaniacs/skins/glass/primitives/cards/world_card.dart' show glassWorldCardExtra;
import 'package:manhwamaniacs/skins/glass/primitives/rail.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/home_rail_common.dart' show posterCardHeight;

/// At least this many genre-fallback items, or the rail is omitted.
const int kGenresMin = 3;
const int kMoreLikeMax = 10;

/// The rail's key, so series detail can scroll to it (`focus=more-like-this`).
GlobalKey moreLikeThisKey(String sourceId, String seriesKey) => GlobalObjectKey('more-like-this:$sourceId:$seriesKey');

/// More like this (glass 9.1.4): up to 10 world cards from `GET /ai/similar`, each with its `why`. While the AI is unavailable the
/// rail reloads with `fallback=genres`: "Same genres", no sparkle and no machine rim; fewer than 3 such items omit it.
class MoreLikeThisRail extends ConsumerWidget {
  const MoreLikeThisRail({super.key, required this.sourceId, required this.seriesKey, required this.title});
  final String sourceId, seriesKey, title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ai = ref.watch(similarProvider(SimilarQuery.series(sourceId, seriesKey)));
    final key = moreLikeThisKey(sourceId, seriesKey);
    return ai.when(
      loading: () => KeyedSubtree(
        key: key,
        child: GlassRail(title: 'More like $title', revealKey: 'mlt:$sourceId:$seriesKey', screenId: 'series', itemCount: 0, itemBuilder: (_, __) => const SizedBox.shrink(), itemHeight: posterCardHeight(context), state: GlassRailState.loading, aiSkeleton: true, skeletonCount: 3, titleLeading: const ThinkingOrbit()),
      ),
      error: (_, __) => _genres(context, ref, key),
      data: (r) {
        if (!r.available) return _genres(context, ref, key);
        if (r.items.isEmpty) return const SizedBox.shrink();
        return _rail(context, ref, key, r.items.take(kMoreLikeMax).toList(), machine: true);
      },
    );
  }

  Widget _genres(BuildContext context, WidgetRef ref, GlobalKey key) {
    final g = ref.watch(similarProvider(SimilarQuery.series(sourceId, seriesKey, fallbackGenres: true)));
    return g.maybeWhen(
      data: (r) => r.items.length < kGenresMin ? const SizedBox.shrink() : _rail(context, ref, key, r.items.take(kMoreLikeMax).toList(), machine: false),
      orElse: () => const SizedBox.shrink(),
    );
  }

  Widget _rail(BuildContext context, WidgetRef ref, GlobalKey key, List<WorldItem> items, {required bool machine}) {
    final dismissed = ref.watch(dismissedPicksProvider);
    final shown = [for (final w in items) if (!dismissed.contains(pickId(w))) w];
    if (shown.isEmpty) return const SizedBox.shrink();
    return KeyedSubtree(
      key: key,
      child: GlassRail(
        title: 'More like $title',
        subtitle: machine ? null : 'Same genres',
        revealKey: 'mlt:$sourceId:$seriesKey',
        screenId: 'series',
        itemCount: shown.length,
        itemWidth: 300,
        itemHeight: 140 + glassWorldCardExtra(context),
        titleLeading: machine ? const MachineBadge() : null,
        itemBuilder: (c, i) {
          final w = shown[i];
          final card = worldCardFor(c, ref, w, ai: machine);
          return Padding(padding: const EdgeInsets.only(right: 12), child: machine ? AiCardActions(item: w, child: card) : card);
        },
      ),
    );
  }
}
