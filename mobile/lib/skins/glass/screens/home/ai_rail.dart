import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/ai/providers/ai_providers.dart';
import 'package:manhwamaniacs/features/ai/utils/ai_state.dart';
import 'package:manhwamaniacs/features/home/models/home_feed.dart';
import 'package:manhwamaniacs/features/home/utils/rerank.dart';
import 'package:manhwamaniacs/features/library/models/world_item.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/primitives/ai/ai_notice.dart';
import 'package:manhwamaniacs/skins/glass/primitives/ai/ai_stamp.dart';
import 'package:manhwamaniacs/skins/glass/primitives/ai/machine_badge.dart';
import 'package:manhwamaniacs/skins/glass/primitives/ai/thinking_orbit.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/menu.dart';
import 'package:manhwamaniacs/skins/glass/primitives/poster.dart';
import 'package:manhwamaniacs/skins/glass/primitives/rail.dart';
import 'package:manhwamaniacs/skins/glass/primitives/toast.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/hero_claim.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/home_actions.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/home_common.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/home_rail_common.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/home_rails.dart';
import 'package:manhwamaniacs/skins/skins.dart';
import 'package:url_launcher/url_launcher.dart';

WorldItem worldOf(HomePickItem p) {
  if (p.world != null) return p.world!;
  final s = p.source!;
  return WorldItem(title: s.title, coverUrl: s.coverUrl, genres: s.genres, available: [WorldAvailability(sourceId: s.sourceId, sourceName: s.sourceId, seriesKey: s.id)]);
}

/// The AI rails ("Because you read X", "For you") and the plain pick rails ("Start here", "Popular on your pinned sources"): the
/// header carries the machine badge, the cards their `why` line. Thinking, stale, unavailable and partial states follow glass 9.1.5.
class HomeAiRail extends ConsumerWidget {
  const HomeAiRail({super.key, required this.rail, required this.env});
  final HomeRailSpec rail;
  final HomeRailEnv env;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dismissed = ref.watch(dismissedPicksProvider);
    final items = [
      for (final i in rail.items.whereType<HomePickItem>())
        if (!(rail.machine && dismissed.contains(pickId(worldOf(i))))) i,
    ];
    final state = rail.ai
        ? aiState(loading: rail.thinking, available: !rail.unavailable, reason: env.aiReason ?? 'not_configured', generatedAt: rail.generatedAt, now: env.now)
        : (state: AiSurfaceState.ready, reason: null);
    final key = railRevealKey(ref, rail.id);
    final badge = rail.machine ? const MachineBadge() : null;
    Widget cardFor(int i) => AiPickCard(item: items[i], ai: rail.machine, env: env, railId: rail.id);
    final h = posterCardHeight(context, extra: 28);
    if (state.state == AiSurfaceState.thinking) {
      return GlassRail(title: rail.title, revealKey: key, screenId: kHomeScreenId, itemCount: 0, itemBuilder: (_, __) => const SizedBox.shrink(), itemHeight: h, state: GlassRailState.loading, aiSkeleton: true, skeletonCount: 4, titleLeading: const ThinkingOrbit());
    }
    if (state.state == AiSurfaceState.unavailable) {
      final notice = AiNotice(reason: state.reason);
      if (items.isEmpty) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            HomeRailHeader(title: rail.title, railId: rail.id, leading: badge),
            Padding(padding: EdgeInsets.fromLTRB(GlassFrame.contentMargin(context), 8, GlassFrame.contentMargin(context), 0), child: notice),
          ],
        );
      }
      return GlassRail(title: rail.title, revealKey: key, screenId: kHomeScreenId, onSeeAll: seeAllOf(ref, rail), itemCount: items.length, itemBuilder: (c, i) => cardFor(i), itemHeight: h, titleLeading: badge, belowHeader: notice);
    }
    return GlassRail(
      title: rail.title,
      subtitle: rail.subtitle,
      revealKey: key,
      screenId: kHomeScreenId,
      onSeeAll: seeAllOf(ref, rail),
      itemCount: items.length,
      itemBuilder: (c, i) => cardFor(i),
      itemHeight: h,
      titleLeading: badge,
      titleTrailing: rail.ai ? AiStamp(generatedAt: rail.generatedAt, now: env.now) : null,
    );
  }
}

/// One pick: a poster with its title and `why`. AI cards can be thrown sideways for "Not interested" (and `Delete`).
class AiPickCard extends ConsumerStatefulWidget {
  const AiPickCard({super.key, required this.item, required this.ai, required this.env, required this.railId});
  final HomePickItem item;
  final bool ai;
  final HomeRailEnv env;
  final String railId;

  @override
  ConsumerState<AiPickCard> createState() => _AiPickCardState();
}

class _AiPickCardState extends ConsumerState<AiPickCard> {
  final GlobalKey _box = GlobalKey();

  Rect _rect() {
    final ro = _box.currentContext?.findRenderObject();
    return ro is RenderBox && ro.attached ? ro.localToGlobal(Offset.zero) & ro.size : Rect.zero;
  }

  WorldItem get _world => worldOf(widget.item);
  WorldAvailability? get _first => _world.available.firstOrNull;
  bool get _infoOnly => widget.item.world != null && _first == null;

  void _noted() {
    final g = _world.genres.firstOrNull;
    if (g != null) ref.read(rerankNotesProvider.notifier).noteOpenedFromRail(g);
  }

