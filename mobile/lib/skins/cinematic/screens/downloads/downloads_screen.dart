import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/features/auth/providers/session_offline_provider.dart';
import 'package:manhwamaniacs/features/downloads/models/download_chapter_state.dart';
import 'package:manhwamaniacs/features/downloads/models/downloaded_series_group.dart';
import 'package:manhwamaniacs/features/downloads/providers/active_download_queue_provider.dart';
import 'package:manhwamaniacs/features/downloads/providers/downloaded_series_provider.dart';
import 'package:manhwamaniacs/features/downloads/queue/download_queue_controller.dart';
import 'package:manhwamaniacs/features/downloads/utils/pending_removals.dart';
import 'package:manhwamaniacs/features/library/providers/device_online_provider.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/feedback.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_banner_strip.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_contents_tabs.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_masthead.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_notice.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_progress.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/dialogue/scan/dialogue_scan_block.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/downloads/activity_block.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/downloads/downloads_copy.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/downloads/downloads_empty.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/downloads/downloads_keys.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/downloads/narration_block.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/downloads/saved_library.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/downloads/storage_meter.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/downloads/storage_panel.dart';
import 'package:manhwamaniacs/skins/cinematic/shell/cine_scaffold.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// Downloads, "The offline edition" (`/downloads`, cinematic 8.23): the storage meter, Activity,
/// the saved library by series, and a STORAGE tab (`?tab=storage`). `?view=queue` (the thumb
/// index long-press) opens with the queue expanded.
class DownloadsScreen extends ConsumerStatefulWidget {
  const DownloadsScreen({super.key, this.tab, this.view});
  final String? tab;
  final String? view;

