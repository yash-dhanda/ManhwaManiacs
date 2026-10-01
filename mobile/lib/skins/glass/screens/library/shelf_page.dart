import 'dart:async';

import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/features/content_mode/content_mode_controller.dart' show contentModeScopeProvider;
import 'package:manhwamaniacs/features/downloads/models/download_chapter_state.dart';
import 'package:manhwamaniacs/features/downloads/providers/downloaded_series_provider.dart';
import 'package:manhwamaniacs/features/downloads/providers/mature_gate_provider.dart';
import 'package:manhwamaniacs/features/library/models/followed_series.dart';
import 'package:manhwamaniacs/features/library/models/shelf_query.dart';
import 'package:manhwamaniacs/features/library/providers/glass_density_provider.dart';
import 'package:manhwamaniacs/features/library/providers/shelf_provider.dart';
import 'package:manhwamaniacs/features/library/providers/shelf_query_provider.dart';
import 'package:manhwamaniacs/features/library/utils/glass_density.dart' show GlassDensityWide;
import 'package:manhwamaniacs/features/library/utils/shelf_counts.dart' show ShelfCounts;
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/glass/ambient_field.dart';
import 'package:manhwamaniacs/skins/glass/haptics.dart';
import 'package:manhwamaniacs/skins/glass/icons/icon_roles.g.dart';
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/menu.dart';
import 'package:manhwamaniacs/skins/glass/primitives/pull_to_refresh.dart';
import 'package:manhwamaniacs/skins/glass/primitives/select/assist_chips.dart';
import 'package:manhwamaniacs/skins/glass/primitives/select/select_mode.dart';
import 'package:manhwamaniacs/skins/glass/primitives/select/selectable_group.dart';
import 'package:manhwamaniacs/skins/glass/primitives/skeleton.dart';
import 'package:manhwamaniacs/skins/glass/primitives/states/lens_glyphs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/states/object_lens.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/home_common.dart' show paletteOf;
import 'package:manhwamaniacs/skins/glass/screens/library/book_shelf.dart';
import 'package:manhwamaniacs/skins/glass/screens/library/bulk_toolbar.dart';
import 'package:manhwamaniacs/skins/glass/screens/library/continue_rail.dart';
import 'package:manhwamaniacs/skins/glass/screens/library/density_pinch.dart';
import 'package:manhwamaniacs/skins/glass/screens/library/flip_grid.dart';
import 'package:manhwamaniacs/skins/glass/screens/library/library_common.dart';
import 'package:manhwamaniacs/skins/glass/screens/library/library_keys.dart';
import 'package:manhwamaniacs/skins/glass/screens/library/library_section.dart';
import 'package:manhwamaniacs/skins/glass/screens/library/shelf_actions.dart';
import 'package:manhwamaniacs/skins/glass/screens/library/shelf_grid.dart';
import 'package:manhwamaniacs/skins/glass/screens/library/shelf_toolbar.dart';
import 'package:manhwamaniacs/skins/glass/shell/glass_scaffold.dart' show GlassBarAction;
import 'package:manhwamaniacs/skins/glass/shell/global_keys.dart' show registerSearchFocus, useGlassRefresh;
import 'package:manhwamaniacs/skins/skins.dart';

/// The Library shelf and Browse all (glass 8.17): the Continue rail, the pinned toolbar, the grid with pinch density, manual order,
/// select mode and its bulk toolbar, and every state.
class GlassShelfPage extends ConsumerStatefulWidget {
  const GlassShelfPage({super.key, this.browseAll = false});

  /// `/library/browse`: the toolbar is expanded and every filter is written to the location.
  final bool browseAll;

  @override
  ConsumerState<GlassShelfPage> createState() => _GlassShelfPageState();
}

