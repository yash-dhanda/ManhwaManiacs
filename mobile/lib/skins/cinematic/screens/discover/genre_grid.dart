import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/ai/providers/ai_providers.dart';
import 'package:manhwamaniacs/features/library/models/world_item.dart';
import 'package:manhwamaniacs/features/library/providers/intelligence_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/icons/phosphor.g.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/cine_extras.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/cine_kit.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/picks/for_you_grid.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/picks/world_card_tile.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

/// A genre opened from Discover: an endless grid of World cards from
/// `GET /discover/genre/{genre}/ai`, every title verified by the server.
/// The next page is fetched once the scroll passes 70 %; pull to reprint
/// replaces the grid with a fresh batch (the next page, never a repeat).
class GenreGridScreen extends ConsumerStatefulWidget {
  const GenreGridScreen({super.key, required this.genre, this.onSources});

  final String genre;

  /// Opens the pinned sources' own catalogues for this genre; null hides it.
  final Future<void> Function(BuildContext, WidgetRef)? onSources;

  @override
  ConsumerState<GenreGridScreen> createState() => _GenreGridScreenState();
}

class _GenreGridScreenState extends ConsumerState<GenreGridScreen> {
  final _scroll = ScrollController();
  final _items = <WorldItem>[];
  final _seen = <String>{};
  String? _cursor = '0';
  bool _loading = false;
  bool _fromCatalogue = false;
  AppError? _error;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    unawaited(_load());
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    final p = _scroll.position;
    if (p.pixels >= p.maxScrollExtent * 0.7) unawaited(_load());
  }

  Future<void> _load({bool replace = false}) async {
    if (_loading || _cursor == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final r = await ref
        .read(askRepositoryProvider)
        .genrePage(widget.genre, cursor: _cursor);
    if (!mounted) return;
    var added = 0;
    setState(() {
      _loading = false;
      switch (r) {
        case Ok(:final value):
          if (replace) _items.clear();
          for (final i in value.items) {
            if (_seen.add(pickId(i))) {
              _items.add(i);
              added++;
            }
          }
          _cursor = value.nextCursor;
          _fromCatalogue = value.fromCatalogue;
        case Err(:final error):
          _error = error;
      }
    });
    // A short page leaves nothing to scroll, so nothing would ever ask for
    // more; a page that added nothing stops here (Load more still works).
    if (added > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scroll.hasClients) _onScroll();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.cine;
    final dismissed = ref.watch(dismissedPicksProvider);
    final items = [
      for (final i in _items)
        if (!dismissed.contains(pickId(i))) i,
    ];
    final cols = forYouColumns(MediaQuery.sizeOf(context).width);
    final rows = (items.length / cols).ceil();
    final tablet = isTablet(context);
    final side = tablet ? CineSpace.s8 : CineSpace.s4;

    Widget footer() {
      if (_error != null && items.isNotEmpty) {
        return Row(
          children: [
            Expanded(
              child: Text(
                "More didn't load.",
                style: cineText(context, t.typeCaption, color: t.colorProof),
              ),
            ),
            QuietButton('Retry', onPressed: _load),
          ],
        );
      }
      if (_error != null) {
        return CineNotice(
          kicker: 'Correction',
          kickerColor: t.colorProof,
          headline: "This genre didn't load.",
          deck: _error!.userMessage,
          actions: [QuietButton('Retry', onPressed: _load)],
        );
      }
      if (_loading && items.isEmpty) {
        return DelayedShow(
          delay: const Duration(milliseconds: 120),
          child: Column(
            children: [
              for (var i = 0; i < 3; i++) ...[
                const FlickerPlate(height: 156),
                const SizedBox(height: CineSpace.s3),
              ],
            ],
          ),
        );
      }
      if (_loading) return const Center(child: LeaderDial(size: 24));
      if (_cursor == null) {
        return items.isEmpty
            ? const CineNotice(
                kicker: 'Nothing found',
                headline: 'Nothing more in this genre.',
              )
            : const Kicker('End of the list');
      }
      return QuietButton('Load more', onPressed: _load);
    }

    return Scaffold(
      backgroundColor: t.colorPaper0,
      body: SafeArea(
        child: CinePullToReprint(
          onRefresh: () => _load(replace: true),
          child: CustomScrollView(
            controller: _scroll,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    side,
                    CineSpace.s4,
                    side,
                    CineSpace.s8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton(
                        tooltip: 'Back',
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: Icon(
                          PhosphorRegular.arrowLeft,
                          color: t.colorInk100,
                        ),
                      ),
                      const Kicker('No. 04 — Discover / Genre'),
                      HeadingFocus(
                        child: SetHeading(
                          widget.genre,
                          id: 'genre-${widget.genre}',
                          style: cineText(context, t.typeMasthead),
                          cap: t.typeMasthead.cap,
                          level: 1,
                          trigger: SetTrigger.mount,
                        ),
                      ),
                      Text(
                        _fromCatalogue
                            ? "The editors are away, so this is the catalogue's own list."
                            : 'Picked by the editors from everywhere, each one checked against a worldwide catalogue.',
                        style: cineText(
                          context,
                          t.typeDeck,
                          color: t.colorInk60,
                        ),
                      ),
                      if (widget.onSources != null)
                        QuietButton(
                          'On your sources',
                          onPressed: () =>
                              unawaited(widget.onSources!(context, ref)),
                        ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: side),
                sliver: SliverList.builder(
                  itemCount: rows,
                  itemBuilder: (context, r) => Padding(
                    padding: const EdgeInsets.only(bottom: CineSpace.s3),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var c = 0; c < cols; c++) ...[
                          if (c > 0) const SizedBox(width: CineSpace.s3),
                          Expanded(
                            child: r * cols + c < items.length
                                ? WorldCardTile(
                                    key: ValueKey(
                                      'genre-${pickId(items[r * cols + c])}',
                                    ),
                                    item: items[r * cols + c],
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  side,
                  CineSpace.s3,
                  side,
                  CineSpace.s16,
                ),
                sliver: SliverToBoxAdapter(child: footer()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
