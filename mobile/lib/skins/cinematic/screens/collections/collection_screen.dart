import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/core/keyboard/shortcut_registry.dart';
import 'package:manhwamaniacs/features/collections/providers/collection_detail_provider.dart';
import 'package:manhwamaniacs/features/collections/providers/collection_order.dart';
import 'package:manhwamaniacs/features/content_mode/content_mode.dart';
import 'package:manhwamaniacs/features/content_mode/content_mode_controller.dart';
import 'package:manhwamaniacs/features/downloads/providers/mature_gate_provider.dart';
import 'package:manhwamaniacs/features/library/models/collection_detail.dart';
import 'package:manhwamaniacs/features/library/models/followed_series.dart';
import 'package:manhwamaniacs/features/library/models/shelf_query.dart';
import 'package:manhwamaniacs/features/library/utils/bulk_runner.dart';
import 'package:manhwamaniacs/features/library/utils/cover_url.dart';
import 'package:manhwamaniacs/features/library/utils/smart_shelf.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/back_order.dart';
import 'package:manhwamaniacs/skins/cinematic/feedback.dart';
import 'package:manhwamaniacs/skins/cinematic/icons/icon_roles.g.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/parts/library_poster.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cards/cine_collection_plate.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_confirm_dialog.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_galley.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_menu.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_notice.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_poster.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_pull_to_reprint.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_select_mode_bar.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/layout/cine_grid.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/quick_look.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/quick_look_actions.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/rows/cine_reorderable_wall.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/toasts.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/collections/add_series_sheet.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/collections/collection_plate.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/collections/shelf_form.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/hub/hub_kit.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/library/shelf_wall.dart';
import 'package:manhwamaniacs/skins/cinematic/shell/cine_scaffold.dart';
import 'package:manhwamaniacs/skins/cinematic/stock.dart';
import 'package:manhwamaniacs/skins/cinematic/tint.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// One tile of the member wall: a followed series, or an orphan the library no longer follows.
class _Member {
  const _Member(this.sourceId, this.seriesKey, this.series);
  final String sourceId, seriesKey;
  final FollowedSeries? series;
  String get key => '$sourceId\u0000$seriesKey';
  String get title => series?.title ?? seriesKey.replaceAll(RegExp(r'[-_]+'), ' ');
}

/// A shelf's page (cinematic 8.11, ScreenId `collection`), pushed inside the Library branch: the
/// duotone header (the match cut's `Hero`), Add series, Edit, Reorder, Select, Delete, the member
/// wall, smart shelves evaluated on the device, and every state.
class CollectionScreen extends ConsumerStatefulWidget {
  const CollectionScreen({super.key, required this.collectionId});
  final int collectionId;