class _GlassShelfPageState extends ConsumerState<GlassShelfPage> {
  final GlassSelectModeController<int> _select = GlassSelectModeController<int>();
  final FlipRegistry _flip = FlipRegistry();
  final ShelfWave _wave = ShelfWave();
  final ValueNotifier<PinchState?> _live = ValueNotifier(null);
  final GlobalKey _toolbarKey = GlobalKey();
  final ValueNotifier<int?> _focused = ValueNotifier(null);
  final ScrollController _scroll = ScrollController();
  final TextEditingController _search = TextEditingController();
  final FocusNode _searchFocus = FocusNode(debugLabel: 'shelf-search');
  final FocusScopeNode _gridScope = FocusScopeNode(debugLabel: 'shelf-grid');
  final GlassPullToRefreshController _pull = GlassPullToRefreshController();
  Timer? _debounce;
  Timer? _ambientTimer;
  bool _pinching = false;
  bool _firstPaint = true;
  List<FollowedSeries> _rows = const [];
  VoidCallback? _offSearch, _offRefresh, _offBridge;

  @override
  void initState() {
    super.initState();
    _offSearch = registerSearchFocus(_searchFocus);
    _offRefresh = useGlassRefresh(() => unawaited(_pull.refresh()));
    _scroll.addListener(_onScroll);
    _select.addListener(_syncLock);
    Future.microtask(() {
      if (!mounted) return;
      _offBridge = bridgeLibrarySelection(ref, _select);
      final q = _routeParams();
      if (q.isNotEmpty) ref.read(shelfQueryProvider.notifier).applyRoute(q);
      final cur = ref.read(shelfQueryProvider).q;
      if (cur.isNotEmpty) _search.text = cur;
      if (q['select'] == '1') _select.enter();
    });
  }

  Map<String, String> _routeParams() {
    try {
      return GoRouterState.of(context).uri.queryParameters;
    } catch (_) {
      return const {};
    }
  }

  /// While select mode paints ranges or a pinch runs, the shelf owns horizontal drags and the hub's pager stands still.
  void _syncLock() {
    if (!mounted) return;
    final lock = LibraryChrome.maybeOf(context)?.pagerLock;
    if (lock != null) lock.value = _select.active || _pinching;
  }

  @override
  void dispose() {
    _select.removeListener(_syncLock);
    _offSearch?.call();
    _offRefresh?.call();
    _offBridge?.call();
    _debounce?.cancel();
    _ambientTimer?.cancel();
    _scroll.dispose();
    _search.dispose();
    _searchFocus.dispose();
    _gridScope.dispose();
    _pull.dispose();
    _live.dispose();
    _focused.dispose();
    _select.dispose();
    super.dispose();
  }

  ShelfQueryNotifier get _q => ref.read(shelfQueryProvider.notifier);
  GlassShelfActions get _actions => ref.read(glassShelfActionsProvider);
  bool get _phone => GlassFrame.of(context) == GlassFrameKind.phone;

  // ---- ambient field ---------------------------------------------------------------------------------------------

  void _onScroll() {
    _ambientTimer?.cancel();
    _ambientTimer = Timer(const Duration(milliseconds: 600), _setAmbient);
  }

  void _setAmbient() {
    if (!mounted || _rows.isEmpty) return;
    final density = ref.read(glassDensityProvider);
    final cols = _phone ? (density.phone.isList ? 1 : density.phone.columns) : 4;
    final per = (_phone ? 240.0 : 300.0);
    final i = ((_scroll.hasClients ? _scroll.offset : 0) / per).floor() * cols;
    final s = _rows[i.clamp(0, _rows.length - 1)];
    final gateOpen = ref.read(matureGateOpenProvider);
    final mature = s.rating == 'mature';
    final p = mature && !gateOpen ? null : paletteOf(null, s.ambient);
    ref.read(libraryAmbientProvider.notifier).state = p == null ? null : GlassAmbientSpec.palette(p, opacity: 0.18);
  }

  // ---- actions ---------------------------------------------------------------------------------------------------

  Future<RefreshResult> _refresh() async {
    ref
      ..invalidate(shelfProvider)
      ..invalidate(shelfCountsProvider)
      ..invalidate(shelfContinueProvider);
    try {
      final r = await ref.read(shelfProvider.future);
      return r.rows.length == _rows.length ? RefreshResult.unchanged : RefreshResult.changed;
    } catch (_) {
      return RefreshResult.unchanged;
    }
  }

  void _openSheet(String id) {
    final uri = Uri.parse(GoRouterState.of(context).uri.toString());
    GoRouter.of(context).go(uri.replace(queryParameters: {...uri.queryParameters, 'sheet': id}).toString());
  }

