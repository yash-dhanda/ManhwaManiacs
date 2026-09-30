import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/features/auth/providers/session_offline_provider.dart';
import 'package:manhwamaniacs/features/collections/providers/collection_detail_provider.dart' show librarySeriesPickerProvider;
import 'package:manhwamaniacs/features/content_mode/content_mode_controller.dart' show contentModeScopeProvider;
import 'package:manhwamaniacs/features/downloads/providers/bookmark_outbox_provider.dart';
import 'package:manhwamaniacs/features/library/models/followed_series.dart';
import 'package:manhwamaniacs/features/library/providers/bookmarks_provider.dart';
import 'package:manhwamaniacs/features/reader/models/bookmark.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/icons/icon_roles.g.dart';
import 'package:manhwamaniacs/skins/glass/primitives/chip.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/context_menu.dart';
import 'package:manhwamaniacs/skins/glass/primitives/list/swipe_row.dart';
import 'package:manhwamaniacs/skins/glass/primitives/menu.dart';
import 'package:manhwamaniacs/skins/glass/primitives/pull_to_refresh.dart';
import 'package:manhwamaniacs/skins/glass/primitives/skeleton.dart';
import 'package:manhwamaniacs/skins/glass/primitives/states/lens_glyphs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/states/object_lens.dart';
import 'package:manhwamaniacs/skins/glass/primitives/status_capsule.dart';
import 'package:manhwamaniacs/skins/glass/primitives/toast.dart';
import 'package:manhwamaniacs/skins/glass/screens/library/bookmark_row.dart';
import 'package:manhwamaniacs/skins/glass/screens/library/library_common.dart';
import 'package:manhwamaniacs/skins/glass/screens/library/library_keys.dart';
import 'package:manhwamaniacs/skins/glass/screens/library/library_section.dart';
import 'package:manhwamaniacs/skins/glass/shell/global_keys.dart' show useGlassRefresh;
import 'package:manhwamaniacs/skins/glass/transitions/dive.dart';

/// Bookmarks (glass 8.20): a plain list read off the device first and synced through the bookmark outbox, the `?source=&series=` filter
/// chip, swipe to remove with Undo, and the long-press menu (Open, Add note, Remove, Copy link).
class GlassBookmarksPage extends ConsumerStatefulWidget {
  const GlassBookmarksPage({super.key});

  @override
  ConsumerState<GlassBookmarksPage> createState() => _GlassBookmarksPageState();
}

class _GlassBookmarksPageState extends ConsumerState<GlassBookmarksPage> {
  final GlassPullToRefreshController _pull = GlassPullToRefreshController();
  final Set<String> _hidden = {};
  Set<String> _known = {};
  String? _focusedId;
  bool _syncing = false;
  VoidCallback? _offRefresh;

  @override
  void initState() {
    super.initState();
    _offRefresh = useGlassRefresh(() => unawaited(_pull.refresh()));
    unawaited(_flushFirst());
  }

  @override
  void dispose() {
    _offRefresh?.call();
    _pull.dispose();
    super.dispose();
  }

  Future<void> _flushFirst() async {
    final outbox = ref.read(bookmarkOutboxControllerProvider);
    final n = await outbox.pendingCount();
    if (n == 0 || !mounted) return;
    setState(() => _syncing = true);
    await outbox.flush();
    if (!mounted) return;
    ref.invalidate(bookmarksProvider);
    setState(() => _syncing = false);
  }

  Future<RefreshResult> _refresh() async {
    await ref.read(bookmarksProvider.notifier).refresh();
    return RefreshResult.changed;
  }

  String _link(Bookmark b) {
    final at = b.anchorFraction.toStringAsFixed(3);
    return b.mediaType.isNovel ? Routes.novel(b.sourceId, b.seriesKey, b.chapterKey, {'para': b.anchorIndex, 'at': at}) : Routes.reader(b.sourceId, b.seriesKey, b.chapterKey, {'page': b.anchorIndex, 'at': at});
  }

  void _open(Bookmark b, Rect from) => unawaited(enterReader(context, ref, _link(b), fromRect: from));

