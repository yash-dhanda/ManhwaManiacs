import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/home/utils/rerank.dart';
import 'package:manhwamaniacs/skins/glass/primitives/cards/series_card.dart';
import 'package:manhwamaniacs/skins/glass/primitives/poster.dart';
import 'package:manhwamaniacs/skins/glass/primitives/rail.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/hero_claim.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/home_actions.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/home_common.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/home_rail_common.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/home_rails.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/poster_menu.dart';

/// A rail of posters (glass 8.8): "Updated for you", "Almost there", "Ready offline", "Recently added to your library". A tap opens the
/// series with the zoom; the long press opens the poster menu; a lift can be thrown up (open) or dropped on a friend's orb.
class HomePosterRail extends ConsumerWidget {
  const HomePosterRail({super.key, required this.rail, required this.env});
  final HomeRailSpec rail;
  final HomeRailEnv env;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = rail.items.cast<HomePoster>();
    return GlassRail(
      title: rail.title,
      revealKey: railRevealKey(ref, rail.id),
      screenId: kHomeScreenId,
      onSeeAll: seeAllOf(ref, rail),
      itemCount: items.length,
      itemHeight: posterCardHeight(context),
      itemBuilder: (context, i) => HomePosterCard(poster: items[i], env: env, onOpened: (g) => ref.read(rerankNotesProvider.notifier).noteOpenedFromRail(g)),
    );
  }
}

/// One poster of a rail with its title and caption.
class HomePosterCard extends ConsumerStatefulWidget {
  const HomePosterCard({super.key, required this.poster, required this.env, this.onOpened, this.width});
  final HomePoster poster;
  final HomeRailEnv env;
  final ValueChanged<String>? onOpened;
  final double? width;

  @override
  ConsumerState<HomePosterCard> createState() => _HomePosterCardState();
}

class _HomePosterCardState extends ConsumerState<HomePosterCard> {
  final GlobalKey _box = GlobalKey();

  Rect _rect() {
    final ro = _box.currentContext?.findRenderObject();
    return ro is RenderBox && ro.attached ? ro.localToGlobal(Offset.zero) & ro.size : Rect.zero;
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.poster;
    final h = widget.env.handlers;
    final newCount = int.tryParse((p.badge ?? '').split(' ').first) ?? 0;
    void menu() {
      unawaited(showSeriesMenu(context, ref, SeriesMenuSpec(sourceId: p.sourceId, seriesKey: p.seriesKey, title: p.title, coverUrl: p.coverUrl, target: p.target, readNumber: p.readNumber), _rect()));
    }

    final poster = GlassPoster(
      key: _box,
      cover: HomeHero(sourceId: p.sourceId, seriesKey: p.seriesKey, child: HomeCoverImage(url: p.coverUrl, width: widget.width)),
      title: p.title,
      width: widget.width,
      lMax: p.palette?.lMax ?? 0.5,
      meta: GlassPosterMeta(newCount: newCount, mature: p.mature),
      targets: h.targets,
      onTap: () => unawaited(openSeries(ref, p.sourceId, p.seriesKey, from: _rect())),
      onContextPreview: menu,
      onThrowOpen: (v) => unawaited(openSeries(ref, p.sourceId, p.seriesKey, from: _rect(), velocity: v)),
      onDropOnTarget: (id) => recommendTo(context, ref, sourceId: p.sourceId, seriesKey: p.seriesKey, profileId: id),
      onLiftPhase: h.onLiftPhase?.call(p.sourceId, p.seriesKey, _rect),
      onMagnetChanged: h.onMagnetChanged,
    );
    return GlassSeriesCard(poster: poster, title: p.title, meta: p.caption, width: widget.width);
  }
}
