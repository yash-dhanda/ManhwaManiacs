import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/core/time/clock.dart';
import 'package:manhwamaniacs/features/content_mode/content_mode_controller.dart';
import 'package:manhwamaniacs/features/downloads/models/download_chapter_state.dart';
import 'package:manhwamaniacs/features/downloads/providers/downloaded_series_provider.dart';
import 'package:manhwamaniacs/features/downloads/providers/mature_gate_provider.dart';
import 'package:manhwamaniacs/features/library/models/followed_series.dart';
import 'package:manhwamaniacs/features/library/models/shelf_query.dart';
import 'package:manhwamaniacs/features/library/providers/shelf_provider.dart';
import 'package:manhwamaniacs/features/library/providers/shelf_query_provider.dart';
import 'package:manhwamaniacs/features/library/providers/tags_provider.dart';
import 'package:manhwamaniacs/features/library/utils/bulk_runner.dart';
import 'package:manhwamaniacs/features/library/utils/cover_url.dart';
import 'package:manhwamaniacs/features/library/utils/shelf_counts.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/back_order.dart';
import 'package:manhwamaniacs/skins/cinematic/icons/icon_roles.g.dart';
import 'package:manhwamaniacs/skins/cinematic/navigation.dart';
import 'package:manhwamaniacs/skins/cinematic/parts/add_to_shelf_sheet.dart';
import 'package:manhwamaniacs/skins/cinematic/parts/tag_sheet.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_confirm_dialog.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_menu.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_select_mode_bar.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/layout/cine_grid.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/library/continue_cuttings.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/library/filters_sheet.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/library/library_hub.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/library/library_shortcuts.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/library/shelf_actions.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/library/shelf_quick_look.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/library/shelf_states.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/library/shelf_toolbar.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/library/shelf_wall.dart';
import 'package:manhwamaniacs/skins/cinematic/shell/cine_scaffold.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// The Library shelf at `/library` and `/library/browse` (cinematic 8.9, ScreenId `library`): the
/// hub frame, the toolbar, Continue cuttings and the wall in WALL, COMPACT and LIST, manual order,
/// select mode with every bulk action, the book list for novels, and every state. Filters and
/// sorts run on the server over the whole library.
class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key, this.params = const {}, this.browse = false});

  /// The route's query parameters (`?status&sort&fav&view&q&select`, `new`, `tags`).
  final Map<String, String> params;

  /// `/library/browse`: on phones it opens the Filters sheet once on mount.
  final bool browse;

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> with SingleTickerProviderStateMixin {
  final _scroll = ScrollController();
  final _search = TextEditingController();
  final _searchFocus = FocusNode(debugLabel: 'shelf-search');
  final _mastheadFocus = FocusNode(debugLabel: 'library-masthead');
  final _tracker = ShelfSetTracker();
  final _commands = LibraryCommands();
  final List<FocusNode> _nodes = [];
  late final AnimationController _block;
  Timer? _debounce;

  bool _selectMode = false;
  bool _searchOpen = false;
  bool _queryChanged = false;
  bool _browseSheetShown = false;
  final Set<int> _selected = {};
  int? _anchor;
  CineSelectRun? _run;
  String? _result;
  Future<void> Function()? _undo;
  BulkCancel? _cancel;
  List<FollowedSeries> _rows = const [];

  @override
  void initState() {
    super.initState();
    _block = AnimationController(vsync: this, duration: CineDur.beat, value: 1);
    Future.microtask(_applyRoute);
    _wireCommands();
    final q = ref.read(shelfQueryProvider).q;
    if (q.isNotEmpty) {
      _search.text = q;
      _searchOpen = true;
    }
  }

  @override
  void didUpdateWidget(LibraryScreen old) {
    super.didUpdateWidget(old);
    if (old.params != widget.params) Future.microtask(_applyRoute);
  }

  void _applyRoute() {
    if (!mounted) return;
    final r = ShelfQuery.fromRoute(widget.params, base: ref.read(shelfQueryProvider));
    ref.read(shelfQueryProvider.notifier).applyRoute(widget.params);
    if (r.query.q.isNotEmpty && _search.text != r.query.q) {
      _search.text = r.query.q;
      _searchOpen = true;
    }
    if (r.openSelectMode) setState(() => _selectMode = true);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scroll.dispose();
    _search.dispose();
    _searchFocus.dispose();
    _mastheadFocus.dispose();
    _block.dispose();
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  // ---- helpers -------------------------------------------------------------------------------

  ShelfQueryNotifier get _q => ref.read(shelfQueryProvider.notifier);
  ShelfActions get _actions => ShelfActions(context, ref);

  List<FocusNode> _ensureNodes(int n) {
    while (_nodes.length < n) {
      _nodes.add(FocusNode(debugLabel: 'shelf-${_nodes.length}'));
    }
    return _nodes;
  }

  String? _cover(FollowedSeries s) => followedSeriesCoverUrl(ref.read(apiBaseUrlProvider), s);

  int _focused() {
    for (var i = 0; i < _nodes.length && i < _rows.length; i++) {
      if (_nodes[i].hasFocus) return i;
    }
    return -1;
  }

  int get _perRow {
    final q = ref.read(shelfQueryProvider);
    if (ref.read(contentModeScopeProvider).isNovel || q.density == ShelfDensity.list) return 1;
    return ShelfGeometry.perRowFor(MediaQuery.sizeOf(context).width, q.density);
  }

  void _focusIndex(int i) {
    if (i < 0 || i >= _rows.length) return;
    _ensureNodes(_rows.length);
    final node = _nodes[i];
    void go() {
      final ctx = node.context;
      if (ctx != null) {
        node.requestFocus();
        unawaited(Scrollable.ensureVisible(ctx, duration: CineDur.line, alignment: 0.3));
      }
    }

    if (node.context != null) {
      go();
    } else {
      // Not built yet (a lazy wall): scroll toward it, then focus it once it exists.
      final cur = _focused();
      final rows = ((i - (cur < 0 ? 0 : cur)) / _perRow).round();
      if (_scroll.hasClients) _scroll.jumpTo((_scroll.offset + rows * 260).clamp(0.0, _scroll.position.maxScrollExtent));
      WidgetsBinding.instance.addPostFrameCallback((_) => go());
    }
  }

  void _wireCommands() {
    final c = _commands;
    c.search = () {
      setState(() => _searchOpen = true);
      WidgetsBinding.instance.addPostFrameCallback((_) => _searchFocus.requestFocus());
    };
    c.move = (int dx, int dy) {
      final cur = _focused();
      final n = _rows.length;
      if (n == 0) return;
      if (cur < 0) {
        _focusIndex(0);
        return;
      }
      final per = _perRow;
      if (per == 1 && dx != 0) return;
      _focusIndex((cur + dx + dy * per).clamp(0, n - 1));
    };
    c.home = () => _focusIndex(0);
    c.end = () => _focusIndex(_rows.length - 1);
    c.selectMode = () => _selectMode ? _exitSelect() : _enterSelect();
    c.favouriteFocused = () {
      final cur = _focused();
      if (cur >= 0 && !_offline) unawaited(_actions.favourite(_rows[cur]));
    };
    c.status = (int i) => _q.patch((q) => q.copyWith(status: ShelfStatus.values[i]));
    c.cycleSort = () => _q.patch((q) => q.copyWith(sort: ShelfSort.values[(q.sort.index + 1) % ShelfSort.values.length]));
    c.cycleDensity = () {
      if (!ref.read(contentModeScopeProvider).isNovel) _q.patch((q) => q.copyWith(density: ShelfDensity.values[(q.density.index + 1) % 3]));
    };
    c.selectAll = () {
      if (_selectMode) setState(() => _selected.addAll([for (final r in _rows) r.id]));
    };
    c.reprint = () => unawaited(_reprint());
    c.moveItem = (int dx, int dy) {
      final q = ref.read(shelfQueryProvider);
      final cur = _focused();
      if (!q.canReorder || cur < 0 || _offline) return;
      final to = cur + dx + dy * _perRow;
      if (to < 0 || to >= _rows.length || to == cur) return;
      _moveTo(cur, to);
      WidgetsBinding.instance.addPostFrameCallback((_) => _focusIndex(to));
    };
  }

  bool get _offline => ref.read(shelfProvider).valueOrNull?.offline ?? false;

  Future<void> _reprint() async {
    ref
      ..invalidate(shelfProvider)
      ..invalidate(shelfCountsProvider)
      ..invalidate(shelfContinueProvider);
    try {
      await ref.read(shelfProvider.future);
    } catch (_) {}
  }

  void _moveTo(int from, int to) {
    final s = _rows[from];
    unawaited(_actions.reorderRows(_rows, from, to).then((_) {
      if (mounted) SemanticsService.sendAnnouncement(View.of(context), '${s.title} moved to position ${to + 1} of ${_rows.length}', TextDirection.ltr);
    }),);
  }

  // ---- select mode ---------------------------------------------------------------------------

  void _enterSelect() => setState(() => _selectMode = true);

  void _exitSelect() => setState(() {
        _selectMode = false;
        _selected.clear();
        _anchor = null;
        _run = null;
        _result = null;
        _undo = null;
      });

  void _toggle(FollowedSeries s, int i, {bool range = false}) {
    setState(() {
      if (!_selectMode) _selectMode = true;
      if (range && _anchor != null) {
        final a = _anchor!;
        for (var k = a < i ? a : i; k <= (a < i ? i : a); k++) {
          if (k < _rows.length) _selected.add(_rows[k].id);
        }
      } else if (!_selected.remove(s.id)) {
        _selected.add(s.id);
      }
      _anchor = i;
    });
  }

  List<FollowedSeries> get _picked => [for (final r in _rows) if (_selected.contains(r.id)) r];

  Future<void> _bulk(Future<BulkResult> Function(List<FollowedSeries> rows, BulkCancel cancel, void Function(int, int) progress) f) async {
    final rows = _picked;
    if (rows.isEmpty) return;
    final cancel = BulkCancel();
    setState(() {
      _cancel = cancel;
      _run = (done: 0, total: rows.length, failed: 0);
      _result = null;
      _undo = null;
    });
    final r = await f(rows, cancel, (d, fl) {
      if (mounted) setState(() => _run = (done: d, total: rows.length, failed: fl));
    });
    if (!mounted) return;
    setState(() {
      _run = null;
      _result = r.message;
      _undo = r.undo;
      _selected.clear();
    });
  }

  Future<void> _unfollow() async {
    final n = _selected.length;
    final ok = await showCineConfirm(
      context,
      title: 'Unfollow $n series?',
      body: 'Your reading progress is kept. You can follow them again from any series page.',
      confirmLabel: 'Unfollow $n',
      destructive: true,
      filled: true,
    );
    if (ok && mounted) await _bulk((rows, c, p) => _actions.unfollow(rows, cancel: c, onProgress: p));
  }

  Widget _selectBar() {
    final off = _offline;
    VoidCallback? on(VoidCallback f) => off ? null : f;
    return CineSelectModeBar(
      selected: _selected.length,
      total: _rows.length,
      onDone: _exitSelect,
      onSelectAll: () => setState(() => _selected.addAll([for (final r in _rows) r.id])),
      run: _run,
      onStop: () => _cancel?.stop(),
      result: _result,
      onDismissResult: () => setState(() {
        _result = null;
        _undo = null;
      }),
      onUndo: _undo == null
          ? null
          : () async {
              final u = _undo!;
              setState(() {
                _undo = null;
                _result = null;
              });
              await u();
            },
      actions: [
        CineSelectAction('Favourite', CineIconRole.favourite, on(() => unawaited(_bulk((r, c, p) => _actions.setFavourite(r, true, cancel: c, onProgress: p))))),
        CineSelectAction('Unfavourite', CineIconRole.favourite, on(() => unawaited(_bulk((r, c, p) => _actions.setFavourite(r, false, cancel: c, onProgress: p))))),
        CineSelectAction('Mark read', CineIconRole.select, on(() => unawaited(_bulk((r, c, p) => _actions.markRead(r, cancel: c, onProgress: p))))),
        CineSelectAction('Mark unread', CineIconRole.select, on(() => unawaited(_bulk((r, c, p) => _actions.markUnread(r, cancel: c, onProgress: p))))),
        CineSelectAction('Set status', CineIconRole.edit, on(() => unawaited(showStatusSheet(context, title: '${_selected.length} series', onPick: (v) => unawaited(_bulk((r, c, p) => _actions.setStatusAll(r, v, cancel: c, onProgress: p))))))),
        CineSelectAction('Add to collection', CineIconRole.collections, on(() => unawaited(showAddSeriesToShelfSheet(context, series: _picked)))),
        CineSelectAction('Download next 5', CineIconRole.download, on(() => unawaited(_bulk((r, c, p) => _actions.downloadNext(r, cancel: c, onProgress: p))))),
        CineSelectAction('Unfollow', CineIconRole.following, on(() => unawaited(_unfollow())), destructive: true),
      ],
    );
  }

  // ---- build ---------------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final q = ref.watch(shelfQueryProvider);
    final shelf = ref.watch(shelfProvider);
    final counts = ref.watch(shelfCountsProvider).valueOrNull;
    final scope = ref.watch(contentModeScopeProvider);
    final tags = ref.watch(tagsProvider).valueOrNull ?? const [];
    final gateOpen = ref.watch(matureGateOpenProvider);
    final saved = ref.watch(downloadedSeriesProvider).valueOrNull ?? const [];
    final now = ref.watch(clockProvider)();
    final novels = scope.isNovel;

    ref.listen(shelfQueryProvider, (prev, next) {
      if (prev != null && prev != next) {
        _tracker.newEpoch();
        _queryChanged = true;
      }
    });
    ref.listen(shelfProvider, (prev, next) {
      if (!next.isLoading && next.hasValue && prev?.valueOrNull != null) {
        if (_queryChanged) {
          _queryChanged = false;
        } else {
          _block.forward(from: 0);
        }
      }
      if (!next.isLoading) _queryChanged = false;
    });

    final data = shelf.valueOrNull;
    _rows = data?.rows ?? const [];
    _ensureNodes(_rows.length);
    final offline = data?.offline ?? false;
    final grid = CineGrid.of(context);
    final savedKeys = {
      for (final g in saved)
        if (g.chapters.any((c) => c.state == DownloadChapterState.complete)) '${g.sourceId} ${g.seriesKey}',
    };
    final follows = {for (final r in _rows) (r.sourceId, r.seriesKey): r};

    final env = ShelfEnv(
      query: q,
      rows: _rows,
      novels: novels,
      selectMode: _selectMode,
      selected: _selected,
      gateOpen: gateOpen,
      savedKeys: savedKeys,
      offline: offline,
      coverOf: _cover,
      now: now,
      tracker: _tracker,
      nodes: _nodes,
      open: (s) => openFollowed(context, s),
      quickLook: (s, i) => unawaited(openShelfQuickLook(
        context,
        ref,
        s,
        coverUrl: _cover(s),
        actions: _actions,
        offline: offline,
        moveIndex: env0(q, offline, _selectMode) ? i : null,
        moveCount: _rows.length,
        onMove: _moveTo,
      ),),
      toggleSelect: _toggle,
      favourite: (s) => unawaited(_actions.favourite(s)),
      notify: (s) => unawaited(_actions.notify(s)),
      move: _moveTo,
    );

    final Widget content;
    final slivers = <Widget>[
      SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.fromLTRB(grid.left, 0, grid.right, context.cine.space2),
          child: ShelfToolbar(
            query: q,
            counts: counts,
            tags: tags,
            novels: novels,
            offline: offline,
            searchOpen: _searchOpen,
            searchController: _search,
            searchFocus: _searchFocus,
            onQuery: (next) => _q.set(next),
            onSearchChanged: _onSearchChanged,
            onSearchSubmit: _searchNow,
            onToggleSearch: () {
              setState(() => _searchOpen = !_searchOpen);
              if (!_searchOpen) {
                _search.clear();
                _searchNow('');
              }
            },
            onSelect: _enterSelect,
            onFilters: () => unawaited(showFiltersSheet(context, novels: novels)),
            onManageTags: () => unawaited(showTagSheet(context)),
          ),
        ),
      ),
      if (offline) SliverToBoxAdapter(child: ShelfOfflineBanner(onDownloads: () => goSection(context, 3))),
      if (data != null && !offline && data.total > 200) SliverToBoxAdapter(child: ShelfOverflowNote(total: data.total)),
      if (data != null && !offline && !q.filtering)
        SliverToBoxAdapter(child: ShelfContinueSection(follows: follows, now: now)),
      if (shelf.hasError && data != null) SliverToBoxAdapter(child: ShelfPageError(onRetry: _reprint)),
    ];

    if (data == null && shelf.isLoading) {
      slivers.add(SliverToBoxAdapter(child: ShelfGalley(density: q.density, novels: novels)));
    } else if (data == null) {
      slivers.add(SliverToBoxAdapter(child: ShelfError(onRetry: _reprint)));
    } else if (_rows.isEmpty) {
      slivers.add(SliverToBoxAdapter(
        child: offline
            ? ShelfOfflineEmpty(onDownloads: () => goSection(context, 3))
            : q.q.trim().isNotEmpty
                ? ShelfSearchEmpty(
                    onSearchAll: () => context.go(Routes.discover({'q': q.q.trim()})),
                    onClearSearch: () {
                      _search.clear();
                      _searchNow('');
                    },
                  )
                : q.filtering
                    ? ShelfFilteredEmpty(onClear: () => _q.set(q.cleared()))
                    : ShelfEmptyNotice(novels: novels, onFind: () => goSection(context, 2)),
      ),);
    } else {
      slivers.add(SliverFadeTransition(opacity: _block, sliver: ShelfWall(env: env)));
    }

    final masthead = (
      kicker: 'No. 02 — YOUR SHELF',
      title: 'Library',
      deck: counts == null ? '' : shelfDeck(counts, novels: novels),
    );

    // Phones: `/library/browse` opens the Filters sheet once on mount; the branch keeps this
    // State alive, so going back never reopens it.
    if (widget.browse && !_browseSheetShown && MediaQuery.sizeOf(context).width < 768) {
      _browseSheetShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(showFiltersSheet(context, novels: novels));
      });
    }

    content = LibraryHub(
      tab: HubTab.shelf,
      masthead: masthead,
      slivers: slivers,
      scrollController: _scroll,
      mastheadFocus: _mastheadFocus,
      onRefresh: _reprint,
      overlay: _selectMode ? _selectBar() : null,
    );

    return CineModalBack(
      priority: CineBackPriority.selectMode,
      active: _selectMode,
      onBack: _exitSelect,
      child: CineScaffold(
        runningTitle: 'Library',
        contentModeChip: true,
        firstRunNote: false,
        mastheadFocusNode: _mastheadFocus,
        trailing: [
          CineHeadAction(role: CineIconRole.overflow, label: 'More', onPressed: _overflow),
        ],
        body: LibraryShortcuts(commands: _commands, child: content),
      ),
    );
  }

  bool env0(ShelfQuery q, bool offline, bool selecting) => q.canReorder && !offline && !selecting;

  void _overflow() {
    final w = MediaQuery.sizeOf(context).width;
    unawaited(showCineMenu<String>(
      context,
      anchor: Rect.fromLTWH(w - 56, MediaQuery.paddingOf(context).top, 48, 48),
      entries: [CineMenuEntry<String>(label: 'Refresh', onSelected: () => unawaited(_reprint()))],
    ),);
  }

  void _onSearchChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () => _searchNow(v));
  }

  void _searchNow(String v) {
    _debounce?.cancel();
    if (!mounted) return;
    if (v.trim() != ref.read(shelfQueryProvider).q) _q.set(ref.read(shelfQueryProvider).copyWith(q: v.trim()));
  }
}
