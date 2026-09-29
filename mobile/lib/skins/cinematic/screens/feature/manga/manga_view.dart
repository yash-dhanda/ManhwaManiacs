import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/downloads/models/chapter_selection.dart';
import 'package:manhwamaniacs/features/downloads/models/download_chapter_state.dart';
import 'package:manhwamaniacs/features/downloads/providers/series_download_status_provider.dart';
import 'package:manhwamaniacs/features/downloads/queue/download_queue_controller.dart';
import 'package:manhwamaniacs/features/library/providers/device_online_provider.dart';
import 'package:manhwamaniacs/features/library/utils/cover_url.dart';
import 'package:manhwamaniacs/features/settings/providers/settings_provider.dart';
import 'package:manhwamaniacs/features/sources/providers/source_progress_provider.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_ambient.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/downloads/selection_bar.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/feature_data.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/feature_feedback.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/feature_lightbox.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/feature_shortcuts.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/feature_states.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/feature_tabs.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/manga/chapters_panel.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/manga/details_panel.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/manga/feature_actions.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/manga/feature_hero.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/manga/feature_overflow.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/manga/rating_card.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/manga/repoint_sheet.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// The manga Feature page: hero or spread, then pinned contents tabs over
/// swipeable CHAPTERS / DETAILS panels.
class MangaFeatureView extends ConsumerStatefulWidget {
  const MangaFeatureView({
    super.key,
    required this.data,
    this.extraTabs = const [],
    this.savedCopy,
    this.offlineEdition = false,
  });
  final FeatureData data;

  /// `mobile/19` / `mobile/22` append their tabs here.
  final List<FeatureTab> extraTabs;

  /// `3 H` when the payload's `cache.stale` is true.
  final String? savedCopy;

  /// The page is rendered from the local store (offline with saved chapters).
  final bool offlineEdition;

  @override
  ConsumerState<MangaFeatureView> createState() => _MangaFeatureViewState();
}

