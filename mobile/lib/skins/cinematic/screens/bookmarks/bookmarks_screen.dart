import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/core/keyboard/shortcut_registry.dart';
import 'package:manhwamaniacs/features/auth/providers/session_offline_provider.dart';
import 'package:manhwamaniacs/features/collections/providers/collection_detail_provider.dart';
import 'package:manhwamaniacs/features/content_mode/content_mode_controller.dart';
import 'package:manhwamaniacs/features/downloads/providers/bookmark_outbox_provider.dart';
import 'package:manhwamaniacs/features/library/models/followed_series.dart';
import 'package:manhwamaniacs/features/library/providers/bookmarks_provider.dart';
import 'package:manhwamaniacs/features/library/utils/cover_url.dart';
import 'package:manhwamaniacs/features/reader/models/bookmark.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/feedback.dart';
import 'package:manhwamaniacs/skins/cinematic/navigation.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_image.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_notice.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_radio.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/layout/cine_grid.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/sheet_route.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/toasts.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/bookmarks/marginal_note.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/hub/hub_kit.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/library/library_hub.dart';
import 'package:manhwamaniacs/skins/cinematic/shell/cine_scaffold.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

typedef _Group = ({String sourceId, String seriesKey, String title, String? coverUrl, List<Bookmark> notes});

/// Bookmarks, "Marked passages" (cinematic 8.13, ScreenId `bookmarks`): every bookmark as a marginal
/// note, grouped by series, read from the device first and synced through the bookmark outbox. A
/// note edits in place, a swipe or `Remove` takes a bookmark away with an 8 s Undo.
class BookmarksScreen extends ConsumerStatefulWidget {
  const BookmarksScreen({super.key});

  @override
  ConsumerState<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends ConsumerState<BookmarksScreen> {
  final _mastheadFocus = FocusNode(debugLabel: 'bookmarks-masthead');
  final _scroll = ScrollController();
  final List<FocusNode> _nodes = [];
  final Set<String> _hidden = {};
  String? _filter, _editing, _synced;
  List<Bookmark> _flat = const [];

  @override
  void initState() {
    super.initState();
    unawaited(_flushFirst());
  }

  @override
  void dispose() {
    _mastheadFocus.dispose();
    _scroll.dispose();
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  CineToastsNotifier get _toasts => ref.read(cineToastsProvider.notifier);

  /// Flushes what the outbox holds before the list loads; "Synced 3 bookmarks" after.
  Future<void> _flushFirst() async {
    final outbox = ref.read(bookmarkOutboxControllerProvider);
    final n = await outbox.pendingCount();
    if (n == 0) return;
    await outbox.flush();
    if (!mounted) return;
    ref.invalidate(bookmarksProvider);
    setState(() => _synced = 'Synced $n ${n == 1 ? 'bookmark' : 'bookmarks'}');
  }

  List<FocusNode> _nodesFor(int n) {
    while (_nodes.length < n) {
      _nodes.add(FocusNode(debugLabel: 'note-${_nodes.length}'));
    }
    return _nodes;
  }

  int _focused() {
    for (var i = 0; i < _nodes.length && i < _flat.length; i++) {
      if (_nodes[i].hasFocus) return i;
    }
    return -1;
  }

  void _step(int d) {
    if (_flat.isEmpty) return;
    final cur = _focused();
    final to = (cur < 0 ? (d > 0 ? 0 : _flat.length - 1) : cur + d).clamp(0, _flat.length - 1);
    _nodes[to].requestFocus();
    final ctx = _nodes[to].context;
    if (ctx != null) unawaited(Scrollable.ensureVisible(ctx, duration: CineDur.line, alignment: 0.3));
  }

  // ---- one bookmark ---------------------------------------------------------------------------

  void _open(Bookmark b) {
    final at = b.anchorFraction.toStringAsFixed(3);
    final target = b.mediaType.isNovel
        ? ReaderTarget.novel(b.sourceId, b.seriesKey, b.chapterKey, para: b.anchorIndex, at: at)
        : ReaderTarget.manifest(b.sourceId, b.seriesKey, b.chapterKey, page: b.anchorIndex, at: at);
    readerPrefetchOf(ref).onPress(target);
    enterReader(context, target, entry: ReaderEntry.dip);
  }

  Future<void> _saveNote(Bookmark b, String note) async {
    setState(() => _editing = null);
    if (note == (b.note ?? '').trim()) return;
    try {
      await ref.read(bookmarkOutboxControllerProvider).setNote(b, note);
    } on BookmarkDeletedElsewhere {
      _toasts.error('That bookmark was removed on another device.');
    }
    if (mounted) ref.invalidate(bookmarksProvider);
  }

  Future<void> _remove(Bookmark b) async {
    if (_hidden.contains(b.clientId)) return;
    cineFeedback(context, HapticEvent.deleteConfirm);
    setState(() => _hidden.add(b.clientId));
    final outbox = ref.read(bookmarkOutboxControllerProvider);
    await outbox.remove(b.clientId);
    if (!mounted) return;
    _toasts.action('Bookmark removed', label: 'Undo', onAction: () async {
      await outbox.restore(b);
      if (!mounted) return;
      cineFeedback(context, HapticEvent.undo, sound: SoundEvent.undo);
      setState(_hidden.clear);
      ref.invalidate(bookmarksProvider);
    },);
    ref.invalidate(bookmarksProvider);
  }

  Future<void> _pickSeries(List<_Group> groups) async {
    final picked = await showCineSheet<String>(
      context,
      kicker: 'SERIES',
      title: 'Series',
      builder: (ctx) => Column(children: [
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: CineRadio<String?>(value: null, groupValue: _filter, label: 'All series', onChanged: (_) => Navigator.of(ctx).pop('')),
        ),
        for (final g in groups)
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: CineRadio<String?>(value: '${g.sourceId}\u0000${g.seriesKey}', groupValue: _filter, label: g.title, onChanged: (v) => Navigator.of(ctx).pop(v)),
          ),
      ],),
    );
    if (picked == null || !mounted) return;
    setState(() => _filter = picked.isEmpty ? null : picked);
  }