  @override
  ConsumerState<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends ConsumerState<DownloadsScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final Map<String, FocusNode> _blockNodes = {};
  List<String> _order = const [];
  Map<int, DownloadChapterState> _seen = const {};
  int _seenUnfinished = 0;
  int _written = -1;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this, initialIndex: widget.tab == 'storage' ? 1 : 0)..addListener(_onTab);
  }

  @override
  void didUpdateWidget(DownloadsScreen old) {
    super.didUpdateWidget(old);
    final want = widget.tab == 'storage' ? 1 : 0;
    if (want != _tabs.index) _tabs.animateTo(want);
  }

  @override
  void dispose() {
    _tabs
      ..removeListener(_onTab)
      ..dispose();
    for (final n in _blockNodes.values) {
      n.dispose();
    }
    super.dispose();
  }

  /// The tab is the `?tab=storage` query, written on the same location.
  void _onTab() {
    if (_tabs.indexIsChanging) return;
    final i = _tabs.index;
    if (i == _written) return;
    _written = i;
    final want = widget.tab == 'storage' ? 1 : 0;
    if (want == i) return;
    final router = GoRouter.maybeOf(context);
    router?.go(Routes.downloads({if (i == 1) 'tab': 'storage', if (widget.view != null) 'view': widget.view}));
  }

  FocusNode _node(String key) => _blockNodes.putIfAbsent(key, () => FocusNode(debugLabel: 'series-$key'));

  void _walk(int delta) {
    if (_order.isEmpty) return;
    final at = _order.indexWhere((k) => _blockNodes[k]?.hasFocus ?? false);
    final next = at < 0 ? (delta > 0 ? 0 : _order.length - 1) : (at + delta).clamp(0, _order.length - 1);
    _blockNodes[_order[next]]?.requestFocus();
  }

  void _togglePause() {
    final q = ref.read(downloadQueueControllerProvider);
    final ctl = ref.read(downloadQueueControllerProvider.notifier);
    if (q.pauseReason == DownloadQueuePauseReason.userPaused) {
      ctl.resume();
    } else {
      ctl.pause();
    }
  }

  void _toStorage() {
    if (_tabs.index != 1) _tabs.animateTo(1);
  }

  /// download.start when the queue accepts more, download.done / download.fail as chapters land.
  void _watchTransitions(List<DownloadedSeriesGroup> groups) {
    final now = {for (final g in groups) for (final c in g.chapters) c.rowId: c.state};
    var done = false, fail = false;
    var unfinished = 0;
    for (final e in now.entries) {
      final was = _seen[e.key];
      if (e.value == DownloadChapterState.queued || e.value == DownloadChapterState.downloading) unfinished++;
      if (was == null) continue;
      if (e.value == DownloadChapterState.complete && was != DownloadChapterState.complete) done = true;
      if (e.value == DownloadChapterState.failed && was != DownloadChapterState.failed) fail = true;
    }
    final started = _seen.isNotEmpty || _seenUnfinished > 0 ? unfinished > _seenUnfinished : false;
    _seen = now;
    _seenUnfinished = unfinished;
    if (done) cineFeedback(context, HapticEvent.downloadDone, sound: SoundEvent.downloadDone);
    if (fail) cineFeedback(context, HapticEvent.downloadFail, sound: SoundEvent.downloadFail);
    if (started && !done && !fail) cineFeedback(context, HapticEvent.downloadStart);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final profile = ref.watch(activeProfileProvider);
    final offline = ref.watch(sessionOfflineProvider) || !(ref.watch(deviceOnlineProvider).valueOrNull ?? true);
    final shelf = ref.watch(downloadedShelfProvider);
    final queue = ref.watch(activeDownloadQueueProvider).valueOrNull ?? const [];
    final pending = ref.watch(pendingRemovalKeysProvider).valueOrNull ?? const <String>{};
    ref.listen(downloadedSeriesProvider, (prev, next) {
      final v = next.valueOrNull;
      if (v != null) _watchTransitions(v);
    });
    _order = [for (final g in shelf.valueOrNull ?? const <DownloadedSeriesGroup>[]) SavedLibrary.keyOf(g)];
    final wide = MediaQuery.sizeOf(context).width >= 600;
    final side = wide ? c.space8 : c.space4;
    final noun = deviceNounOf(context);

    Widget masthead(double top) => Padding(
          padding: EdgeInsets.fromLTRB(side, top + c.space6, side, 0),
          child: CineMasthead(
            kicker: 'No. 05 — ON THIS DEVICE',
            title: 'Downloads',
            deck: profile == null ? null : 'Saved for ${profile.name} · reads with no connection',
            id: 'downloads',
          ),
        );

    // The keys wrap the whole scaffold: route focus lands on the running head's title, which sits
    // beside the body, so the bindings must be above both.
    Widget scaffold(Widget body) => DownloadsKeys(
          onNext: () => _walk(1),
          onPrevious: () => _walk(-1),
          onTogglePause: _togglePause,
          child: CineScaffold(contentModeChip: true, tabletLayout: true, firstRunNote: false, body: body),
        );

    if (profile == null) {
      return scaffold(
        Builder(
          builder: (context) => SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                masthead(CineScaffoldScope.topExtentOf(context)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: side),
                  child: CineNotice(
                    tone: CineNoticeTone.empty,
                    kicker: 'NO PROFILE',
                    headline: 'Choose a profile to see its downloads.',
                    primary: CineNoticeAction(
                      'Choose a profile',
                      () => unawaited(context.push<void>(Routes.profiles(), extra: const <String, String>{'mode': 'switch', 'transition': 'dip'})),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    Widget saved() {
      final groups = shelf.valueOrNull;
      Widget state;
      if (shelf.isLoading && groups == null) {
        state = Padding(
          padding: EdgeInsets.symmetric(vertical: c.space8),
          child: Row(
            children: [
              const CineLeaderDial(size: 24),
              SizedBox(width: c.space3),
              CineRoleText("Checking what's stored…", c.typeCaption, color: c.colorInk60),
            ],
          ),
        );
      } else if (shelf.hasError && groups == null) {
        state = CineNotice(
          tone: CineNoticeTone.error,
          kicker: 'CORRECTION',
          headline: "Couldn't read downloads.",
          primary: CineNoticeAction('Try again', () => ref.invalidate(downloadedSeriesProvider)),
        );
      } else if (groups!.isEmpty && queue.isEmpty) {
        state = const DownloadsEmpty();
      } else {
        state = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SavedLibrary(groups: groups, pendingKeys: pending, nodeFor: _node, noun: noun),
            SizedBox(height: c.space6),
            CineRoleText(kSavedNote, c.typeCaption, color: c.colorInk60),
          ],
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DownloadsStorageMeter(onTap: _toStorage),
          SizedBox(height: c.space6),
          ActivityBlock(initiallyExpanded: widget.view == 'queue', onStorageSettings: _toStorage),
          const DialogueScanBlock(),
          const NarrationBlock(),
          state,
        ],
      );
    }

    // `all` keeps the provider alive while the pager swaps tabs.

    Widget page(Widget child) => Builder(
          builder: (ctx) => CustomScrollView(
            slivers: [
              SliverOverlapInjector(handle: NestedScrollView.sliverOverlapAbsorberHandleFor(ctx)),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(side, c.space4, side, c.space12),
                sliver: SliverToBoxAdapter(child: child),
              ),
            ],
          ),
        );

    return scaffold(
      Builder(
        builder: (context) => NestedScrollView(
          headerSliverBuilder: (ctx, _) => [
            if (offline)
              const SliverToBoxAdapter(
                child: CineBannerStrip(
                  kicker: 'OFFLINE EDITION',
                  line: "You're offline. Only saved chapters open.",
                  tone: CineBannerTone.plain,
                ),
              ),
            SliverToBoxAdapter(child: masthead(offline ? 0 : CineScaffoldScope.topExtentOf(context))),
            SliverOverlapAbsorber(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(ctx),
              sliver: SliverPersistentHeader(
                pinned: true,
                delegate: _TabsHeader(
                  child: ColoredBox(
                    color: c.colorPaper0,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: side),
                      child: CineContentsTabs(
                        controller: _tabs,
                        tabs: const [CineTab(folio: '01', label: 'SAVED'), CineTab(folio: '02', label: 'STORAGE')],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
          body: TabBarView(
            controller: _tabs,
            children: [
              page(saved()),
              page(const StoragePanel()),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabsHeader extends SliverPersistentHeaderDelegate {
  const _TabsHeader({required this.child});
  final Widget child;

  @override
  double get minExtent => 48;
  @override
  double get maxExtent => 48;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => child;

  @override
  bool shouldRebuild(_TabsHeader old) => true;
}