class _MangaFeatureViewState extends ConsumerState<MangaFeatureView>
    with SingleTickerProviderStateMixin {
  final _selection = ChapterSelectionController();
  final _commands = FeatureCommands();
  final _scroll = ScrollController();
  late final List<FeatureTab> _tabs;
  late final TabController _tabController;
  double _offset = 0;

  FeatureData get d => widget.data;

  @override
  void initState() {
    super.initState();
    _tabs = [
      FeatureTab(
        id: 'chapters',
        label: 'CHAPTERS',
        count: d.chapters.length,
        panelBuilder: (_) => ChaptersPanel(data: d, selection: _selection, commands: _commands),
      ),
      FeatureTab(id: 'details', label: 'DETAILS', panelBuilder: (_) => DetailsPanel(data: d)),
      ...widget.extraTabs,
    ];
    _tabController = TabController(length: _tabs.length, vsync: this);
    _scroll.addListener(() {
      final o = _scroll.hasClients ? _scroll.offset : 0.0;
      if ((o > 24) != (_offset > 24) || (o > _titleAt) != (_offset > _titleAt)) {
        setState(() => _offset = o);
      } else {
        _offset = o;
      }
    });
    _commands
      ..viewCover = _cover
      ..select = _startSelect
      ..move = () {
        if (d.isFollowed && isOnline(ref)) {
          showRepointSheet(context, d, sourceIsDown: false);
        }
      }
      ..tab = (i) {
        if (i < _tabs.length) _tabController.animateTo(i);
      }
      ..tabBy = (delta) {
        final i = (_tabController.index + delta).clamp(0, _tabs.length - 1);
        _tabController.animateTo(i);
      };
  }

  double get _titleAt {
    final size = MediaQuery.sizeOf(context);
    if (size.width >= 600) return 300;
    return (size.width * 1.25).clamp(0.0, size.height * 0.70) - 96;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scroll.dispose();
    _selection.dispose();
    super.dispose();
  }

  void _startSelect() {
    if (!_selection.isActive) _selection.begin();
  }

  void _cover() => showCoverLightbox(
        context,
        imageUrl:
            '${ref.read(apiBaseUrlProvider)}/sources/${d.sourceId}/series/${Uri.encodeComponent(d.seriesKey)}/cover',
        title: d.title,
        heroTag: d.followed != null
            ? seriesCoverHeroTag(d.followed!.id)
            : 'cover-${d.sourceId}-${d.seriesKey}',
      );

  Future<void> _downloadSelected() async {
    final keys = _selection.selected;
    final chapters = d.chapters.where((c) => keys.contains(c.id)).toList();
    _selection.end();
    feedback(ref, HapticEvent.downloadStart);
    await ref
        .read(downloadQueueControllerProvider.notifier)
        .enqueueChapters(queueRequests(d, chapters));
  }

  void _overflow() => showFeatureOverflow(context, ref, d, onCover: _cover);

  @override
  Widget build(BuildContext context) {
    final t = cineOf(context);
    final statuses =
        ref.watch(seriesChapterDownloadStatusProvider(d.identity)).valueOrNull ?? const {};
    final progress =
        ref.watch(sourceSeriesProgressProvider((sourceId: d.sourceId, seriesId: d.seriesKey)));
    final selectable = [
      for (final c in d.readingOrder)
        (
          key: c.id,
          number: c.number,
          title: c.title,
          isRead: progress[c.id]?.completed ?? false,
          isDownloaded: statuses[c.id]?.state == DownloadChapterState.complete,
        ),
    ];
    final wide = MediaQuery.sizeOf(context).width >= 600;
    final mature = d.followed?.rating == 'mature' &&
        (ref.watch(matureContentProvider).valueOrNull ?? false);
    final topPad = MediaQuery.paddingOf(context).top;
    final scrolled = _offset > 24;
    final showTitle = _offset > _titleAt;

    Widget onArt(IconData icon, String tip, VoidCallback onTap) => Semantics(
          button: true,
          label: tip,
          excludeSemantics: true,
          child: Tooltip(
            message: tip,
            child: InkResponse(
              onTap: onTap,
              radius: 24,
              child: SizedBox(
                width: 48,
                height: 48,
                child: Center(
                  child: Container(
                    width: 40,
                    height: 40,
                    color: scrolled ? Colors.transparent : t.colorOnart,
                    child: Icon(icon, size: 20, color: t.colorInk100),
                  ),
                ),
              ),
            ),
          ),
        );

    final runningHead = Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: EdgeInsets.only(top: topPad, left: 4, right: 4),
        decoration: BoxDecoration(
          color: scrolled ? const Color(0xFF000000) : Colors.transparent,
          border: Border(bottom: BorderSide(color: scrolled ? t.colorRule1 : Colors.transparent)),
        ),
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              onArt(Icons.arrow_back, 'Back', () => featureBack(context)),
              Expanded(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 160),
                  opacity: showTitle ? 1 : 0,
                  child: Text(
                    d.title,
                    key: const Key('running-title'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: t.colorInk60),
                  ),
                ),
              ),
              onArt(Icons.more_horiz, 'More', _overflow),
            ],
          ),
        ),
      ),
    );

    return CineAmbient(
      target: CineAmbientColors.forSeries('${d.sourceId}/${d.seriesKey}'),
      builder: (context, amb) => ListenableBuilder(
        listenable: _selection,
        builder: (context, _) => PopScope(
          canPop: !_selection.isActive,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop &&
                _selection.isActive &&
                defaultTargetPlatform != TargetPlatform.iOS) {
              _selection.end();
            }
          },
          child: FeatureShortcuts(
            commands: _commands,
            child: Scaffold(
              backgroundColor: t.colorPaper0,
              extendBodyBehindAppBar: true,
              bottomNavigationBar: _selection.isActive
                  ? SelectionBar(
                      controller: _selection,
                      chapters: selectable,
                      onDownload: _downloadSelected,
                    )
                  : null,
              body: Stack(
                children: [
                  NestedScrollView(
                    controller: _scroll,
                    headerSliverBuilder: (context, _) => [
                      SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FeatureHero(
                              data: d,
                              onSelect: _startSelect,
                              onCover: _cover,
                              commands: _commands,
                              onOverflow: wide ? _overflow : null,
                            ),
                            if (widget.offlineEdition || widget.savedCopy != null)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                                child: Wrap(spacing: 8, children: [
                                  if (widget.offlineEdition) const FeatureBadge('OFFLINE EDITION'),
                                  if (widget.savedCopy != null)
                                    FeatureBadge('SAVED COPY · ${widget.savedCopy}'),
                                ],),
                              ),
                          ],
                        ),
                      ),
                      SliverOverlapAbsorber(
                        handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
                        sliver: SliverPersistentHeader(
                          pinned: true,
                          delegate: _TabsDelegate(
                            clearance: 56 + topPad,
                            color: t.colorPaper0,
                            rule: t.colorRule1,
                            bar: TabBar(
                              controller: _tabController,
                              indicatorColor: t.colorSpot,
                              labelColor: t.colorInk100,
                              unselectedLabelColor: t.colorInk60,
                              tabs: [
                                for (var i = 0; i < _tabs.length; i++)
                                  Tab(
                                    height: 48,
                                    text: '${_tabs[i].folio(i)} ${_tabs[i].label}'
                                        '${_tabs[i].count != null ? superscript(_tabs[i].count!) : ''}',
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                    body: TabBarView(
                      controller: _tabController,
                      children: [
                        for (final tab in _tabs) Builder(builder: tab.panelBuilder),
                      ],
                    ),
                  ),
                  runningHead,
                  if (mature)
                    Positioned(
                      left: 16,
                      top: topPad + 60,
                      child: RatingCard(descriptors: RatingCard.descriptorsFor(d.series.genres)),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The pinned tab row, pinned under the running head: the box is the head's
/// height plus the row, so the row stops right beneath the head and the
/// absorbed overlap the panels inject is exactly the head plus the row.
class _TabsDelegate extends SliverPersistentHeaderDelegate {
  _TabsDelegate({
    required this.clearance,
    required this.color,
    required this.rule,
    required this.bar,
  });

  final double clearance;
  final Color color, rule;
  final TabBar bar;

  @override
  double get minExtent => 48 + clearance;
  @override
  double get maxExtent => 48 + clearance;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => ColoredBox(
        color: color,
        child: Column(
          children: [
            SizedBox(height: clearance),
            DecoratedBox(
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: rule))),
              child: SizedBox(height: 47, child: bar),
            ),
          ],
        ),
      );

  @override
  bool shouldRebuild(_TabsDelegate old) =>
      old.bar != bar || old.color != color || old.clearance != clearance;
}