  Future<void> _open({Offset? velocity}) async {
    final from = _rect();
    _noted();
    if (_infoOnly) {
      await _infoMenu(from);
      return;
    }
    final av = _world.available;
    if (av.length > 1) {
      await showGlassMenu(
        context,
        anchor: from,
        title: 'Open on',
        entries: [for (final a in av) GlassMenuEntry(label: 'On ${a.sourceName}', onSelected: () => unawaited(openSeries(ref, a.sourceId, a.seriesKey, from: from, velocity: velocity)))],
      );
      return;
    }
    await openSeries(ref, _first!.sourceId, _first!.seriesKey, from: from, velocity: velocity);
  }

  Future<void> _infoMenu(Rect from) {
    final w = _world;
    final platform = w.platforms.firstOrNull;
    return showGlassMenu(
      context,
      anchor: from,
      title: 'Not on your sources',
      entries: [
        GlassMenuEntry(label: 'Search my sources', onSelected: () => unawaited(ref.read(skinRouterProvider).push<void>(Routes.discover({'q': w.title})))),
        if (platform != null)
          GlassMenuEntry(
            label: 'Read on ${platform.site}',
            onSelected: () => unawaited(() async {
              try {
                final ok = await launchUrl(Uri.parse(platform.url), mode: LaunchMode.externalApplication);
                if (!ok) throw StateError('launch');
              } catch (_) {
                showGlassToast(ref, GlassToastSpec("Couldn't open ${platform.site}", kind: GlassToastKind.error));
              }
            }()),
          ),
      ],
    );
  }

  void _notInterested({double? velocity}) {
    final w = _world;
    final fb = ref.read(aiFeedbackProvider);
    if (velocity == null) glassFire(ref, HapticEvent.throwCommit, velocity: 0);
    unawaited(fb.notInterested(w, hide: false));
    final id = pickId(w);
    final dismissed = ref.read(dismissedPicksProvider.notifier);
    Timer(const Duration(milliseconds: 380), () {
      try {
        dismissed.add(id);
      } catch (_) {}
    });
    showGlassToast(ref, GlassToastSpec("We'll show fewer like this", undo: () => unawaited(fb.undoNotInterested(w))));
  }

  void _menu() {
    final from = _rect();
    unawaited(showGlassMenu(
      context,
      anchor: from,
      title: _world.title,
      entries: [
        GlassMenuEntry(label: _infoOnly ? 'Not on your sources' : 'Details', enabled: !_infoOnly, onSelected: () => unawaited(_open())),
        if (widget.ai) ...[
          GlassMenuEntry(label: 'Not interested', onSelected: _notInterested),
          GlassMenuEntry(
            label: 'More like this one',
            onSelected: () => unawaited(() async {
              await ref.read(aiFeedbackProvider).likedPick(_world);
              if (_infoOnly || _first == null) {
                unawaited(ref.read(skinRouterProvider).push<void>(Routes.picks()));
              } else {
                unawaited(openSeries(ref, _first!.sourceId, _first!.seriesKey, from: from, query: 'focus=more-like-this'));
              }
            }()),
          ),
        ],
        if (_infoOnly) GlassMenuEntry(label: 'Search my sources', onSelected: () => unawaited(ref.read(skinRouterProvider).push<void>(Routes.discover({'q': _world.title})))),
      ],
    ),);
  }

  KeyEventResult _key(FocusNode n, KeyEvent e) {
    if (e is! KeyDownEvent || !widget.ai) return KeyEventResult.ignored;
    if (e.logicalKey == LogicalKeyboardKey.delete || e.logicalKey == LogicalKeyboardKey.backspace) {
      _notInterested();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final w = _world;
    final why = widget.item.why ?? w.why;
    final h = widget.env.handlers;
    final has = _first != null && !_infoOnly;
    final poster = GlassPoster(
      key: _box,
      cover: HomeHero(sourceId: _first?.sourceId ?? '', seriesKey: _first?.seriesKey ?? w.title, child: HomeCoverImage(url: w.coverUrl)),
      title: w.title,
      lMax: widget.item.palette?.lMax ?? 0.5,
      allowAway: widget.ai,
      targets: has ? h.targets : null,
      onTap: () => unawaited(_open()),
      onContextPreview: _menu,
      onThrowOpen: (v) => unawaited(_open(velocity: v)),
      onThrowAway: (v) => _notInterested(velocity: v.distance),
      onDropOnTarget: has ? (id) => recommendTo(context, ref, sourceId: _first!.sourceId, seriesKey: _first!.seriesKey, profileId: id) : null,
      onLiftPhase: has ? h.onLiftPhase?.call(_first!.sourceId, _first!.seriesKey, _rect) : null,
      onMagnetChanged: h.onMagnetChanged,
    );
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onKeyEvent: _key,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              poster,
              if (widget.ai)
                Positioned.fill(
                  child: IgnorePointer(child: DecoratedBox(decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: gt.colorMachineRim, width: 0.5)))),
                ),
            ],
          ),
          const SizedBox(height: 8),
          GlassLabel(w.title, role: gt.typeFootnote, wght: 600, maxLines: 2),
          if (_infoOnly) GlassLabel('Not on your sources', role: gt.typeCaption1, color: gt.colorLabel3),
          if (why != null)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.ai) const Padding(padding: EdgeInsets.only(top: 2, right: 4), child: MachineBadge(size: 12)),
                Expanded(child: GlassLabel(why, role: gt.typeCaption1, italic: true, color: gt.colorLabel2, maxLines: 2)),
              ],
            ),
        ],
      ),
    );
  }
}
