import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/features/downloads/models/chapter_selection.dart';
import 'package:manhwamaniacs/features/downloads/models/download_chapter_state.dart';
import 'package:manhwamaniacs/features/downloads/providers/series_download_status_provider.dart';
import 'package:manhwamaniacs/features/downloads/queue/download_queue_controller.dart';
import 'package:manhwamaniacs/features/sources/providers/source_progress_provider.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/downloads/selection_bar.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/feature_data.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/feature_lightbox.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/feature_states.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/feature_tabs.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/manga/chapters_panel.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/manga/details_panel.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/manga/feature_hero.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/manga/feature_overflow.dart';

/// The manga Feature page: hero or spread, then pinned contents tabs over
/// swipeable CHAPTERS / DETAILS panels.
class MangaFeatureView extends ConsumerStatefulWidget {
  const MangaFeatureView({super.key, required this.data, this.extraTabs = const []});
  final FeatureData data;

  /// `mobile/19` / `mobile/22` append their tabs here.
  final List<FeatureTab> extraTabs;

  @override
  ConsumerState<MangaFeatureView> createState() => _MangaFeatureViewState();
}

class _MangaFeatureViewState extends ConsumerState<MangaFeatureView>
    with SingleTickerProviderStateMixin {
  final _selection = ChapterSelectionController();
  late final List<FeatureTab> _tabs;
  late final TabController _tabController;

  FeatureData get d => widget.data;

  @override
  void initState() {
    super.initState();
    _tabs = [
      FeatureTab(
        id: 'chapters',
        label: 'CHAPTERS',
        count: d.chapters.length,
        panelBuilder: (_) => ChaptersPanel(data: d, selection: _selection),
      ),
      FeatureTab(id: 'details', label: 'DETAILS', panelBuilder: (_) => DetailsPanel(data: d)),
      ...widget.extraTabs,
    ];
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _selection.dispose();
    super.dispose();
  }

  void _cover() => showCoverLightbox(
        context,
        imageUrl:
            '${ref.read(apiBaseUrlProvider)}/sources/${d.sourceId}/series/${Uri.encodeComponent(d.seriesKey)}/cover',
        title: d.title,
      );

  Future<void> _downloadSelected() async {
    final keys = _selection.selected;
    final chapters = d.chapters.where((c) => keys.contains(c.id)).toList();
    _selection.end();
    await ref
        .read(downloadQueueControllerProvider.notifier)
        .enqueueChapters(queueRequests(d, chapters));
  }

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
    return PopScope(
      canPop: !_selection.isActive,
      child: Scaffold(
        backgroundColor: t.colorPaper0,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            tooltip: 'Back',
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.canPop() ? context.pop() : context.go('/'),
          ),
          actions: [
            IconButton(
              tooltip: 'More',
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              icon: const Icon(Icons.more_horiz),
              onPressed: () => showFeatureOverflow(context, ref, d, onCover: _cover),
            ),
          ],
        ),
        bottomNavigationBar: ListenableBuilder(
          listenable: _selection,
          builder: (context, _) => _selection.isActive
              ? SelectionBar(
                  controller: _selection, chapters: selectable, onDownload: _downloadSelected,)
              : const SizedBox.shrink(),
        ),
        body: NestedScrollView(
          headerSliverBuilder: (context, _) => [
            SliverOverlapAbsorber(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
              sliver: MultiSliver2(
                children: [
                  SliverToBoxAdapter(
                    child: FeatureHero(data: d, onSelect: _selection.begin, onCover: _cover),
                  ),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _TabsDelegate(
                      TabBar(
                        controller: _tabController,
                        indicatorColor: t.colorSpot,
                        tabs: [
                          for (var i = 0; i < _tabs.length; i++)
                            Tab(
                              height: 48,
                              text: '${_tabs[i].folio(i)} ${_tabs[i].label}'
                                  '${_tabs[i].count != null ? ' ${_tabs[i].count}' : ''}',
                            ),
                        ],
                      ),
                      t.colorPaper0,
                    ),
                  ),
                ],
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
      ),
    );
  }
}

/// Two adjacent slivers as one (the overlap absorber takes a single sliver).
class MultiSliver2 extends StatelessWidget {
  const MultiSliver2({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => SliverMainAxisGroup(slivers: children);
}

class _TabsDelegate extends SliverPersistentHeaderDelegate {
  _TabsDelegate(this.bar, this.color);
  final TabBar bar;
  final Color color;

  @override
  double get minExtent => 48;
  @override
  double get maxExtent => 48;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) =>
      ColoredBox(color: color, child: bar);

  @override
  bool shouldRebuild(_TabsDelegate old) => old.bar != bar || old.color != color;
}
