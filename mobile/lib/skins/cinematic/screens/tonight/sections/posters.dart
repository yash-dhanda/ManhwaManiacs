import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/ai/providers/ai_providers.dart';
import 'package:manhwamaniacs/features/home/models/home_feed.dart';
import 'package:manhwamaniacs/features/home/utils/rerank.dart';
import 'package:manhwamaniacs/skins/cinematic/parts/quick_look_builders.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_badge.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_poster.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_rail.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/quick_look.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/rail_math.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/tonight/sections.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/tonight/tonight_layout.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

CineAiReason _reason(String? note) => switch (note) {
      'budget_exhausted' || 'ai_budget_exhausted' => CineAiReason.budget,
      'not_configured' || 'ai_not_configured' => CineAiReason.notConfigured,
      'rate_limited' => CineAiReason.rateLimited,
      _ => CineAiReason.failed,
    };

/// The poster rails: `first_picks`, `new_this_week`, `almost_there`, `where_were_we`, `picked`,
/// `because`, `popular` and the offline edition's `saved` (cinematic 8.8, 7.8).
class PostersSection extends ConsumerStatefulWidget {
  const PostersSection({super.key, required this.plan, required this.env});
  final PlannedSection plan;
  final TonightEnv env;

  @override
  ConsumerState<PostersSection> createState() => _PostersSectionState();
}

class _PostersSectionState extends ConsumerState<PostersSection> {
  final Set<int> _fading = {}, _gone = {};

  HomeSection get _s => widget.plan.section;

  /// The visible items with their index in the section (the Hero tag key).
  List<(int, Object)> get _items {
    // Cards dismissed with Not for me anywhere in the app are gone from these rails too.
    final dismissed = ref.watch(dismissedPicksProvider);
    return [
      for (var i = 0; i < _s.items.length; i++)
        if (!_gone.contains(i) && !_dismissedItem(_s.items[i], dismissed)) (i, _s.items[i]),
    ];
  }

  bool _dismissedItem(Object it, Set<String> dismissed) {
    if (it is! HomePickItem) return false;
    final w = it.world;
    return dismissed.contains(w != null ? pickId(w) : 's${it.source!.sourceId}:${it.source!.id}');
  }

  void _notForMe(int i) {
    setState(() => _fading.add(i));
    Timer(const Duration(milliseconds: 240), () {
      if (mounted) setState(() => _gone.add(i));
    });
  }

  String _id() {
    final seed = _s.seed?.title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    return 'tonight.${_s.type.wire}${seed == null ? '' : '.$seed'}';
  }

  ({int start, int end})? _roman() {
    final seed = _s.seed?.title;
    if (seed == null || _s.type != HomeSectionType.because || !_s.title.endsWith(seed)) return null;
    final start = _s.title.characters.length - seed.characters.length;
    return (start: start, end: _s.title.characters.length);
  }

  @override
  Widget build(BuildContext context) {
    final s = _s;
    final env = widget.env;
    final items = _items;
    final ai = isAiSection(s.type);
    final shelf = s.type == HomeSectionType.picked && s.fallback == 'shelf' && s.state == HomeSectionState.unavailable;
    final stale = s.state == HomeSectionState.stale && !ai && s.generatedAt != null ? ageShort(s.generatedAt!, env.now) : null;
    final picked = ai && !shelf ? pickedAgo(s.generatedAt, env.now) : null;
    final failed = !s.hasItems;

    final rail = CineRail(
      headingId: _id(),
      heading: s.title,
      folio: widget.plan.folio,
      itemCount: items.length,
      state: failed
          ? CineRailState.error
          : shelf
              ? CineRailState.aiUnavailable
              : CineRailState.ready,
      aiReason: shelf ? _reason(s.note) : null,
      fallback: shelf ? _ShelfRow(items: items, builder: _poster) : null,
      staleAgo: stale,
      pickedAgo: picked,
      onRetry: env.refresh,
      onSeeAll: seeAllFor(context, s.type),
      roman: _roman(),
      itemBuilder: (context, i, w, node) => _poster(context, items[i].$1, items[i].$2, node: node),
    );
    return Padding(padding: EdgeInsets.only(bottom: tonightWide(context) ? 64 : 40), child: rail);
  }