  @override
  ConsumerState<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends ConsumerState<CollectionScreen> {
  final _headerFocus = FocusNode(debugLabel: 'collection-header');
  final _scroll = ScrollController();
  final List<FocusNode> _nodes = [];
  bool _select = false, _reorder = false;
  final Set<String> _picked = {};
  CineSelectRun? _run;
  String? _result;
  List<_Member> _members = const [];
  List<_Member> _fullOrder = const [];
  int _perRow = 3;

  @override
  void dispose() {
    _headerFocus.dispose();
    _scroll.dispose();
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  int get _id => widget.collectionId;
  CollectionDetailNotifier get _detail => ref.read(collectionDetailProvider(_id).notifier);
  CineToastsNotifier get _toasts => ref.read(cineToastsProvider.notifier);
  bool get _smart => ref.read(collectionDetailProvider(_id)).valueOrNull?.rules != null;

  List<FocusNode> _nodesFor(int n) {
    while (_nodes.length < n) {
      _nodes.add(FocusNode(debugLabel: 'member-${_nodes.length}'));
    }
    return _nodes;
  }

  int _focused() {
    for (var i = 0; i < _nodes.length && i < _members.length; i++) {
      if (_nodes[i].hasFocus) return i;
    }
    return -1;
  }

  void _focusIndex(int i) {
    if (i < 0 || i >= _members.length) return;
    final n = _nodes[i];
    n.requestFocus();
    final ctx = n.context;
    if (ctx != null) unawaited(Scrollable.ensureVisible(ctx, duration: CineDur.line, alignment: 0.3));
  }

  void _exitModes() => setState(() {
        _select = false;
        _reorder = false;
        _picked.clear();
        _run = null;
        _result = null;
      });

  // ---- actions -------------------------------------------------------------------------------

  Future<void> _edit(CollectionDetail d) async {
    final saved = await showShelfForm(context, edit: d.toCollection());
    if (saved != null && mounted) ref.invalidate(collectionDetailProvider(_id));
  }

  Future<void> _delete(CollectionDetail d) async {
    final ok = await showCineConfirm(
      context,
      title: 'Delete ${d.name}? The series stay in your library.',
      confirmLabel: 'Delete shelf',
      destructive: true,
      filled: true,
      onConfirm: () async {
        final err = await _detail.deleteCollection();
        if (err != null) throw err;
      },
    );
    if (!ok || !mounted) return;
    cineFeedback(context, HapticEvent.deleteConfirm);
    _toasts.info('Deleted ${d.name}.');
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(Routes.collections());
    }
  }

  Future<void> _removePicked(CollectionDetail d) async {
    final keys = _picked.toList();
    if (keys.isEmpty) return;
    final ok = await showCineConfirm(
      context,
      title: 'Remove ${keys.length} from ${d.name}? It stays in your library.',
      confirmLabel: 'Remove ${keys.length}',
      destructive: true,
      filled: true,
    );
    if (!ok || !mounted) return;
    final repo = ref.read(libraryRepositoryProvider);
    final by = {for (final m in _fullOrder) m.key: m};
    setState(() => _run = (done: 0, total: keys.length, failed: 0));
    final out = await runBulk<String>(
      keys,
      (k) => repo.removeSeriesFromCollection(_id, sourceId: by[k]!.sourceId, seriesKey: by[k]!.seriesKey),
      onProgress: (done, failed) {
        if (mounted) setState(() => _run = (done: done, total: keys.length, failed: failed));
      },
    );
    if (!mounted) return;
    await _detail.reload();
    if (!mounted) return;
    setState(() {
      _run = null;
      _picked.clear();
      _result = out.failed > 0 ? '${out.done} of ${out.total} removed, ${out.failed} failed.' : 'Removed ${out.done} from ${d.name}.';
    });
  }

  Future<void> _removeOne(_Member m, CollectionDetail d) async {
    setState(() {
      _picked
        ..clear()
        ..add(m.key);
    });
    await _removePicked(d);
  }

  /// The full membership order after moving the tile at [from] onto the tile at [to] of the
  /// visible (mode-filtered) list.
  List<MemberKey> _reordered(int from, int to) {
    final moved = _members[from], anchor = _members[to];
    final order = [..._fullOrder]..removeWhere((m) => m.key == moved.key);
    var at = order.indexWhere((m) => m.key == anchor.key);
    if (to > from) at++;
    order.insert(at.clamp(0, order.length), moved);
    return [for (final m in order) (sourceId: m.sourceId, seriesKey: m.seriesKey)];
  }

  Future<void> _move(int from, int to) async {
    if (from == to || from < 0 || to < 0 || to >= _members.length) return;
    final ok = await ref.read(collectionOrderProvider).members(_id, _reordered(from, to));
    if (!ok && mounted) _toasts.error("Couldn't save the order.");
  }

  void _open(_Member m) {
    final s = m.series;
    if (s != null) {
      unawaited(context.push(Routes.featureByFollow(s.id)));
    } else {
      unawaited(context.push(Routes.feature(m.sourceId, m.seriesKey)));
    }
  }

  void _quickLook(_Member m, CollectionDetail d, String? cover) {
    final s = m.series;
    unawaited(openQuickLook(
      context,
      title: m.title,
      kicker: 'QUICK LOOK',
      heroTag: (m.sourceId, m.seriesKey),
      cover: const SizedBox.shrink(),
      credits: s == null ? 'NO LONGER FOLLOWED' : 'ON THIS SHELF',
      actions: [
        QuickLookAction(QuickLookId.open, 'Open', CineIconRole.external, onSelected: () => _open(m)),
        if (!_smart) QuickLookAction('remove-from-shelf', 'Remove from shelf', CineIconRole.delete, destructive: true, onSelected: () => unawaited(_removeOne(m, d))),
      ],
    ),);
  }

  // ---- build -------------------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final async = ref.watch(collectionDetailProvider(_id));
    final followedAsync = ref.watch(librarySeriesPickerProvider);
    final scope = ref.watch(contentModeScopeProvider);
    final gate = ref.watch(matureGateOpenProvider);
    final apiBase = ref.watch(apiBaseUrlProvider);
    final grid = CineGrid.of(context);
    final width = MediaQuery.sizeOf(context).width;
    _perRow = width >= 600 ? 5 : 3;

    final d = async.valueOrNull;
    final followed = followedAsync.valueOrNull ?? const <FollowedSeries>[];
    final smart = d?.rules != null;

    // The members: a manual shelf's stored order joined to library rows, a smart shelf's rows
    // computed on the device.
    var full = <_Member>[];
    if (d != null) {
      final byKey = {for (final s in followed) '${s.sourceId}\u0000${s.seriesKey}': s};
      final byIdentity = {for (final s in followed) '${s.sourceId}\u0000${s.identity}': s};
      if (smart) {
        full = [for (final s in evaluateShelf(d.rules!, followed, contentKindOf: (s) => scope.novelsEnabled ? scope.modeOf(s.sourceId).name : null)) _Member(s.sourceId, s.seriesKey, s)];
      } else {
        full = [
          for (final m in d.series)
            _Member(m.sourceId, m.seriesKey, byKey['${m.sourceId}\u0000${m.seriesKey}'] ?? byIdentity['${m.sourceId}\u0000${m.seriesKey}']),
        ];
      }
    }
    final visible = [for (final m in full) if (!scope.novelsEnabled || scope.modeOf(m.sourceId) == scope.mode) m];
    _fullOrder = full;
    _members = visible;
    final mismatch = full.isNotEmpty && visible.isEmpty && scope.novelsEnabled;
    final nodes = _nodesFor(visible.length);

    Widget body;
    Widget? header;
    if (async.hasError && d == null) {
      final e = async.error;
      if (e is ApiError && e.statusCode == 404) {
        body = CineNotice(
          key: const Key('collection-notfound'),
          tone: CineNoticeTone.empty,
          kicker: 'NOT IN THIS ISSUE',
          wholeScreen: true,
          headline: "This shelf isn't available here any more.",
          deck: 'It may have been removed.',
          primary: CineNoticeAction('Back to collections', () => context.go(Routes.collections())),
        );
      } else {
        body = HubNoticeBox(
          notice: CineNotice(
            key: const Key('collection-error'),
            tone: CineNoticeTone.error,
            kicker: 'CORRECTION',
            headline: "This shelf didn't load.",
            deck: e is NetworkError ? "You're offline." : "The server didn't answer.",
            primary: CineNoticeAction('Try again', () => ref.invalidate(collectionDetailProvider(_id))),
            quiet: CineNoticeAction('Back to collections', () => context.go(Routes.collections())),
          ),
        );
      }
    } else if (d == null) {
      header = Padding(padding: EdgeInsets.only(bottom: c.space4), child: const AspectRatio(aspectRatio: 16 / 9, child: CineFlicker(child: CineGalleyPlate())));
      body = _wall(context, const [], loading: true, d: null, apiBase: apiBase, gate: gate, nodes: nodes);
    } else {
      final art = plateArt(d.toCollection(), followed, apiBase, contentKindOf: (s) => scope.novelsEnabled ? scope.modeOf(s.sourceId).name : null);
      final covers = smart ? [for (final m in visible.take(4)) if (m.series != null && followedSeriesCoverUrl(apiBase, m.series!) != null) followedSeriesCoverUrl(apiBase, m.series!)!] : art.covers;
      header = _Header(detail: d, covers: covers, duo: art.duo, tint: art.tint, count: visible.length, focus: _headerFocus);
      body = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _actions(context, d, smart),
        if (mismatch)
          HubNoticeBox(
            notice: CineNotice(
              key: const Key('collection-mode-mismatch'),
              tone: CineNoticeTone.empty,
              kicker: 'NOTE',
              headline: scope.isNovel ? 'Everything on this shelf is manga.' : 'Everything on this shelf is a novel.',
              deck: scope.isNovel ? 'Switch to Manga to see it.' : 'Switch to Novels to see it.',
              primary: CineNoticeAction('Switch', () => unawaited(ref.read(contentModeControllerProvider.notifier).setMode(scope.isNovel ? ContentMode.manga : ContentMode.novel))),
            ),
          )
        else if (visible.isEmpty && smart)
          HubNoticeBox(
            notice: CineNotice(
              key: const Key('collection-nothing-matches'),
              tone: CineNoticeTone.empty,
              kicker: 'NOTHING MATCHES',
              headline: 'Nothing matches these rules.',
              primary: CineNoticeAction('Edit rules', () => unawaited(_edit(d))),
            ),
          )
        else if (visible.isEmpty)
          HubNoticeBox(
            notice: CineNotice(
              key: const Key('collection-empty'),
              tone: CineNoticeTone.empty,
              kicker: 'EMPTY SHELF',
              headline: 'This shelf is empty.',
              primary: CineNoticeAction('Add series', () => unawaited(_add(d))),
            ),
          )
        else
          _wall(context, visible, loading: false, d: d, apiBase: apiBase, gate: gate, nodes: nodes),
      ],);
    }

    final selecting = _select || _reorder;
    final content = CinePullToReprint(
      onRefresh: () async => _detail.reload(),
      child: ListView(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(0, 0, 0, selecting ? 160 : 48),
        children: [
          if (header != null) header,
          Padding(padding: EdgeInsets.symmetric(horizontal: grid.left), child: body),
        ],
      ),
    );

    return PopScope(
      canPop: !(_reorder && defaultTargetPlatform == TargetPlatform.iOS),
      child: CineModalBack(
        priority: CineBackPriority.selectMode,
        active: selecting,
        onBack: _exitModes,
        child: CineScaffold(
          runningTitle: d?.name ?? 'Collection',
          back: const CineBack(),
          firstRunNote: false,
          mastheadFocusNode: _headerFocus,
          body: RegisteredShortcuts(
            group: 'Collection',
            entries: [
              hubKey('Collection', LogicalKeyboardKey.keyE, 'Edit the shelf', () {
                if (d != null) unawaited(_edit(d));
              }),
              hubKey('Collection', LogicalKeyboardKey.keyA, 'Add series', () {
                if (d != null && !smart) unawaited(_add(d));
              }),
              hubKey('Collection', LogicalKeyboardKey.keyX, 'Select mode', () {
                if (d != null && visible.isNotEmpty) setState(() => _select = !_select);
              }),
              hubKey('Collection', LogicalKeyboardKey.keyR, 'Reload the shelf', () => unawaited(_detail.reload())),
              hubKey('Collection', LogicalKeyboardKey.delete, 'Remove the focused series', () {
                final i = _focused();
                if (d != null && !smart && i >= 0) unawaited(_removeOne(visible[i], d));
              }, single: false,),
              hubKey('Collection', LogicalKeyboardKey.arrowLeft, 'Previous series', () => _step(-1, 0), single: false, keys: const ['←']),
              hubKey('Collection', LogicalKeyboardKey.arrowRight, 'Next series', () => _step(1, 0), single: false, keys: const ['→']),
              hubKey('Collection', LogicalKeyboardKey.arrowUp, 'Series above', () => _step(0, -1), single: false, keys: const ['↑']),
              hubKey('Collection', LogicalKeyboardKey.arrowDown, 'Series below', () => _step(0, 1), single: false, keys: const ['↓']),
              hubKey('Collection', LogicalKeyboardKey.home, 'First series', () => _focusIndex(0), single: false),
              hubKey('Collection', LogicalKeyboardKey.end, 'Last series', () => _focusIndex(visible.length - 1), single: false),
              for (final (k, dx, dy, label) in [
                (LogicalKeyboardKey.arrowLeft, -1, 0, '←'),
                (LogicalKeyboardKey.arrowRight, 1, 0, '→'),
                (LogicalKeyboardKey.arrowUp, 0, -1, '↑'),
                (LogicalKeyboardKey.arrowDown, 0, 1, '↓'),
              ])
                hubKey('Collection', k, 'Move the focused series (Reorder)', () {
                  final i = _focused();
                  if (_reorder && i >= 0) {
                    final to = i + dx + dy * _perRow;
                    unawaited(_move(i, to));
                    WidgetsBinding.instance.addPostFrameCallback((_) => _focusIndex(to));
                  }
                }, alt: true, keys: ['Alt', label],),
            ],
            child: Stack(children: [
              Positioned.fill(child: content),
              if (_select)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: CineSelectModeBar(
                    selected: _picked.length,
                    total: visible.length,
                    onDone: _exitModes,
                    onSelectAll: () => setState(() => _picked.addAll([for (final m in visible) m.key])),
                    run: _run,
                    result: _result,
                    onDismissResult: () => setState(() => _result = null),
                    actions: [
                      CineSelectAction('Remove from shelf', CineIconRole.delete, smart || d == null ? null : () => unawaited(_removePicked(d)), destructive: true),
                    ],
                  ),
                ),
            ],),
          ),
        ),
      ),
    );
  }

  void _step(int dx, int dy) {
    if (_members.isEmpty) return;
    final cur = _focused();
    if (cur < 0) {
      _focusIndex(0);
      return;
    }
    _focusIndex((cur + dx + dy * _perRow).clamp(0, _members.length - 1));
  }

  Future<void> _add(CollectionDetail d) => showAddSeriesSheet(context, collectionId: _id, memberKeys: {for (final m in d.series) '${m.sourceId}\u0000${m.seriesKey}'});

  Widget _actions(BuildContext context, CollectionDetail d, bool smart) {
    final c = context.cine;
    return Padding(
      padding: EdgeInsets.only(bottom: c.space4),
      child: Wrap(spacing: c.space2, runSpacing: c.space2, crossAxisAlignment: WrapCrossAlignment.center, children: [
        if (!smart) CineButton(key: const Key('collection-add'), label: 'Add series', variant: CineButtonVariant.secondary, onPressed: () => unawaited(_add(d))),
        CineButton(key: const Key('collection-edit'), label: 'Edit', variant: CineButtonVariant.quiet, icon: CineIconRole.edit, onPressed: () => unawaited(_edit(d))),
        if (!smart)
          CineButton(
            key: const Key('collection-reorder'),
            label: 'Reorder',
            variant: CineButtonVariant.quiet,
            toggle: true,
            selected: _reorder,
            onPressed: d.series.length < 2 ? null : () => setState(() {
                  _reorder = !_reorder;
                  _select = false;
                  _picked.clear();
                }),
          ),
        CineButton(
          key: const Key('collection-select'),
          label: 'Select',
          variant: CineButtonVariant.quiet,
          toggle: true,
          selected: _select,
          onPressed: _members.isEmpty ? null : () => setState(() {
                _select = !_select;
                _reorder = false;
                _picked.clear();
              }),
        ),
        Builder(
          builder: (ctx) => CineButton(
            key: const Key('collection-more'),
            label: 'More',
            variant: CineButtonVariant.quiet,
            onPressed: () => unawaited(showCineMenu<Object?>(ctx, anchor: cineAnchorRect(ctx), entries: [
              CineMenuEntry<Object?>(label: 'Delete shelf', destructive: true, onSelected: () => unawaited(_delete(d))),
            ],),),
          ),
        ),
      ],),
    );
  }

  Widget _tile(BuildContext context, _Member m, int i, CollectionDetail? d, String apiBase, bool gate, FocusNode node, {Widget? handle}) {
    final s = m.series;
    if (s == null) {
      return CinePoster(
        key: ValueKey('member-${m.key}'),
        title: m.title,
        folio: 'NO LONGER FOLLOWED',
        focusNode: node,
        selectMode: _select,
        selected: _picked.contains(m.key),
        dragHandle: handle,
        onTap: _select ? () => setState(() => _toggle(m)) : () => _open(m),
        onQuickLook: d == null ? null : () => _quickLook(m, d, null),
      );
    }
    return LibraryPoster(
      key: ValueKey('member-${m.key}'),
      series: s,
      coverUrl: followedSeriesCoverUrl(apiBase, s),
      gateOpen: gate,
      selectMode: _select,
      selected: _picked.contains(m.key),
      focusNode: node,
      dragHandle: handle,
      flickerIndex: i,
      onTap: _select ? () => setState(() => _toggle(m)) : () => _open(m),
      onQuickLook: d == null ? null : () => _quickLook(m, d, followedSeriesCoverUrl(apiBase, s)),
    );
  }

  void _toggle(_Member m) {
    if (!_picked.remove(m.key)) _picked.add(m.key);
  }

  Widget _wall(BuildContext context, List<_Member> members, {required bool loading, required CollectionDetail? d, required String apiBase, required bool gate, required List<FocusNode> nodes}) {
    final geo = ShelfGeometry.of(context, ShelfDensity.wall);
    if (loading) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: geo.delegate,
        itemCount: 6,
        itemBuilder: (_, i) => AspectRatio(aspectRatio: 2 / 3, child: CineFlicker(index: i, child: const CineGalleyPlate())),
      );
    }
    if (_reorder && !_smart) {
      return CineReorderableWall<_Member>(
        items: members,
        idOf: (m) => m.key,
        titleOf: (m) => m.title,
        crossAxisCount: geo.perRow,
        aspectRatio: geo.cellWidth / geo.cellHeight,
        spacing: geo.gap,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        onMove: (f, t) => unawaited(_move(f, t)),
        itemBuilder: (ctx, m, i, handle, entries, actions) => Semantics(
          customSemanticsActions: actions,
          child: _tile(ctx, m, i, d, apiBase, gate, nodes[i], handle: handle),
        ),
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: geo.delegate,
      itemCount: members.length,
      itemBuilder: (ctx, i) => _tile(ctx, members[i], i, d, apiBase, gate, nodes[i]),
    );
  }
}