  Future<void> _remove(Bookmark b) async {
    if (_hidden.contains(b.clientId)) return;
    setState(() => _hidden.add(b.clientId));
    final outbox = ref.read(bookmarkOutboxControllerProvider);
    await outbox.remove(b.clientId);
    if (!mounted) return;
    showGlassToast(ref, GlassToastSpec('Bookmark removed', undo: () => unawaited(_restore(b))));
    ref.invalidate(bookmarksProvider);
  }

  Future<void> _restore(Bookmark b) async {
    await ref.read(bookmarkOutboxControllerProvider).restore(b);
    if (!mounted) return;
    setState(() => _hidden.remove(b.clientId));
    ref.invalidate(bookmarksProvider);
  }

  void _note(Bookmark b) {
    final uri = Uri.parse(GoRouterState.of(context).uri.toString());
    GoRouter.of(context).go(uri.replace(queryParameters: {...uri.queryParameters, 'sheet': 'note', 'bookmark': b.clientId}).toString());
  }

  void _menu(Bookmark b, String title, Rect from) {
    unawaited(showGlassContextMenu(context, sourceRect: from, preview: const SizedBox(width: 10, height: 10), kind: GlassPreviewKind.row, title: title, entries: [
      GlassMenuEntry(label: 'Open', onSelected: () => _open(b, from)),
      GlassMenuEntry(label: (b.note ?? '').isEmpty ? 'Add note' : 'Edit note', onSelected: () => _note(b)),
      GlassMenuEntry(label: 'Remove', destructive: true, onSelected: () => unawaited(_remove(b))),
      GlassMenuEntry(label: 'Copy link', onSelected: () {
        unawaited(Clipboard.setData(ClipboardData(text: _link(b))));
        showGlassToast(ref, const GlassToastSpec('Link copied'));
      },),
    ],),);
  }

  void _clearFilter() {
    final uri = Uri.parse(GoRouterState.of(context).uri.toString());
    final q = {...uri.queryParameters}..remove('source')..remove('series');
    GoRouter.of(context).replace<void>(uri.replace(queryParameters: q.isEmpty ? null : q).toString());
  }

