import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/network/api_image.dart';
import 'package:manhwamaniacs/features/home/models/home_feed.dart';
import 'package:manhwamaniacs/features/library/models/followed_series.dart';
import 'package:manhwamaniacs/features/library/providers/shelf_provider.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/icons/icon_roles.g.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/navigation.dart';
import 'package:manhwamaniacs/skins/cinematic/parts/quick_look_builders.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cards/cine_cutting_card.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_icon_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_section_header.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/quick_look.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/tonight/sections/tonight_rail.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/tonight/tonight_layout.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// The `3 NEW`, `ALMOST DONE`, `PAUSED 21 D` badge of a cutting, from what the shelf knows.
String? cuttingNudge(HomeContinueItem it, FollowedSeries? follow, DateTime now) {
  final fresh = follow?.readState?.newCount ?? 0;
  if (fresh > 0) return '${fresh > 99 ? '99+' : fresh} NEW';
  if (it.row.pageCount > 0 && it.row.progressPct >= 0.85) return 'ALMOST DONE';
  final at = it.row.lastReadAt;
  if (at != null && now.difference(at).inDays >= 21) return 'PAUSED ${now.difference(at).inDays} D';
  return null;
}

/// `CH 142 · 63%` or `NEXT · CH 143` when the chapter has no pages read yet.
String cuttingFolio(HomeContinueItem it) {
  final r = it.row;
  if (r.pageCount == 0) return 'NEXT · ${chapterFolio(r.chapterNumber)}';
  return '${chapterFolio(r.chapterNumber)} · ${(r.progressPct * 100).round()}%';
}

/// Continue reading on the shelf (cinematic 8.9): shown only with no filter and no search. A pager
/// of cuttings at 86 % on phones, a rail with 3.2 visible on tablets. A tap enters the reader by
/// Dip (Library cuttings never use the Column wipe, 8.14.2).
class ShelfContinue extends ConsumerStatefulWidget {
  const ShelfContinue({super.key, required this.items, required this.follows, required this.now});
  final List<HomeContinueItem> items;

  /// The shelf's rows by `(sourceId, seriesKey)`, for the nudges.
  final Map<(String, String), FollowedSeries> follows;
  final DateTime now;

  @override
  ConsumerState<ShelfContinue> createState() => _ShelfContinueState();
}

class _ShelfContinueState extends ConsumerState<ShelfContinue> {
  final PageController _pager = PageController(viewportFraction: 0.86);
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _pager.addListener(() {
      final p = _pager.hasClients ? (_pager.page ?? 0).round() : 0;
      if (p != _page && mounted) setState(() => _page = p);
    });
  }

  @override
  void dispose() {
    _pager.dispose();
    super.dispose();
  }

  void _go(int page) {
    final to = page.clamp(0, widget.items.length - 1);
    if (CineMotion.reduced(context)) {
      _pager.jumpToPage(to);
    } else {
      _pager.animateToPage(to, duration: CineDur.column, curve: CineCurves.settle);
    }
  }

  String? _abs(String? url) => url == null || url.isEmpty ? null : resolveApiResourceUrl(ref.read(apiBaseUrlProvider), url);

  Widget _cutting(HomeContinueItem it) {
    final r = it.row;
    final card = CineCuttingCard(
      title: r.title ?? 'Continue',
      folio: cuttingFolio(it),
      imageUrl: _abs(r.coverUrl),
      progress: r.pageCount > 0 ? r.progressPct.clamp(0.0, 1.0) : null,
      nudge: cuttingNudge(it, widget.follows[(r.sourceId, r.seriesKey)], widget.now),
      onTap: () => continueTo(context, ref, r.sourceId, r.seriesKey, r.chapterKey, entry: ReaderEntry.dip),
    );
    return CineQuickLookTarget(
      onOpen: () => unawaited(openCuttingQuickLook(context, ref, it, entry: ReaderEntry.dip)),
      child: card,
    );
  }

  double _height(BuildContext context, double w) {
    final c = context.cine;
    return w * 2 / 3 + c.space2 + roleLineHeight(context, c.typeTitle) + c.space1 / 2 + roleLineHeight(context, c.typeFolio) + 4;
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    if (items.isEmpty) return const SizedBox.shrink();
    final c = context.cine;
    if (tonightWide(context)) {
      return TonightRail(
        headingId: 'library.continue',
        heading: 'Continue reading',
        folio: '01',
        itemCount: items.length,
        visiblePhone: 1.6,
        visibleTablet: 3.2,
        itemHeight: (w) => _height(context, w),
        itemBuilder: (context, i, w) => _cutting(items[i]),
      );
    }
    final pageW = MediaQuery.sizeOf(context).width * 0.86;
    return Padding(
      padding: const EdgeInsets.only(bottom: 40),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const CineSectionHeader(headingId: 'library.continue', heading: 'Continue reading', folio: '01'),
        SizedBox(height: c.space3),
        SizedBox(
          height: _height(context, pageW - 12),
          child: PageView.builder(
            key: const Key('shelf-continue-pager'),
            controller: _pager,
            itemCount: items.length,
            itemBuilder: (context, i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: ExcludeSemantics(excluding: i != _page, child: _cutting(items[i])),
            ),
          ),
        ),
        SizedBox(height: c.space3),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          CineIconButton(
            key: const Key('shelf-continue-prev'),
            label: 'Previous cutting',
            role: CineIconRole.back,
            variant: CineIconButtonVariant.ruled,
            onPressed: _page > 0 ? () => _go(_page - 1) : null,
          ),
          SizedBox(width: c.space4),
          CineRoleText('${math.min(_page + 1, items.length)} / ${items.length}', c.typeFolio, color: c.colorInk45),
          SizedBox(width: c.space4),
          CineIconButton(
            key: const Key('shelf-continue-next'),
            label: 'Next cutting',
            codepoint: CineGlyph.arrowRight,
            variant: CineIconButtonVariant.ruled,
            onPressed: _page < items.length - 1 ? () => _go(_page + 1) : null,
          ),
        ],),
      ],),
    );
  }
}

/// The continue rows of [shelfContinueProvider], or nothing while loading or failed (the row is
/// optional; the wall is the page).
class ShelfContinueSection extends ConsumerWidget {
  const ShelfContinueSection({super.key, required this.follows, required this.now});
  final Map<(String, String), FollowedSeries> follows;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(shelfContinueProvider).valueOrNull;
    if (items == null || items.isEmpty) return const SizedBox.shrink();
    return ShelfContinue(items: items, follows: follows, now: now);
  }
}
