import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/core/keyboard/shortcut_registry.dart';
import 'package:manhwamaniacs/core/time/clock.dart';
import 'package:manhwamaniacs/features/content_mode/content_mode.dart';
import 'package:manhwamaniacs/features/content_mode/content_mode_controller.dart';
import 'package:manhwamaniacs/features/library/models/reading_history_item.dart';
import 'package:manhwamaniacs/features/library/providers/history_pages_provider.dart';
import 'package:manhwamaniacs/features/library/utils/cover_url.dart';
import 'package:manhwamaniacs/features/library/utils/history_continue.dart';
import 'package:manhwamaniacs/features/updates/utils/notification_grouping.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/navigation.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_contents_tabs.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_notice.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/layout/cine_grid.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/toasts.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/history/history_row.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/hub/hub_kit.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/library/library_hub.dart';
import 'package:manhwamaniacs/skins/cinematic/shell/cine_scaffold.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// History, "The log" (cinematic 8.12, ScreenId `history`): what you have been reading, by day, with
/// its time margin; BY SERIES or BY CHAPTER; Continue by Dip; `Load earlier` for the next 50.
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this)..addListener(() => setState(() {}));
  final _mastheadFocus = FocusNode(debugLabel: 'history-masthead');
  final _scroll = ScrollController();
  final List<FocusNode> _nodes = [];
  final Set<int> _faded = {};
  bool _loadingMore = false, _moreFailed = false;

  bool get _bySeries => _tabs.index == 0;

  @override
  void dispose() {
    _tabs.dispose();
    _mastheadFocus.dispose();
    _scroll.dispose();
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  List<FocusNode> _nodesFor(int n) {
    while (_nodes.length < n) {
      _nodes.add(FocusNode(debugLabel: 'log-${_nodes.length}'));
    }
    return _nodes;
  }

  int _focused(int n) {
    for (var i = 0; i < _nodes.length && i < n; i++) {
      if (_nodes[i].hasFocus) return i;
    }
    return -1;
  }

  void _step(int d, int n) {
    if (n == 0) return;
    final cur = _focused(n);
    final to = (cur < 0 ? (d > 0 ? 0 : n - 1) : cur + d).clamp(0, n - 1);
    _nodes[to].requestFocus();
    final ctx = _nodes[to].context;
    if (ctx != null) unawaited(Scrollable.ensureVisible(ctx, duration: hubScroll(context), alignment: 0.3));
  }

  Future<void> _continue(ReadingHistoryItem item) async {
    final go = ref.read(historyContinueProvider);
    final r = await go(item);
    if (!mounted) return;
    if (r.toSeriesPage) {
      unawaited(context.push(Routes.feature(item.sourceId, item.seriesKey)));
      return;
    }
    final target = r.isNovel
        ? ReaderTarget.novel(r.sourceId, r.seriesKey, r.chapterKey!, page: r.page)
        : ReaderTarget.manifest(r.sourceId, r.seriesKey, r.chapterKey!, page: r.page);
    readerPrefetchOf(ref).onPress(target);
    enterReader(context, target, entry: ReaderEntry.dip);
  }

  void _openSeries(ReadingHistoryItem i) => unawaited(context.push(Routes.feature(i.sourceId, i.seriesKey)));

  Future<void> _loadEarlier() async {
    if (_loadingMore) return;
    setState(() {
      _loadingMore = true;
      _moreFailed = false;
    });
    final ok = await ref.read(historyPagesProvider(_bySeries).notifier).loadEarlier();
    if (!mounted) return;
    setState(() {
      _loadingMore = false;
      _moreFailed = !ok;
    });
    if (!ok) ref.read(cineToastsProvider.notifier).error("Couldn't load earlier reading.");
  }

  Future<void> _reload() async {
    ref.invalidate(historyPagesProvider(_bySeries));
    try {
      await ref.read(historyPagesProvider(_bySeries).future);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final async = ref.watch(historyPagesProvider(_bySeries));
    final scope = ref.watch(contentModeScopeProvider);
    final now = ref.watch(clockProvider)();
    final apiBase = ref.watch(apiBaseUrlProvider);
    final grid = CineGrid.of(context);
    final wide = MediaQuery.sizeOf(context).width >= 600;
    final pages = async.valueOrNull;
    final tagged = <(int, ReadingHistoryItem)>[];
    if (pages != null) {
      for (var p = 0; p < pages.length; p++) {
        for (final it in scope.filter(pages[p], (r) => r.sourceId)) {
          tagged.add((p, it));
        }
      }
    }
    final nodes = _nodesFor(tagged.length);
    final hasEarlier = pages != null && nextHistoryOffset(pages) != null;

    final slivers = <Widget>[
      SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.only(left: grid.left, right: grid.right),
          child: CineContentsTabs(controller: _tabs, tabs: const [CineTab(folio: '01', label: 'BY SERIES'), CineTab(folio: '02', label: 'BY CHAPTER')]),
        ),
      ),
    ];
    if (async.isLoading && pages == null) {
      slivers.add(const SliverToBoxAdapter(child: HubGalley(count: 8)));
    } else if (async.hasError && pages == null) {
      slivers.add(SliverToBoxAdapter(
        child: HubErrorNotice(
          error: async.error!,
          offlineHeadline: 'Reading history needs a connection to load.',
          errorHeadline: "History didn't load.",
          onRetry: () => ref.invalidate(historyPagesProvider(_bySeries)),
        ),
      ),);
    } else if (tagged.isEmpty) {
      slivers.add(SliverToBoxAdapter(
        child: HubNoticeBox(
          notice: CineNotice(
            key: const Key('history-empty'),
            tone: CineNoticeTone.empty,
            kicker: 'NOTHING READ YET',
            headline: 'Nothing read yet.',
            deck: 'Open a chapter and it shows up here.',
            primary: CineNoticeAction('Go to library', () => context.go(Routes.library())),
          ),
        ),
      ),);
    } else {
      // Days flatten to date rules and rows; the log is newest first.
      final items = <Object>[];
      String? day;
      for (var i = 0; i < tagged.length; i++) {
        final at = tagged[i].$2.lastReadAt;
        final label = at == null ? 'EARLIER' : dayLabel(at, now);
        if (label != day) {
          items.add(label);
          day = label;
        }
        items.add(i);
      }
      slivers.add(SliverPadding(
        padding: EdgeInsets.only(left: grid.left, right: grid.right),
        sliver: SliverList.builder(
          itemCount: items.length,
          itemBuilder: (context, k) {
            final it = items[k];
            if (it is String) return _DayRule(it);
            final i = it as int;
            final (page, row) = tagged[i];
            final novel = scope.novelsEnabled ? scope.modeOf(row.sourceId) == ContentMode.novel : false;
            Widget w = HistoryRow(
              key: ValueKey('log-${row.id}'),
              item: row,
              coverUrl: historyCoverUrl(apiBase, row.coverUrl),
              novel: novel,
              wide: wide,
              focusNode: nodes[i],
              onContinue: () => _continue(row),
              onOpenSeries: () => _openSeries(row),
            );
            if (page > 0 && !_faded.contains(page)) {
              WidgetsBinding.instance.addPostFrameCallback((_) => _faded.add(page));
              w = _FadeIn(child: w);
            }
            return w;
          },
        ),
      ),);
      if (hasEarlier || _moreFailed) {
        slivers.add(SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(grid.left, c.space4, grid.right, c.space6),
            child: Align(
              alignment: Alignment.centerLeft,
              child: CineButton(key: const Key('history-earlier'), label: 'Load earlier', variant: CineButtonVariant.quiet, loading: _loadingMore, onPressed: () => unawaited(_loadEarlier())),
            ),
          ),
        ),);
      }
    }
    slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 48)));

    ref.listen(historyPagesProvider(_bySeries), (_, __) {});
    return CineScaffold(
      runningTitle: 'History',
      contentModeChip: true,
      firstRunNote: false,
      mastheadFocusNode: _mastheadFocus,
      body: RegisteredShortcuts(
        group: 'History',
        entries: [
          hubKey('History', LogicalKeyboardKey.keyJ, 'Next row', () => _step(1, tagged.length)),
          hubKey('History', LogicalKeyboardKey.keyK, 'Previous row', () => _step(-1, tagged.length)),
          hubKey('History', LogicalKeyboardKey.enter, 'Continue the focused row', () {
            final i = _focused(tagged.length);
            if (i >= 0) unawaited(_continue(tagged[i].$2));
          }, single: false,),
          hubKey('History', LogicalKeyboardKey.keyO, 'Open the focused series', () {
            final i = _focused(tagged.length);
            if (i >= 0) _openSeries(tagged[i].$2);
          }),
          hubKey('History', LogicalKeyboardKey.keyT, 'Toggle BY SERIES and BY CHAPTER', () => _tabs.animateTo(1 - _tabs.index, duration: CineDur.column)),
        ],
        child: LibraryHub(
          tab: HubTab.history,
          masthead: (kicker: 'No. 07 — THE LOG', title: 'History', deck: "What you've been reading, most recent first."),
          slivers: slivers,
          scrollController: _scroll,
          mastheadFocus: _mastheadFocus,
          onRefresh: _reload,
        ),
      ),
    );
  }
}

class _DayRule extends StatelessWidget {
  const _DayRule(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    return Padding(
      padding: EdgeInsets.only(top: c.space6, bottom: c.space2),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Semantics(header: true, child: CineRoleText(label, c.typeKicker, color: c.colorInk60)),
        SizedBox(height: c.space2),
        DecoratedBox(decoration: BoxDecoration(border: Border(top: c.ruleHair)), child: const SizedBox(width: double.infinity)),
      ],),
    );
  }
}

/// Appended rows fade in over 160 ms as one block (a fade under reduced motion as well).
class _FadeIn extends StatelessWidget {
  const _FadeIn({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 160),
        builder: (_, v, child) => Opacity(opacity: v, child: child),
        child: child,
      );
}