  Widget _lens(LensSituation s, String title, {String? description, LensAction? primary, GlassLensTone tone = GlassLensTone.empty}) =>
      SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.symmetric(vertical: 32), child: GlassObjectLens(situation: s, title: title, description: description, tone: tone, primary: primary)));

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(bookmarksProvider);
    final scope = ref.watch(contentModeScopeProvider);
    final followed = ref.watch(librarySeriesPickerProvider).valueOrNull ?? const <FollowedSeries>[];
    final offline = ref.watch(sessionOfflineProvider);
    final params = GoRouterState.of(context).uri.queryParameters;
    final fSource = params['source'], fSeries = params['series'];
    final all = [for (final b in (async.valueOrNull?.bookmarks ?? const <Bookmark>[])) if (!_hidden.contains(b.clientId)) b];
    // A bookmark that was there and is gone without us removing it was removed on another device.
    final ids = {for (final b in all) b.clientId};
    if (_known.isNotEmpty && async.hasValue) {
      final gone = _known.difference(ids).difference(_hidden);
      if (gone.isNotEmpty) WidgetsBinding.instance.addPostFrameCallback((_) => mounted ? showGlassToast(ref, const GlassToastSpec('That bookmark was removed on another device')) : null);
    }
    if (async.hasValue) _known = ids;
    final inMode = scope.filter(all, (b) => b.sourceId);
    final by = {for (final s in followed) '${s.sourceId}|${s.seriesKey}': s};
    final filtered = [for (final b in inMode) if (fSource == null || fSeries == null || (b.sourceId == fSource && b.seriesKey == fSeries)) b]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    String titleOf(Bookmark b) => (b.seriesTitle?.trim().isNotEmpty ?? false) ? b.seriesTitle!.trim() : (by['${b.sourceId}|${b.seriesKey}']?.title ?? b.seriesKey);
    final filterTitle = fSource != null && fSeries != null ? (by['$fSource|$fSeries']?.title ?? filtered.firstOrNull?.seriesTitle ?? fSeries) : null;

    final slivers = <Widget>[
      if (filterTitle != null)
        SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.only(bottom: 12), child: Align(alignment: Alignment.centerLeft, child: GlassChip(label: filterTitle, kind: GlassChipKind.input, onRemove: _clearFilter)))),
      if (_syncing) const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.only(bottom: 12), child: Align(alignment: Alignment.centerLeft, child: GlassStatusCapsule(kind: GlassStatusKind.syncing)))),
    ];
    if (async.isLoading && !async.hasValue) {
      slivers.add(SliverToBoxAdapter(child: GlassSkeletonGroup(child: Column(children: [for (var i = 0; i < 5; i++) Padding(padding: const EdgeInsets.only(bottom: 10), child: GlassSkeleton(height: 84, index: i))]))));
    } else if (async.hasError && !async.hasValue) {
      slivers.add(_lens(LensSituation.loadError, "Couldn't load your bookmarks", tone: GlassLensTone.error, primary: LensAction('Try again', () => ref.invalidate(bookmarksProvider))));
    } else if (filtered.isEmpty) {
      slivers.add(_lens(LensSituation.bookmarks, 'No bookmarks yet', description: 'Press B while reading, or use the bookmark button, to save the exact spot.', primary: LensAction('Go to library', () => GoRouter.of(context).go(Routes.library()))));
    } else {
      slivers.add(SliverToBoxAdapter(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 880),
            child: GlassSwipeGroup(
              child: Column(children: [
                if (offline) Padding(padding: const EdgeInsets.only(bottom: 8), child: GlassLabel("Some bookmarks are only on the server; they show when you're online", role: gt.typeFootnote, color: gt.colorLabel3, maxLines: 3)),
                for (final b in filtered)
                  GlassSwipeRow(
                    key: ValueKey('bm-${b.clientId}'),
                    name: titleOf(b),
                    trailing: [
                      SwipeAction(id: 'remove', label: 'Remove', glyph: roleIcon(GlassIconRole.delete), tone: SwipeTone.danger, destructive: true, run: () => _remove(b)),
                    ],
                    child: Focus(
                      canRequestFocus: false,
                      onFocusChange: (f) {
                        if (f) _focusedId = b.clientId;
                      },
                      child: BookmarkRow(
                        bookmark: b,
                        title: titleOf(b),
                        coverUrl: by['${b.sourceId}|${b.seriesKey}']?.coverUrl,
                        onOpen: () => _open(b, Rect.zero),
                        onMenu: (from) => _menu(b, titleOf(b), from),
                      ),
                    ),
                  ),
              ],),
            ),
          ),
        ),
      ),);
    }
    slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 24)));

    Bookmark? focused() => filtered.where((b) => b.clientId == _focusedId).firstOrNull;
    return LibraryKeys(
      group: 'Bookmarks',
      section: LibrarySection.bookmarks,
      bindings: [
        LibraryKey(description: 'Remove the focused bookmark', keys: const ['Delete'], match: kKey(LogicalKeyboardKey.delete), action: () {
          final b = focused();
          if (b != null) unawaited(_remove(b));
        },),
        LibraryKey(description: '', keys: const [], match: kKey(LogicalKeyboardKey.backspace), action: () {
          final b = focused();
          if (b != null) unawaited(_remove(b));
        },),
        LibraryKey(description: 'Move through the list', keys: const ['↑', '↓'], match: kKey(LogicalKeyboardKey.arrowDown), action: () => FocusManager.instance.primaryFocus?.nextFocus()),
        LibraryKey(description: '', keys: const [], match: kKey(LogicalKeyboardKey.arrowUp), action: () => FocusManager.instance.primaryFocus?.previousFocus()),
      ],
      child: LibrarySectionFrame(
        section: LibrarySection.bookmarks,
        physics: kGlassRefreshPhysics,
        refreshSliver: GlassPullToRefresh(controller: _pull, onRefresh: _refresh),
        slivers: slivers,
      ),
    );
  }
}