/// The header (cinematic 8.11): the duotone mosaic across the width at 16:9 (the `Hero` target of
/// the plate's match cut) with `scrim.foot`, and on its solid end the kicker, the name set as a
/// masthead, the description and the smart rules as credits.
class _Header extends StatelessWidget {
  const _Header({required this.detail, required this.covers, required this.duo, required this.tint, required this.count, required this.focus});
  final CollectionDetail detail;
  final List<String> covers;
  final Color? duo, tint;
  final int count;
  final FocusNode focus;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final grid = CineGrid.of(context);
    final smart = detail.rules != null;
    final kicker = '${smart ? 'SMART SHELF' : 'SHELF'} · $count SERIES';
    final desc = detail.description?.trim() ?? '';
    return LayoutBuilder(
      builder: (context, box) {
        final h = box.maxWidth * 9 / 16;
        final nameStyle = CineText.style(context, c.typeMasthead);
        final block = 12 + 16 + (nameStyle.fontSize ?? 40) * (nameStyle.height ?? 1.1) + (desc.isEmpty ? 0 : 60) + (smart ? 20 : 0);
        final textOverlay = Padding(
          padding: EdgeInsets.fromLTRB(grid.left, 0, grid.right, c.space4),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            CineStock.raised(Builder(builder: (b) => CineRoleText(kicker, b.cine.typeKicker, color: b.cine.colorInk60))),
            SizedBox(height: c.space2),
            SetHeading(
              detail.name,
              id: 'collection.${detail.id}.header',
              style: CineText.style(context, c.typeMasthead).copyWith(color: c.colorInk100),
              cap: c.typeMasthead.cap,
              level: 1,
              trigger: SetTrigger.signal,
              focusNode: focus,
            ),
            if (desc.isNotEmpty) ...[
              SizedBox(height: c.space2),
              CineMeasureDeck(desc),
            ],
            if (smart) ...[
              SizedBox(height: c.space2),
              CineStock.raised(Builder(builder: (b) => CineRoleText('SMART RULES: ${describeRules(detail.rules!)}', b.cine.typeCredit, color: b.cine.colorInk60))),
            ],
          ],),
        );
        return SizedBox(
          height: h < block + 40 ? block + 40 : h,
          child: Stack(fit: StackFit.expand, children: [
            CineCollectionMosaic(coverUrls: covers, duo: duo, heroTag: ('collection', detail.id), heroOnGestures: defaultTargetPlatform == TargetPlatform.iOS),
            DecoratedBox(decoration: BoxDecoration(gradient: cineScrimFoot(solidAtPx: (h < block + 40 ? block + 40 : h) - block - 24, height: h < block + 40 ? block + 40 : h, tint: tint ?? c.colorAmbientFallbackTint))),
            Align(alignment: Alignment.bottomLeft, child: textOverlay),
          ],),
        );
      },
    );
  }
}

/// The deck under the name, 62 characters to a line.
class CineMeasureDeck extends StatelessWidget {
  const CineMeasureDeck(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: CineText.style(context, c.typeDeck).fontSize! * 0.5 * 62),
      child: CineStock.raised(Builder(builder: (b) => CineRoleText(text, b.cine.typeDeck, color: b.cine.colorInk60, maxLines: 3, overflow: TextOverflow.ellipsis))),
    );
  }
}