  Widget _poster(BuildContext context, int index, Object item, {FocusNode? node}) {
    final env = widget.env;
    final tag = env.tags.of('${widget.plan.index}:$index');
    Widget poster;
    if (item is HomeSeriesItem) {
      poster = _seriesPoster(context, index, item, tag, node);
    } else if (item is HomePickItem) {
      poster = _pickPoster(context, index, item, tag, node);
    } else if (item is HomeSavedItem) {
      poster = CinePoster(
        title: item.title,
        url: coverAbs(ref, item.coverUrl),
        folio: '${item.chapters} SAVED',
        heroTag: tag,
        focusNode: node,
        onTap: () => openSeries(context, item.sourceId, item.seriesKey),
      );
    } else {
      poster = const SizedBox.shrink();
    }
    return AnimatedOpacity(opacity: _fading.contains(index) ? 0 : 1, duration: const Duration(milliseconds: 240), child: poster);
  }

  Widget _seriesPoster(BuildContext context, int index, HomeSeriesItem item, (String, String)? tag, FocusNode? node) {
    final s = item.series;
    final rs = s.readState;
    final type = widget.plan.section.type;
    final n = rs?.newCount ?? 0;
    String folio;
    Color? folioColor;
    var badges = <Widget>[];
    switch (type) {
      case HomeSectionType.newThisWeek:
        folio = '${chapterFolio(rs?.chapterNumber)}${n > 0 ? ' · ${n > 99 ? '99+' : n} NEW' : ''}';
        if (n > 0) badges = [CineBadge.newCount(n, onArt: true)];
      case HomeSectionType.almostThere:
        folio = '${item.chaptersLeft ?? 1} LEFT';
        folioColor = context.cine.colorSpot;
      case HomeSectionType.whereWereWe:
        final ago = agoCaption(item.lastReadAt, widget.env.now);
        folio = [if (ago.isNotEmpty) ago, chapterFolio(rs?.chapterNumber)].where((e) => e.isNotEmpty).join(' · ');
      default:
        folio = chapterFolio(rs?.chapterNumber);
    }
    return CineQuickLookTarget(
      onOpen: () => unawaited(openFollowedQuickLook(context, ref, item, entry: widget.env.entry, recapFirst: type == HomeSectionType.whereWereWe, heroTag: tag)),
      child: CinePoster(
        title: s.title,
        url: coverAbs(ref, s.coverUrl),
        folio: folio,
        folioColor: folioColor,
        badges: badges,
        heroTag: tag,
        duo: item.ambient?.duo,
        focusNode: node,
        flickerIndex: index,
        onTap: () => openSeries(context, s.sourceId, s.seriesKey),
      ),
    );
  }

  Widget _pickPoster(BuildContext context, int index, HomePickItem item, (String, String)? tag, FocusNode? node) {
    final w = item.world;
    final info = w != null && w.available.isEmpty;
    final type = widget.plan.section.type;
    String? folio;
    if (info) {
      folio = 'NOT ON YOUR SOURCES';
    } else if (type == HomeSectionType.firstPicks) {
      folio = 'NOT STARTED';
    }
    return CineQuickLookTarget(
      onOpen: () => unawaited(openPickQuickLook(context, ref, item, entry: widget.env.entry, heroTag: tag, onNotForMe: () => _notForMe(index))),
      child: CinePoster(
        title: item.title,
        url: coverAbs(ref, w?.coverUrl ?? item.source?.coverUrl),
        folio: folio,
        badges: [if (w != null && (w.isAdult)) CineBadge.certificate(onArt: true)],
        heroTag: info ? null : tag,
        duo: item.ambient?.duo,
        duotone: info ? (item.ambient?.duo ?? context.cine.colorAmbientFallbackDuo) : null,
        focusNode: node,
        flickerIndex: index,
        onTap: () {
          final g = item.world?.genres.firstOrNull ?? item.source?.genres.firstOrNull;
          if (g != null) ref.read(rerankNotesProvider.notifier).noteOpenedFromRail(g);
          openPick(context, item);
        },
      ),
    );
  }
}

/// The shelf that replaces `Picked for you` while the AI desk is closed.
class _ShelfRow extends StatelessWidget {
  const _ShelfRow({required this.items, required this.builder});
  final List<(int, Object)> items;
  final Widget Function(BuildContext context, int index, Object item, {FocusNode? node}) builder;

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.sizeOf(context).width;
    final gap = railGap(screenW);
    return LayoutBuilder(builder: (context, box) {
      final visible = railVisible(width: screenW, textScale: cineScale(context));
      final w = railPosterWidth(contentWidth: box.maxWidth, visible: visible, gap: gap);
      return SizedBox(
        height: 1.5 * w + 8 + 2 * 20 + 2 + 16 + 16,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const ClampingScrollPhysics(),
          itemCount: items.length,
          itemBuilder: (context, i) => Padding(
            padding: EdgeInsets.only(right: gap),
            child: SizedBox(width: w, child: builder(context, items[i].$1, items[i].$2)),
          ),
        ),
      );
    },);
  }
}