  void _step(int dir) {
    final reduced = ref.read(glassMotionPrefsProvider).reduced;
    _flip.snapshot();
    final n = ref.read(glassDensityProvider.notifier);
    if (_phone) {
      n.stepPhoneBy(larger: dir > 0);
    } else {
      n.stepWideBy(larger: dir > 0);
    }
    unawaited(ref.read(glassHapticsProvider).fire(HapticEvent.select));
    _flip.play(instant: reduced);
  }

  void _query(ShelfQuery Function(ShelfQuery) f, [Offset? cause]) {
    _wave.replay(cause ?? Offset.zero);
    _q.patch(f);
    if (widget.browseAll) _writeLocation(f(ref.read(shelfQueryProvider)));
  }

  void _writeLocation(ShelfQuery q) {
    final p = <String, String>{
      if (q.q.isNotEmpty) 'q': q.q,
      if (q.effectiveStatus != ShelfStatus.all) 'reading_status': q.effectiveStatus.wire!,
      if (q.fav) 'fav': '1',
      'sort': q.sort.name,
      if (q.tagIds.isNotEmpty) 'tags': q.tagIds.join(','),
    };
    GoRouter.of(context).replace<void>(Uri(path: Routes.libraryAliases.first, queryParameters: p).toString());
  }

  void _onSearch(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted && v.trim() != ref.read(shelfQueryProvider).q) _query((q) => q.copyWith(q: v.trim()));
    });
  }

  void _sortMenu(Rect anchor) {
    final cur = ref.read(shelfQueryProvider).sort;
    const sorts = [(ShelfSort.updated, 'Recently updated'), (ShelfSort.added, 'Recently added'), (ShelfSort.title, 'Title'), (ShelfSort.manual, 'Manual order')];
    unawaited(showGlassMenu(context, anchor: anchor, title: 'Sort', entries: [
      for (final s in sorts) GlassMenuEntry(label: s.$2, checked: cur == s.$1, onSelected: () => _query((q) => q.copyWith(sort: s.$1))),
    ],),);
  }

  void _reorder(int from, int to) {
    if (from == to || from < 0 || to < 0 || to >= _rows.length) return;
    final s = _rows[from];
    final total = _rows.length;
    unawaited(_actions.reorderRows(_rows, from, to).then((_) {
      if (!mounted) return;
      unawaited(SemanticsService.sendAnnouncement(View.of(context), '${s.title} moved to position ${to + 1} of $total', TextDirection.ltr, assertiveness: Assertiveness.assertive));
    }),);
  }

  int get _focusedIndex {
    final id = _focused.value;
    return id == null ? -1 : _rows.indexWhere((r) => r.id == id);
  }

  void _move(TraversalDirection d) => FocusManager.instance.primaryFocus?.focusInDirection(d);

  void _edge(bool first) {
    final nodes = _gridScope.traversalDescendants.toList();
    if (nodes.isEmpty) return;
    (first ? nodes.first : nodes.last).requestFocus();
  }

  void _section(int delta) {
    final i = (LibrarySection.shelf.index + delta).clamp(0, LibrarySection.values.length - 1);
    if (i != LibrarySection.shelf.index) GoRouter.of(context).replace<void>(LibrarySection.values[i].path);
  }

  List<LibraryKey> _keys() {
    final manual = ref.read(shelfQueryProvider).canReorder;
    final perRow = _phone ? 3 : 4;
    return [
      LibraryKey(description: 'Move through the grid', keys: const ['←', '↑', '→', '↓'], match: (e, hk) => false, action: () {}),
      LibraryKey(description: 'Move through the grid', keys: const ['h', 'j', 'k', 'l'], single: true, match: (e, hk) => false, action: () {}),
      LibraryKey(description: 'First or last series', keys: const ['Home', 'End'], match: (e, hk) => false, action: () {}),
      // shift+x first: a keyboard may report the shifted key's character as a lower-case 'x'.
      LibraryKey(description: 'Select a range', keys: const ['⇧', 'x'], single: true, match: kShiftLetter(LogicalKeyboardKey.keyX), action: () {
        final id = _focused.value;
        if (id != null) _select.extendTo(id);
      },),
      LibraryKey(description: 'Select', keys: const ['x'], single: true, match: kChar('x'), action: () {
        final id = _focused.value;
        if (id != null) _select.active ? _select.toggle(id) : _select.enter(id);
      },),
      LibraryKey(description: 'Favourite', keys: const ['*'], single: true, match: kChar('*'), action: () {
        final i = _focusedIndex;
        if (i >= 0) unawaited(_actions.favourite(_rows[i]));
      },),
      LibraryKey(description: 'Mark read', keys: const ['m'], single: true, match: kChar('m'), action: () {
        final i = _focusedIndex;
        if (i >= 0) unawaited(_actions.markRead({_rows[i].id}));
      },),
      LibraryKey(description: 'Previous section', keys: const ['['], single: true, match: kChar('['), action: () => _section(-1)),
      LibraryKey(description: 'Next section', keys: const [']'], single: true, match: kChar(']'), action: () => _section(1)),
      LibraryKey(description: 'Refresh', keys: const ['r'], single: true, match: (e, hk) => false, action: () {}),
      if (manual) ...[
        LibraryKey(description: 'Move earlier or later', keys: const ['⌥', '↑ ↓'], match: kKey(LogicalKeyboardKey.arrowUp, alt: true), action: () => _reorder(_focusedIndex, _focusedIndex - perRow)),
        LibraryKey(description: 'Move earlier or later', keys: const ['⌥', '↓'], match: kKey(LogicalKeyboardKey.arrowDown, alt: true), action: () => _reorder(_focusedIndex, _focusedIndex + perRow)),
        LibraryKey(description: 'Move one place', keys: const ['⌥', '⇧', '←'], match: kKey(LogicalKeyboardKey.arrowLeft, alt: true, shift: true), action: () => _reorder(_focusedIndex, _focusedIndex - 1)),
        LibraryKey(description: 'Move one place', keys: const ['⌥', '⇧', '→'], match: kKey(LogicalKeyboardKey.arrowRight, alt: true, shift: true), action: () => _reorder(_focusedIndex, _focusedIndex + 1)),
        LibraryKey(description: 'Move to the top or bottom', keys: const ['⌥', '⇧', '↑'], match: kKey(LogicalKeyboardKey.arrowUp, alt: true, shift: true), action: () => _reorder(_focusedIndex, 0)),
        LibraryKey(description: 'Move to the top or bottom', keys: const ['⌥', '⇧', '↓'], match: kKey(LogicalKeyboardKey.arrowDown, alt: true, shift: true), action: () => _reorder(_focusedIndex, _rows.length - 1)),
      ],
      // The arrows, hjkl and Home/End: plain keys that move focus (no text field has it; the registry lists them above).
      LibraryKey(description: '', keys: const [], match: kKey(LogicalKeyboardKey.arrowLeft), action: () => _move(TraversalDirection.left)),
      LibraryKey(description: '', keys: const [], match: kKey(LogicalKeyboardKey.arrowRight), action: () => _move(TraversalDirection.right)),
      LibraryKey(description: '', keys: const [], match: kKey(LogicalKeyboardKey.arrowUp), action: () => _move(TraversalDirection.up)),
      LibraryKey(description: '', keys: const [], match: kKey(LogicalKeyboardKey.arrowDown), action: () => _move(TraversalDirection.down)),
      LibraryKey(description: '', keys: const [], single: true, match: kChar('h'), action: () => _move(TraversalDirection.left)),
      LibraryKey(description: '', keys: const [], single: true, match: kChar('l'), action: () => _move(TraversalDirection.right)),
      LibraryKey(description: '', keys: const [], single: true, match: kChar('k'), action: () => _move(TraversalDirection.up)),
      LibraryKey(description: '', keys: const [], single: true, match: kChar('j'), action: () => _move(TraversalDirection.down)),
      LibraryKey(description: '', keys: const [], match: kKey(LogicalKeyboardKey.home), action: () => _edge(true)),
      LibraryKey(description: '', keys: const [], match: kKey(LogicalKeyboardKey.end), action: () => _edge(false)),
    ];
  }

  // ---- build -----------------------------------------------------------------------------------------------------

  Widget _lens({required LensSituation s, required String title, String? description, LensAction? primary, GlassLensTone tone = GlassLensTone.empty}) => SliverToBoxAdapter(
        child: Padding(padding: const EdgeInsets.symmetric(vertical: 32), child: GlassObjectLens(situation: s, title: title, description: description, tone: tone, primary: primary)),
      );

  Widget _skeleton(BuildContext context) {
    final density = ref.watch(glassDensityProvider);
    final cols = _phone ? (density.phone.isList ? 1 : density.phone.columns) : 5;
    return SliverToBoxAdapter(
      child: GlassSkeletonGroup(
        child: LayoutBuilder(builder: (context, c) {
          final gap = _phone ? 12.0 : 20.0;
          final w = (c.maxWidth - gap * (cols - 1)) / cols;
          return Wrap(spacing: gap, runSpacing: gap, children: [
            for (var i = 0; i < 12; i++) cols == 1 ? GlassSkeleton(width: c.maxWidth, height: 76, index: i) : GlassSkeleton(width: w, height: w * 1.5, index: i),
          ],);
        },),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final q = ref.watch(shelfQueryProvider);
    final shelf = ref.watch(shelfProvider);
    final counts = ref.watch(shelfCountsProvider).valueOrNull;
    final novels = ref.watch(contentModeScopeProvider).isNovel;
    final gateOpen = ref.watch(matureGateOpenProvider);
    final saved = ref.watch(downloadedSeriesProvider).valueOrNull ?? const [];
    final density = ref.watch(glassDensityProvider);
    ref.listen(shelfQueryProvider, (p, n) {
      if (p != null && p.copyWith(q: '') != n.copyWith(q: '')) _wave.replay(Offset.zero);
    });
    final data = shelf.valueOrNull;
    _rows = data?.rows ?? const [];
    if (data != null && _firstPaint) {
      _firstPaint = false;
      _wave.replay(Offset.zero);
    }
    final offline = data?.offline ?? false;
    final downloaded = {
      for (final g in saved)
        if (g.chapters.any((c) => c.state == DownloadChapterState.complete)) '${g.sourceId}|${g.seriesKey}',
    };
    final ui = ShelfUi(select: _select, flip: _flip, live: _live, wave: _wave, focused: _focused, downloaded: downloaded, gateOpen: gateOpen, toolbarKey: _toolbarKey);
    final list = _phone ? density.phone.isList : density.wide == GlassDensityWide.list;

    final toolbar = ShelfToolbarSpec(
      query: q,
      searchController: _search,
      searchFocus: _searchFocus,
      onQuery: _onSearch,
      onStatus: (s) => _query((x) => x.copyWith(status: s, clearReadingStatus: true, fav: false)),
      onFavourites: () => _query((x) => x.copyWith(fav: !x.fav)),
      onFilters: () => _openSheet('filters'),
      onSort: () => _sortMenu(Rect.fromLTWH(MediaQuery.sizeOf(context).width / 2, 160, 1, 1)),
      onBrowseAll: widget.browseAll ? null : () => GoRouter.of(context).replace<void>(Routes.libraryAliases.first),
      sortLabel: switch (q.sort) { ShelfSort.manual => 'Manual order', ShelfSort.title => 'Title', ShelfSort.added => 'Recently added', _ => 'Sort' },
      density: density.wide,
      onDensity: (d) {
        if (d == density.wide) return;
        _flip.snapshot();
        ref.read(glassDensityProvider.notifier).setWide(d);
        unawaited(ref.read(glassHapticsProvider).fire(HapticEvent.select));
        _flip.play(instant: ref.read(glassMotionPrefsProvider).reduced);
      },
    );

    final Widget body;
    if (data == null && shelf.isLoading) {
      body = _skeleton(context);
    } else if (data == null) {
      body = _lens(s: LensSituation.loadError, title: "Couldn't load your library", tone: GlassLensTone.error, primary: LensAction('Try again', () => unawaited(_refresh())));
    } else if (_rows.isEmpty) {
      body = q.q.trim().isNotEmpty
          ? _lens(s: LensSituation.nothingFound, title: 'No results for “${q.q.trim()}”', primary: LensAction('Clear search', () {
              _search.clear();
              _query((x) => x.copyWith(q: ''));
            }),)
          : q.filtering
              ? _lens(s: LensSituation.nothingFound, title: 'No series match these filters', primary: LensAction('Clear filters', () => _query((x) => x.cleared())))
              : _lens(
                  s: LensSituation.shelf,
                  title: novels ? 'Your shelf is empty' : 'Your shelf is empty',
                  description: novels ? 'Add a book from a novel source to start your shelf' : 'Follow series from Sources to build your shelf.',
                  primary: LensAction('Browse sources', () => ref.read(skinRouterProvider).go(Routes.sources())),
                );
    } else if (novels) {
      body = SliverBookShelf(rows: _rows, ui: ui);
    } else {
      body = SliverShelfGrid(rows: _rows, ui: ui, manual: q.canReorder && !offline && !_select.active, onReorder: _reorder);
    }

    final capped = data != null && !offline && data.total > _rows.length;
    final overflow = <GlassMenuEntry>[
      GlassMenuEntry(label: 'Sort', onSelected: () => _sortMenu(Rect.fromLTWH(MediaQuery.sizeOf(context).width - 24, 80, 1, 1))),
      if (!novels) GlassMenuEntry(label: 'Density', onSelected: () => _openSheet('density')),
      GlassMenuEntry(label: 'Show filters', onSelected: () => _openSheet('filters')),
      GlassMenuEntry(label: 'Manage tags', onSelected: () => _openSheet('manage-tags')),
      GlassMenuEntry(label: 'Refresh', onSelected: () => unawaited(_pull.refresh())),
    ];

    final slivers = <Widget>[
      SliverToBoxAdapter(child: ShelfContinueRail(show: !q.filtering && !offline && !_select.active)),
      SliverPersistentHeader(pinned: true, delegate: ShelfToolbarDelegate(toolbar, boundary: _toolbarKey, extent: 120 + 18 * (MediaQuery.textScalerOf(context).scale(1) - 1).clamp(0.0, 1.0))),
      if (_select.active)
        SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.only(bottom: 12), child: GlassSelectAssistChips<int>(controller: _select, visible: [for (final r in _rows) r.id]))),
      if (capped)
        SliverToBoxAdapter(
          child: Padding(padding: const EdgeInsets.only(bottom: 12), child: GlassLabel('Showing the first ${_rows.length} of ${data.total}. Narrow it with search or a filter.', role: gt.typeFootnote, color: gt.colorLabel2, maxLines: 3)),
        ),
      body,
    ];

    return LibraryKeys(
      group: 'Library',
      section: LibrarySection.shelf,
      bindings: _keys(),
      child: DensityPinch(
        live: _live,
        wheel: !_phone,
        onPinching: (p) {
          if (p == _pinching) return;
          setState(() => _pinching = p);
          _syncLock();
        },
        onStep: (d) {
          if (d != 0 && !list) _step(d);
        },
        child: FocusScope(
          node: _gridScope,
          child: GlassSelectableGroup<int>(
            controller: _select,
            ids: [for (final r in _rows) r.id],
            label: 'Select series',
            child: LibrarySectionFrame(
              section: LibrarySection.shelf,
              scrollController: _scroll,
              physics: _pinching ? const NeverScrollableScrollPhysics() : kGlassRefreshPhysics,
              refreshSliver: GlassPullToRefresh(controller: _pull, onRefresh: _refresh),
              countLine: counts == null || counts.total == 0 ? null : shelfCountLine(counts, novels: novels),
              trailing: [GlassBarAction(id: 'select', label: 'Select', glyph: roleGlyph(GlassIconRole.select), onPress: () => _select.active ? _select.exit() : _select.enter())],
              overflow: overflow,
              slivers: slivers,
              overlay: GlassShelfBulkBar(controller: _select),
            ),
          ),
        ),
      ),
    );
  }
}

/// "142 series followed" / "38 books on your shelf" (the large title's count line).
String shelfCountLine(ShelfCounts c, {required bool novels}) => novels ? '${c.total} ${c.total == 1 ? 'book' : 'books'} on your shelf' : '${c.total} series followed';
