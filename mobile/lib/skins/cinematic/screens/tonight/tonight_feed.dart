import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/network/api_image.dart';
import 'package:manhwamaniacs/core/time/clock.dart';
import 'package:manhwamaniacs/features/home/models/home_feed.dart';
import 'package:manhwamaniacs/features/home/providers/home_feed_provider.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/features/recap/models/recap_origin.dart';
import 'package:manhwamaniacs/features/sources/models/source.dart';
import 'package:manhwamaniacs/features/sources/providers/sources_provider.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/navigation.dart';
import 'package:manhwamaniacs/skins/cinematic/parts/quick_look_builders.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/ambient_scope.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_lightbox.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_pull_to_reprint.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/layout/cine_grid.dart';
import 'package:manhwamaniacs/skins/cinematic/recap/continue_to.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/tonight/also_in_this_issue.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/tonight/cover_story_header.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/tonight/cover_story_parts.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/tonight/cover_story_phone.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/tonight/cover_story_spread.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/tonight/novel_title_page.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/tonight/sections.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/tonight/tonight_footer.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/tonight/tonight_layout.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/tonight/tonight_shortcuts.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/tonight/tonight_states.dart';
import 'package:manhwamaniacs/skins/cinematic/shell/running_head.dart';
import 'package:manhwamaniacs/skins/cinematic/tint.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// The scrolling issue: the pinned cover story header (the trailer scrub), the actions, Also in this
/// issue, the numbered sections and the footer (cinematic 8.8).
class TonightFeed extends ConsumerStatefulWidget {
  const TonightFeed({super.key, required this.view, required this.commands, required this.headlineFocus, required this.animateHeadline, required this.onTyped});

  final HomeFeedView view;
  final TonightCommands commands;
  final FocusNode headlineFocus;

  /// The Front page moment (once per day per profile).
  final bool animateHeadline;
  final VoidCallback onTyped;

  @override
  ConsumerState<TonightFeed> createState() => _TonightFeedState();
}

class _TonightFeedState extends ConsumerState<TonightFeed> {
  final ScrollController _scroll = ScrollController();
  final TypedHeadlineController _typed = TypedHeadlineController();
  final FocusNode _page = FocusNode(debugLabel: 'tonight-page');
  CineEditionPhase _edition = CineEditionPhase.none;
  Timer? _editionTimer;
  bool _scrolled = false;