  Future<void> _reload() async {
    await ref.read(bookmarksProvider.notifier).refresh();
  }

  // ---- build --------------------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final async = ref.watch(bookmarksProvider);
    final scope = ref.watch(contentModeScopeProvider);
    final followed = ref.watch(librarySeriesPickerProvider).valueOrNull ?? const <FollowedSeries>[];
    final apiBase = ref.watch(apiBaseUrlProvider);
    final offline = ref.watch(sessionOfflineProvider);
    final grid = CineGrid.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final swipe = width < 600;
    final two = width >= 900;

    final all = [for (final b in (async.valueOrNull?.bookmarks ?? const <Bookmark>[])) if (!_hidden.contains(b.clientId)) b];
    final inMode = scope.filter(all, (b) => b.sourceId);
    final by = {for (final s in followed) '${s.sourceId}\u0000${s.seriesKey}': s};
    final map = <String, List<Bookmark>>{};
    for (final b in [...inMode]..sort((a, b) => b.createdAt.compareTo(a.createdAt))) {
      map.putIfAbsent('${b.sourceId}\u0000${b.seriesKey}', () => []).add(b);
    }
    final groups = <_Group>[
      for (final e in map.entries)
        (
          sourceId: e.value.first.sourceId,
          seriesKey: e.value.first.seriesKey,
          title: e.value.first.seriesTitle?.trim().isNotEmpty ?? false ? e.value.first.seriesTitle!.trim() : (by[e.key]?.title ?? e.value.first.seriesKey),
          coverUrl: by[e.key] == null ? null : followedSeriesCoverUrl(apiBase, by[e.key]!),
          notes: e.value,
        ),
    ];
    final shown = _filter == null ? groups : [for (final g in groups) if ('${g.sourceId}\u0000${g.seriesKey}' == _filter) g];
    _flat = [for (final g in shown) ...g.notes];
    final nodes = _nodesFor(_flat.length);

