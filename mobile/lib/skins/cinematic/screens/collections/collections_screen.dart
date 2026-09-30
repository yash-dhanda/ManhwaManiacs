import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/core/keyboard/shortcut_registry.dart';
import 'package:manhwamaniacs/features/circle/models/circle_models.dart';
import 'package:manhwamaniacs/features/collections/providers/collection_detail_provider.dart';
import 'package:manhwamaniacs/features/collections/providers/collection_order.dart';
import 'package:manhwamaniacs/features/collections/providers/collection_sort_provider.dart';
import 'package:manhwamaniacs/features/collections/providers/collections_provider.dart';
import 'package:manhwamaniacs/features/collections/providers/shared_collections_provider.dart';
import 'package:manhwamaniacs/features/collections/utils/collection_sorting.dart';
import 'package:manhwamaniacs/features/content_mode/content_mode_controller.dart';
import 'package:manhwamaniacs/features/library/models/collection.dart';
import 'package:manhwamaniacs/features/library/models/followed_series.dart';
import 'package:manhwamaniacs/features/library/utils/manual_order.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/icons/icon_roles.g.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_badge.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_galley.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_icon_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_menu.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_notice.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_radio.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_search_field.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/layout/cine_grid.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/rows/cine_reorderable_list.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/rows/cine_reorderable_wall.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/sheet_route.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/toasts.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/circle/shelves_tab.dart' show SharedShelfPlate;
import 'package:manhwamaniacs/skins/cinematic/screens/collections/collection_plate.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/collections/shelf_form.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/hub/hub_kit.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/library/library_hub.dart';
import 'package:manhwamaniacs/skins/cinematic/shell/cine_scaffold.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// Collections, "Shelves" (cinematic 8.11, ScreenId `collections`): the owner's shelves as 16:9
/// plates, New shelf, search, the four sorts and Custom order. Sharing is `mobile/22`'s.
class CollectionsScreen extends ConsumerStatefulWidget {
  const CollectionsScreen({super.key, this.openNew = false, this.shareOnNew = false});

  /// `?sheet=collection-new`: opens the New shelf form on arrival (the Circle's SHELVES tab), with
  /// `Share with the circle` on when [shareOnNew] (`view=shared`).
  final bool openNew, shareOnNew;

  @override
  ConsumerState<CollectionsScreen> createState() => _CollectionsScreenState();
}

class _CollectionsScreenState extends ConsumerState<CollectionsScreen> {
  final _mastheadFocus = FocusNode(debugLabel: 'collections-masthead');
  final _searchFocus = FocusNode(debugLabel: 'shelf-search');
  final _search = TextEditingController();
  final _scroll = ScrollController();
  final List<FocusNode> _nodes = [];
  bool _searchOpen = false;
  List<Collection> _shown = const [];
  List<Collection> _all = const [];
  int _perRow = 1;