  HomeFeed get _feed => widget.view.feed!;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      // Only a feed with no cover story paints a solid head; the scrub header owns that otherwise, and a
      // rebuild of the page from a scroll would be a rebuild of every row below it.
      if (_feed.cover != null) return;
      final s = _scroll.hasClients && _scroll.offset > 24;
      if (s != _scrolled && mounted) setState(() => _scrolled = s);
    });
    _syncEdition();
    _wire();
  }

  @override
  void didUpdateWidget(TonightFeed old) {
    super.didUpdateWidget(old);
    if (old.view.offline != widget.view.offline) _syncEdition();
    _wire();
  }

  void _syncEdition() {
    _editionTimer?.cancel();
    if (widget.view.offline) {
      _edition = CineEditionPhase.badge;
      _editionTimer = Timer(CineDur.holdEdition, () {
        if (mounted) setState(() => _edition = CineEditionPhase.glyph);
      });
    } else {
      _edition = CineEditionPhase.none;
    }
  }

  void _wire() {
    final c = widget.commands;
    final cover = _feed.cover;
    c.reprint = _reprint;
    c.continueReading = cover?.chapterKey == null ? null : _continue;
    c.previouslyOn = (cover?.recap?.available ?? false) && cover?.chapterKey != null ? _recap : null;
    c.viewCover = cover == null ? null : _lightbox;
    c.sectionBy = _sectionBy;
  }

  @override
  void dispose() {
    _editionTimer?.cancel();
    _scroll.dispose();
    _page.dispose();
    super.dispose();
  }

  Future<void> _reprint() => ref.read(homeFeedProvider.notifier).refresh();

  void _continue() {
    final cv = _feed.cover;
    if (cv?.chapterKey == null) return;
    unawaited(continueTo(context, ref, sourceId: cv!.sourceId, seriesKey: cv.seriesKey, chapterKey: cv.chapterKey!, title: cv.title, lastReadAt: cv.pausedDays > 0 ? ref.read(clockProvider)().subtract(Duration(days: cv.pausedDays)) : null, recap: cv.recap, origin: RecapEntry.wipe));
  }

  void _dwell() {
    final cv = _feed.cover;
    if (cv?.chapterKey == null) return;
    readerPrefetchOf(ref).onDwell(readerTargetFor(cv!.sourceId, cv.seriesKey, cv.chapterKey!, novel: cv.isNovel));
  }

  void _recap() {
    final cv = _feed.cover;
    if (cv?.chapterKey != null) openRecap(context, cv!.sourceId, cv.seriesKey, cv.chapterKey!);
  }

  void _details() {
    final cv = _feed.cover;
    if (cv != null) openSeries(context, cv.sourceId, cv.seriesKey);
  }

  void _lightbox() {
    final cv = _feed.cover;
    if (cv == null) return;
    final url = coverAbs(ref, cv.coverUrl);
    if (url == null) return;
    final headers = apiImageHttpHeaders(ref.read(authTokenStoreProvider).token, profileId: ref.read(activeProfileProvider)?.id);
    unawaited(openCineLightbox(
      context,
      heroTag: (cv.sourceId, cv.seriesKey),
      image: CachedNetworkImageProvider(url, headers: headers),
      title: cv.title,
      folio: 'COVER · 720 × 1080',
    ),);
  }

  /// `Down` and `Up` move focus between sections; the page scrolls the new stop to 30 % of the view.
  void _sectionBy(int delta) {
    final scope = FocusScope.of(context);
    final moved = scope.focusInDirection(delta > 0 ? TraversalDirection.down : TraversalDirection.up);
    if (!moved) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final f = FocusManager.instance.primaryFocus?.context;
      if (f != null && f.mounted) {
        Scrollable.ensureVisible(f, alignment: 0.3, duration: CineMotion.reduced(context) ? Duration.zero : CineDur.column, curve: CineCurves.settle);
      }
    });
  }

  String _sourceName(String id) {
    for (final s in ref.watch(sourcesListProvider).valueOrNull ?? const <SourceSummary>[]) {
      if (s.id == id) return s.name;
    }
    return id;
  }

  Widget _runningHead(BuildContext context, {required bool solid, required bool overArt}) => CineRunningHead(
        title: 'Tonight',
        overArt: overArt,
        solid: solid,
        edition: _edition,
        onEditionGlyph: () => goSection(context, 3),
      );

  @override
  Widget build(BuildContext context) {
    final feed = _feed;
    final cover = feed.cover;
    final now = ref.read(clockProvider)();
    final wide = tonightWide(context);
    final grid = CineGrid.of(context);
    final topInset = MediaQuery.viewPaddingOf(context).top;
    final tags = HeroTags.of(feed);
    final env = TonightEnv(feed: feed, tags: tags, now: now, refresh: () => unawaited(_reprint()));
    final reduced = CineMotion.reduced(context);
    final plans = planSections(feed);
    final gap = wide ? 64.0 : 40.0;
    final hPad = EdgeInsets.only(left: grid.left, right: grid.right);

    CoverStoryData? data;
    CoverLayout? layout;
    if (cover != null) {
      data = CoverStoryData(
        feed: feed,
        cover: cover,
        imageUrl: coverAbs(ref, cover.coverUrl),
        heroTag: tags.of('cover'),
        now: now,
        animateHeadline: widget.animateHeadline,
        headlineFocus: widget.headlineFocus,
        typed: _typed,
        onTyped: widget.onTyped,
        onContinue: _continue,
        onDwell: _dwell,
        onRecap: _recap,
        onDetails: _details,
        onLightbox: _lightbox,
        onRefresh: () => unawaited(_reprint()),
      );
      final credits = <(String, String)>[
        if (cover.author != null) ('STORY', cover.author!),
        ('SOURCE', _sourceName(cover.sourceId)),
        if (cover.newCount > 0) ('NEW CHAPTERS', '${cover.newCount}'),
      ];
      layout = cover.isNovel
          ? NovelCoverLayout.of(context, data, credits: credits)
          : (wide ? SpreadCoverLayout.of(context, data, credits: credits) : PhoneCoverLayout.of(context, data));
    }

    final ambient = cover?.ambient == null ? null : AmbientRoles(duo: cover!.ambient!.duo, tint: cover.ambient!.tint, ink: cover.ambient!.ink);

    final slivers = <Widget>[
      if (layout != null)
        SliverPersistentHeader(
          pinned: true,
          delegate: _AmbientHeader(
            ambient: ambient,
            inner: CoverStoryHeaderDelegate(
              layout: layout,
              topInset: topInset,
              side: grid.left,
              runningHead: _runningHead(context, solid: false, overArt: true),
              pageFocus: _page,
              reducedMotion: reduced,
              signature: _edition,
            ),
          ),
        )
      else
        SliverToBoxAdapter(child: _noCover(context, feed, data)),
      if (layout != null && !wide) SliverToBoxAdapter(child: Padding(padding: hPad.copyWith(top: 16), child: CoverActions(data: data!))),
      SliverToBoxAdapter(child: Padding(padding: hPad.copyWith(top: gap), child: AlsoInThisIssue(env: env))),
      for (final p in plans) SliverToBoxAdapter(child: Padding(padding: hPad.copyWith(top: p == plans.first && feed.also.length < 2 ? gap : 0), child: buildSection(p, env))),
      SliverToBoxAdapter(child: Padding(padding: hPad, child: TonightFooter(feed: feed))),
    ];

    final scroll = CustomScrollView(controller: _scroll, slivers: slivers);
    return Focus(
      focusNode: _page,
      skipTraversal: true,
      child: Stack(children: [
        Positioned.fill(child: CinePullToReprint(onRefresh: _reprint, child: scroll)),
        if (layout == null) Positioned(top: 0, left: 0, right: 0, child: _runningHead(context, solid: _scrolled, overArt: false)),
      ],),
    );
  }

  Widget _noCover(BuildContext context, HomeFeed feed, CoverStoryData? _) {
    final offline = widget.view.offline;
    return TonightHeadBlock(
      feed: feed,
      headline: _plainHeadline(context, feed),
      actionLabel: offline ? 'Go to Downloads' : 'Find something',
      onAction: () => goSection(context, offline ? 3 : 2),
    );
  }

  Widget _plainHeadline(BuildContext context, HomeFeed feed) {
    final c = context.cine;
    final grid = CineGrid.of(context);
    final role = fitCoverRole(context, feed.headline, MediaQuery.sizeOf(context).width - grid.left - grid.right, maxLines: 3);
    final style = CineText.style(context, role).copyWith(color: c.colorInk100);
    return Focus(
      focusNode: widget.headlineFocus,
      skipTraversal: true,
      child: widget.animateHeadline
          ? TypedHeadline(feed.headline, style: style, cap: role.cap, level: 1, controller: _typed, onDone: widget.onTyped)
          : Semantics(header: true, headingLevel: 1, label: feed.headline, excludeSemantics: true, child: Text(feed.headline, style: style, textScaler: CineText.scaler(context, role))),
    );
  }
}

/// Puts the cover story's ambient colours around the header's build.
class _AmbientHeader extends SliverPersistentHeaderDelegate {
  _AmbientHeader({required this.ambient, required this.inner});
  final AmbientRoles? ambient;
  final CoverStoryHeaderDelegate inner;

  @override
  double get maxExtent => inner.maxExtent;

  @override
  double get minExtent => inner.minExtent;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) =>
      CineAmbient(ambient: ambient, child: inner.build(context, shrinkOffset, overlapsContent));

  @override
  bool shouldRebuild(_AmbientHeader old) => old.ambient != ambient || inner.shouldRebuild(old.inner);
}