    var next = 0;
    Widget groupWidget(_Group g) {
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(
          padding: EdgeInsets.only(top: c.space6, bottom: c.space2),
          child: Row(children: [
            SizedBox(width: 32, height: 48, child: DecoratedBox(decoration: BoxDecoration(border: Border.all(color: c.colorRule2)), child: CineImage(url: g.coverUrl, title: g.title))),
            SizedBox(width: c.space3),
            Expanded(child: Semantics(header: true, child: CineRoleText(g.title, c.typeSubhead, maxLines: 2, overflow: TextOverflow.ellipsis))),
          ],),
        ),
        for (final b in g.notes)
          Builder(builder: (context) {
            final i = next++;
            return MarginalNote(
              key: ValueKey('note-${b.clientId}'),
              bookmark: b,
              editing: _editing == b.clientId,
              swipe: swipe,
              focusNode: nodes[i],
              onOpen: () => _open(b),
              onEdit: () => setState(() => _editing = b.clientId),
              onSaveNote: (n) => unawaited(_saveNote(b, n)),
              onRemove: () => unawaited(_remove(b)),
              onOpenSeries: () => unawaited(context.push(Routes.feature(b.sourceId, b.seriesKey))),
            );
          },),
      ],);
    }

    final slivers = <Widget>[];
    if (groups.length > 1 || _filter != null) {
      slivers.add(SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.fromLTRB(grid.left, 0, grid.right, c.space2),
          child: Align(
            alignment: Alignment.centerLeft,
            child: CineButton(
              key: const Key('bookmarks-filter'),
              label: _filter == null ? 'ALL SERIES ▾' : '${groups.where((g) => '${g.sourceId}\u0000${g.seriesKey}' == _filter).map((g) => g.title).firstOrNull ?? 'SERIES'} ▾',
              variant: CineButtonVariant.quiet,
              size: CineButtonSize.sm,
              onPressed: () => unawaited(_pickSeries(groups)),
            ),
          ),
        ),
      ),);
    }
    if (_synced != null || offline) {
      slivers.add(SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.fromLTRB(grid.left, 0, grid.right, c.space2),
          child: Semantics(
            liveRegion: true,
            child: CineRoleText(offline ? "Changes sync when you're back online" : _synced!, c.typeCaption, color: c.colorInk60, key: const Key('bookmarks-caption')),
          ),
        ),
      ),);
    }
    if (async.isLoading && async.valueOrNull == null) {
      slivers.add(const SliverToBoxAdapter(child: HubGalley()));
    } else if (async.hasError && async.valueOrNull == null) {
      slivers.add(SliverToBoxAdapter(
        child: HubErrorNotice(
          error: async.error!,
          offlineHeadline: "Bookmarks didn't load.",
          errorHeadline: "Bookmarks didn't load.",
          onRetry: () => ref.invalidate(bookmarksProvider),
        ),
      ),);
    } else if (shown.isEmpty) {
      slivers.add(SliverToBoxAdapter(
        child: HubNoticeBox(
          notice: CineNotice(
            key: const Key('bookmarks-empty'),
            tone: CineNoticeTone.empty,
            kicker: 'NO MARKS YET',
            headline: 'No bookmarks yet.',
            deck: 'Press B while reading, or tap the bookmark in the reader.',
            primary: CineNoticeAction('Go to library', () => context.go(Routes.library())),
          ),
        ),
      ),);
    } else if (two) {
      final half = (shown.length + 1) ~/ 2;
      final left = shown.take(half).toList(), right = shown.skip(half).toList();
      slivers.add(SliverPadding(
        padding: EdgeInsets.fromLTRB(grid.left, 0, grid.right, c.space6),
        sliver: SliverToBoxAdapter(
          child: Row(key: const Key('bookmarks-two-columns'), crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: Column(children: [for (final g in left) groupWidget(g)])),
            SizedBox(width: c.space6),
            SizedBox(width: 1, child: DecoratedBox(decoration: BoxDecoration(color: c.colorRule1), child: const SizedBox(height: 400))),
            SizedBox(width: c.space6),
            Expanded(child: Column(children: [for (final g in right) groupWidget(g)])),
          ],),
        ),
      ),);
    } else {
      slivers.add(SliverPadding(
        padding: EdgeInsets.fromLTRB(grid.left, 0, grid.right, c.space6),
        sliver: SliverList.builder(itemCount: shown.length, itemBuilder: (context, i) => groupWidget(shown[i])),
      ),);
    }
    slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 48)));

    return CineScaffold(
      runningTitle: 'Bookmarks',
      contentModeChip: true,
      firstRunNote: false,
      mastheadFocusNode: _mastheadFocus,
      body: RegisteredShortcuts(
        group: 'Bookmarks',
        entries: [
          hubKey('Bookmarks', LogicalKeyboardKey.keyJ, 'Next note', () => _step(1)),
          hubKey('Bookmarks', LogicalKeyboardKey.keyK, 'Previous note', () => _step(-1)),
          hubKey('Bookmarks', LogicalKeyboardKey.enter, 'Open the focused bookmark', () {
            final i = _focused();
            if (i >= 0) _open(_flat[i]);
          }, single: false,),
          hubKey('Bookmarks', LogicalKeyboardKey.keyE, "Edit the focused bookmark's note", () {
            final i = _focused();
            if (i >= 0) setState(() => _editing = _flat[i].clientId);
          }),
          hubKey('Bookmarks', LogicalKeyboardKey.delete, 'Remove the focused bookmark', () {
            final i = _focused();
            if (i >= 0) unawaited(_remove(_flat[i]));
          }, single: false,),
        ],
        child: LibraryHub(
          tab: HubTab.bookmarks,
          masthead: (kicker: 'No. 08 — MARKED PASSAGES', title: 'Bookmarks', deck: 'Exact places you marked, in both readers.'),
          slivers: slivers,
          scrollController: _scroll,
          mastheadFocus: _mastheadFocus,
          onRefresh: _reload,
        ),
      ),
    );
  }
}