  @override
  void initState() {
    super.initState();
    if (widget.openNew) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(showShelfForm(context, shareWithCircle: widget.shareOnNew));
      });
    }
  }

  @override
  void dispose() {
    _mastheadFocus.dispose();
    _searchFocus.dispose();
    _search.dispose();
    _scroll.dispose();
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  CineToastsNotifier get _toasts => ref.read(cineToastsProvider.notifier);

  List<FocusNode> _nodesFor(int n) {
    while (_nodes.length < n) {
      _nodes.add(FocusNode(debugLabel: 'plate-${_nodes.length}'));
    }
    return _nodes;
  }

  int _focused() {
    for (var i = 0; i < _nodes.length && i < _shown.length; i++) {
      if (_nodes[i].hasFocus) return i;
    }
    return -1;
  }

  void _focusIndex(int i) {
    if (i < 0 || i >= _shown.length) return;
    final n = _nodes[i];
    n.requestFocus();
    final ctx = n.context;
    if (ctx != null) unawaited(Scrollable.ensureVisible(ctx, duration: hubScroll(context), alignment: 0.3));
  }

  bool get _canReorder => ref.read(collectionSortProvider) == CollectionSort.custom && _search.text.trim().isEmpty && _all.length > 1;

  Future<void> _move(int from, int to) async {
    if (from == to || from < 0 || to < 0 || to >= _shown.length) return;
    final before = _shown;
    final after = reorder(before, from, to);
    final ok = await ref.read(collectionOrderProvider).collections(before, after);
    if (!ok && mounted) _toasts.error("Couldn't save the order.");
  }

  Future<void> _reload() async {
    await ref.read(collectionsProvider.notifier).reload();
  }

  void _openSearch() {
    setState(() => _searchOpen = true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _searchFocus.requestFocus());
  }

  void _newShelf() => unawaited(showShelfForm(context));


  Future<void> _sortSheet() async {
    final now = ref.read(collectionSortProvider);
    final picked = await showCineSheet<CollectionSort>(
      context,
      kicker: 'SORT',
      title: 'Sort shelves',
      builder: (ctx) => Column(children: [
        for (final s in CollectionSort.values)
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: CineRadio<CollectionSort>(value: s, groupValue: now, label: collectionSortLabel(s), onChanged: (v) => Navigator.of(ctx).pop(v)),
          ),
      ],),
    );
    if (picked != null) ref.read(collectionSortProvider.notifier).state = picked;
  }

  void _sortMenu(BuildContext anchor) {
    final now = ref.read(collectionSortProvider);
    unawaited(showCineMenu<CollectionSort>(anchor, anchor: cineAnchorRect(anchor), entries: [
      for (final s in CollectionSort.values) CineMenuEntry<CollectionSort>(label: collectionSortLabel(s), value: s, checked: s == now, onSelected: () => ref.read(collectionSortProvider.notifier).state = s),
    ],),);
  }

  String? Function(FollowedSeries) get _kindOf {
    final scope = ref.read(contentModeScopeProvider);
    return (s) => scope.novelsEnabled ? scope.modeOf(s.sourceId).name : null;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final async = ref.watch(collectionsProvider);
    final sort = ref.watch(collectionSortProvider);
    final followed = ref.watch(librarySeriesPickerProvider).valueOrNull ?? const <FollowedSeries>[];
    final apiBase = ref.watch(apiBaseUrlProvider);
    final grid = CineGrid.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= 768;
    _perRow = width >= 900 ? 3 : (width >= 600 ? 2 : 1);
    final query = _search.text;
    _all = async.valueOrNull ?? _all;
    final shown = sortCollections(filterCollections(_all, query), sort);
    _shown = shown;
    final nodes = _nodesFor(shown.length);
    final reorderable = _canReorder;
    final kindOf = _kindOf;
    final sharedData = ref.watch(sharedCollectionsProvider).valueOrNull;
    final sharedById = {for (final x in sharedData?.collections ?? const <SharedShelf>[]) if (x.shared != null) x.id: x};
    final withMe = query.trim().isEmpty ? sharedData?.sharedWithMe ?? const <SharedShelf>[] : [for (final x in sharedData?.sharedWithMe ?? const <SharedShelf>[]) if (x.name.toLowerCase().contains(query.trim().toLowerCase())) x];

    Widget plate(Collection col, int i, {Widget? handle, List<CineMenuEntry<Object?>>? entries, Map<CustomSemanticsAction, VoidCallback>? actions}) {
      final art = plateArt(col, followed, apiBase, contentKindOf: kindOf);
      final share = sharedById[col.id];
      return CollectionPlate(
        key: ValueKey('plate-${col.id}'),
        collection: col,
        art: art,
        sharedWith: [for (final m in share?.shared?.members ?? const <ProfileRef>[]) if (m.avatarKey != null) m.avatarKey!],
        badges: share?.shared == null ? const [] : const [CineBadge('SHARED', variant: CineBadgeVariant.shared)],
        focusNode: nodes[i],
        onTap: () => unawaited(context.push(Routes.collection(col.id))),
        dragHandle: handle == null ? null : Padding(padding: const EdgeInsets.all(4), child: handle),
        moveEntries: entries,
        semanticActions: actions,
        menuOnLongPress: !(reorderable && !wide),
      );
    }

    Widget list() {
      if (reorderable) {
        if (_perRow == 1) {
          return SliverToBoxAdapter(
            child: CineReorderableList<Collection>(
              items: shown,
              idOf: (x) => x.id,
              titleOf: (x) => x.name,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              onMove: (f, t) => unawaited(_move(f, t)),
              itemBuilder: (ctx, col, i, handle, entries, actions) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: ReorderableDelayedDragStartListener(index: i, child: plate(col, i, handle: handle, entries: entries, actions: actions)),
              ),
            ),
          );
        }
        final cell = (width - grid.left - grid.right - 16 * (_perRow - 1)) / _perRow;
        return SliverToBoxAdapter(
          child: CineReorderableWall<Collection>(
            items: shown,
            idOf: (x) => x.id,
            titleOf: (x) => x.name,
            crossAxisCount: _perRow,
            aspectRatio: cell / (cell * 9 / 16),
            spacing: 16,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            onMove: (f, t) => unawaited(_move(f, t)),
            itemBuilder: (ctx, col, i, handle, entries, actions) => plate(col, i, handle: handle, entries: entries, actions: actions),
          ),
        );
      }
      if (_perRow == 1) {
        return SliverList.separated(
          itemCount: shown.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (ctx, i) => plate(shown[i], i, entries: _entries(shown, i, reorderable)),
        );
      }
      return SliverGrid.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: _perRow, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 16 / 9),
        itemCount: shown.length,
        itemBuilder: (ctx, i) => plate(shown[i], i),
      );
    }

    final slivers = <Widget>[
      SliverToBoxAdapter(child: _toolbar(context, wide, grid)),
    ];
    if (async.isLoading && _all.isEmpty) {
      slivers.add(SliverPadding(
        padding: EdgeInsets.fromLTRB(grid.left, c.space2, grid.right, c.space6),
        sliver: SliverList.separated(
          itemCount: 4,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (_, i) => AspectRatio(aspectRatio: 16 / 9, child: CineFlicker(index: i, child: const CineGalleyPlate())),
        ),
      ),);
    } else if (async.hasError && _all.isEmpty) {
      slivers.add(SliverToBoxAdapter(
        child: HubErrorNotice(
          error: async.error!,
          offlineHeadline: 'Collections need a connection to load.',
          errorHeadline: "Collections didn't load.",
          onRetry: () => ref.invalidate(collectionsProvider),
        ),
      ),);
    } else if (_all.isEmpty) {
      slivers.add(SliverToBoxAdapter(
        child: HubNoticeBox(
          notice: CineNotice(
            key: const Key('collections-empty'),
            tone: CineNoticeTone.empty,
            kicker: 'NO SHELVES YET',
            headline: 'No shelves yet.',
            deck: 'Group series by theme, mood or reading plan.',
            primary: CineNoticeAction('New shelf', _newShelf),
          ),
        ),
      ),);
    } else if (shown.isEmpty) {
      slivers.add(SliverToBoxAdapter(
        child: HubNoticeBox(
          notice: CineNotice(
            key: const Key('collections-no-match'),
            tone: CineNoticeTone.empty,
            kicker: 'NOTHING MATCHES',
            headline: 'No shelves match that.',
            quiet: CineNoticeAction('Clear search', () {
              _search.clear();
              setState(() {});
            }),
          ),
        ),
      ),);
    } else {
      slivers.add(SliverPadding(padding: EdgeInsets.fromLTRB(grid.left, c.space2, grid.right, c.space6), sliver: list()));
    }

    if (withMe.isNotEmpty) {
      slivers.add(SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.fromLTRB(grid.left, c.space4, grid.right, c.space2),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Semantics(header: true, child: CineRoleText('SHARED WITH YOU', c.typeKicker, color: c.colorInk45)),
            SizedBox(height: c.space2),
            DecoratedBox(decoration: BoxDecoration(border: Border(top: c.ruleHair)), child: const SizedBox(width: double.infinity)),
          ],),
        ),
      ),);
      slivers.add(SliverPadding(
        padding: EdgeInsets.fromLTRB(grid.left, c.space2, grid.right, c.space6),
        sliver: SliverGrid.count(
          crossAxisCount: _perRow,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 16 / 9,
          children: [for (final x in withMe) SharedShelfPlate(key: ValueKey('shared-${x.id}'), shelf: x)],
        ),
      ),);
    }
    final nShared = sharedById.length;
    final deck = _all.isEmpty && withMe.isEmpty
        ? ''
        : [
            '${_all.length} ${_all.length == 1 ? 'shelf' : 'shelves'}',
            if (nShared > 0) '$nShared shared',
            if ((sharedData?.sharedWithMe.length ?? 0) > 0) '${sharedData!.sharedWithMe.length} shared with you',
          ].join(' · ');
    return CineScaffold(
      runningTitle: 'Collections',
      contentModeChip: true,
      firstRunNote: false,
      mastheadFocusNode: _mastheadFocus,
      body: RegisteredShortcuts(
        group: 'Collections',
        entries: [
          hubKey('Collections', LogicalKeyboardKey.keyN, 'New shelf', _newShelf),
          hubKey('Collections', LogicalKeyboardKey.slash, 'Search shelves', _openSearch),
          hubKey('Collections', LogicalKeyboardKey.keyR, 'Reload the shelves', () => unawaited(_reload())),
          hubKey('Collections', LogicalKeyboardKey.arrowLeft, 'Previous shelf', () => _step(-1, 0), single: false, keys: const ['←']),
          hubKey('Collections', LogicalKeyboardKey.arrowRight, 'Next shelf', () => _step(1, 0), single: false, keys: const ['→']),
          hubKey('Collections', LogicalKeyboardKey.arrowUp, 'Shelf above', () => _step(0, -1), single: false, keys: const ['↑']),
          hubKey('Collections', LogicalKeyboardKey.arrowDown, 'Shelf below', () => _step(0, 1), single: false, keys: const ['↓']),
          hubKey('Collections', LogicalKeyboardKey.home, 'First shelf', () => _focusIndex(0), single: false),
          hubKey('Collections', LogicalKeyboardKey.end, 'Last shelf', () => _focusIndex(_shown.length - 1), single: false),
          for (final (k, dx, dy, label) in [
            (LogicalKeyboardKey.arrowLeft, -1, 0, '←'),
            (LogicalKeyboardKey.arrowRight, 1, 0, '→'),
            (LogicalKeyboardKey.arrowUp, 0, -1, '↑'),
            (LogicalKeyboardKey.arrowDown, 0, 1, '↓'),
          ])
            hubKey('Collections', k, 'Move the focused shelf (Custom order)', () => _altMove(dx, dy), alt: true, keys: ['Alt', label]),
        ],
        child: LibraryHub(
          tab: HubTab.collections,
          masthead: (kicker: 'No. 06 — SHELVES', title: 'Collections', deck: deck),
          slivers: slivers,
          scrollController: _scroll,
          mastheadFocus: _mastheadFocus,
          onRefresh: _reload,
        ),
      ),
    );
  }

  void _step(int dx, int dy) {
    if (_shown.isEmpty) return;
    final cur = _focused();
    if (cur < 0) {
      _focusIndex(0);
      return;
    }
    _focusIndex((cur + dx + dy * _perRow).clamp(0, _shown.length - 1));
  }

  void _altMove(int dx, int dy) {
    if (!_canReorder) return;
    final cur = _focused();
    if (cur < 0) return;
    final to = cur + dx + dy * _perRow;
    if (to < 0 || to >= _shown.length || to == cur) return;
    final name = _shown[cur].name;
    unawaited(_move(cur, to));
    SemanticsService.sendAnnouncement(View.of(context), '$name moved to position ${to + 1} of ${_shown.length}', TextDirection.ltr);
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusIndex(to));
  }

  List<CineMenuEntry<Object?>>? _entries(List<Collection> shown, int i, bool reorderable) => reorderable
      ? cineMoveEntries(context, title: shown[i].name, index: i, count: shown.length, onMove: (f, t) => unawaited(_move(f, t)))
      : null;

  Widget _toolbar(BuildContext context, bool wide, CineGridSpec grid) {
    final c = context.cine;
    final sort = ref.watch(collectionSortProvider);
    final searchField = CineSearchField(
      key: const Key('shelf-search-field'),
      semanticLabel: 'Search shelves',
      placeholder: 'Search shelves',
      variant: CineSearchVariant.compact,
      controller: _search,
      focusNode: _searchFocus,
      onChanged: (_) => setState(() {}),
    );
    final sortBtn = Builder(
      builder: (ctx) => CineButton(
        key: const Key('shelf-sort'),
        label: wide ? 'Sort · ${collectionSortLabel(sort)}' : 'Sort',
        variant: CineButtonVariant.quiet,
        size: CineButtonSize.sm,
        onPressed: () => wide ? _sortMenu(ctx) : unawaited(_sortSheet()),
      ),
    );
    if (wide && MediaQuery.textScalerOf(context).scale(16) / 16 >= 1.5) {
      // Large text: the search field takes a row, the buttons wrap under it.
      return Padding(
        padding: EdgeInsets.fromLTRB(grid.left, 0, grid.right, c.space3),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          searchField,
          SizedBox(height: c.space2),
          Wrap(spacing: c.space3, runSpacing: c.space2, children: [sortBtn, CineButton(label: 'New shelf', onPressed: _newShelf)]),
        ],),
      );
    }
    if (wide) {
      return Padding(
        padding: EdgeInsets.fromLTRB(grid.left, 0, grid.right, c.space3),
        child: Row(children: [
          Expanded(child: searchField),
          SizedBox(width: c.space3),
          sortBtn,
          SizedBox(width: c.space3),
          CineButton(label: 'New shelf', onPressed: _newShelf),
        ],),
      );
    }
    return Padding(
      padding: EdgeInsets.fromLTRB(grid.left, 0, grid.right, c.space3),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          if (_searchOpen) Expanded(child: searchField) else CineIconButton(label: 'Search shelves', role: CineIconRole.search, onPressed: _openSearch),
          if (!_searchOpen) const Spacer(),
          SizedBox(width: c.space2),
          sortBtn,
        ],),
        SizedBox(height: c.space2),
        CineButton(label: 'New shelf', variant: CineButtonVariant.secondary, fullWidth: true, onPressed: _newShelf),
      ],),
    );
  }
}
