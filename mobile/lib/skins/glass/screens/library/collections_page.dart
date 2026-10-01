import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/features/circle/models/circle_models.dart' show SharedShelf;
import 'package:manhwamaniacs/features/collections/providers/collection_detail_provider.dart' show librarySeriesPickerProvider;
import 'package:manhwamaniacs/features/collections/providers/collection_order.dart';
import 'package:manhwamaniacs/features/collections/providers/collection_sort_provider.dart';
import 'package:manhwamaniacs/features/collections/providers/collections_provider.dart';
import 'package:manhwamaniacs/features/collections/providers/shared_collections_provider.dart';
import 'package:manhwamaniacs/features/collections/utils/collection_sorting.dart';
import 'package:manhwamaniacs/features/content_mode/content_mode_controller.dart' show ContentModeScope, contentModeScopeProvider;
import 'package:manhwamaniacs/features/library/models/collection.dart';
import 'package:manhwamaniacs/features/library/models/followed_series.dart';
import 'package:manhwamaniacs/features/library/utils/smart_shelf.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/icons/icon_roles.g.dart';
import 'package:manhwamaniacs/skins/glass/motion.dart';
import 'package:manhwamaniacs/skins/glass/motion_names.g.dart';
import 'package:manhwamaniacs/skins/glass/primitives/cards/collection_card.dart' show GlassCollectionCardState;
import 'package:manhwamaniacs/skins/glass/primitives/common.dart' show gt;
import 'package:manhwamaniacs/skins/glass/primitives/list/reorder_list.dart';
import 'package:manhwamaniacs/skins/glass/primitives/menu.dart';
import 'package:manhwamaniacs/skins/glass/primitives/pull_to_refresh.dart';
import 'package:manhwamaniacs/skins/glass/primitives/search_field.dart';
import 'package:manhwamaniacs/skins/glass/primitives/skeleton.dart';
import 'package:manhwamaniacs/skins/glass/primitives/states/lens_glyphs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/states/object_lens.dart';
import 'package:manhwamaniacs/skins/glass/primitives/toast.dart';
import 'package:manhwamaniacs/skins/glass/screens/library/collection_card.dart';
import 'package:manhwamaniacs/skins/glass/screens/library/library_common.dart';
import 'package:manhwamaniacs/skins/glass/screens/library/library_keys.dart';
import 'package:manhwamaniacs/skins/glass/screens/library/library_section.dart';
import 'package:manhwamaniacs/skins/glass/shell/glass_scaffold.dart' show GlassBarAction;
import 'package:manhwamaniacs/skins/glass/shell/global_keys.dart' show registerSearchFocus, useGlassRefresh;
import 'package:manhwamaniacs/skins/glass/type.dart' show GlassText;

/// Collections (glass 8.18): the count line, "+" New collection, a search well, the sort menu, and collection cards (one column on
/// phones, two on tablet frames, three from 1280 px). Auto shelves are computed on the device; shared shelves carry a friend marker.
class GlassCollectionsPage extends ConsumerStatefulWidget {
  const GlassCollectionsPage({super.key});

  @override
  ConsumerState<GlassCollectionsPage> createState() => _GlassCollectionsPageState();
}

class _GlassCollectionsPageState extends ConsumerState<GlassCollectionsPage> {
  final TextEditingController _search = TextEditingController();
  final FocusNode _searchFocus = FocusNode(debugLabel: 'collections-search');
  final GlassPullToRefreshController _pull = GlassPullToRefreshController();
  final Map<int, GlobalKey<GlassCollectionCardState>> _keys = {};
  /// The ids already shown; a card whose id arrives later (a new collection) drops in (Card drop). Null before the first list.
  Set<int>? _known;
  VoidCallback? _offSearch, _offRefresh;

  @override
  void initState() {
    super.initState();
    _offSearch = registerSearchFocus(_searchFocus);
    _offRefresh = useGlassRefresh(() => unawaited(_pull.refresh()));
  }

  @override
  void dispose() {
    _offSearch?.call();
    _offRefresh?.call();
    _search.dispose();
    _searchFocus.dispose();
    _pull.dispose();
    super.dispose();
  }

  Future<RefreshResult> _refresh() async {
    await ref.read(collectionsProvider.notifier).refresh();
    return RefreshResult.changed;
  }

  void _openSheet(String id) {
    final uri = Uri.parse(GoRouterState.of(context).uri.toString());
    GoRouter.of(context).go(uri.replace(queryParameters: {...uri.queryParameters, 'sheet': id}).toString());
  }

  void _sortMenu(Rect anchor) {
    final cur = ref.read(collectionSortProvider);
    unawaited(showGlassMenu(context, anchor: anchor, title: 'Sort', entries: [
      for (final s in CollectionSort.values) GlassMenuEntry(label: collectionSortLabel(s), checked: cur == s, onSelected: () => ref.read(collectionSortProvider.notifier).state = s),
    ],),);
  }

  Future<void> _open(Collection c) async {
    final key = _keys[c.id];
    // Reduce Motion: the card stays at rest; the detail's header fades its fan in (Fan open, 150 ms fade).
    if (!GlassMotion.isReduced()) unawaited(key?.currentState?.fanOpen());
    await GoRouter.of(context).push<void>(Routes.collection(c.id));
    unawaited(key?.currentState?.fanClose());
  }

  Future<void> _reorder(List<Collection> shown, int from, int to) async {
    final moved = [...shown];
    final item = moved.removeAt(from);
    moved.insert(to.clamp(0, moved.length), item);
    final ok = await ref.read(collectionOrderProvider).collections(shown, moved);
    if (!ok && mounted) showGlassToast(ref, const GlassToastSpec("Couldn't save the order", kind: GlassToastKind.error));
  }

  List<String> _coversOf(Collection c, List<FollowedSeries> followed, ContentModeScope scope) {
    if (!c.smart) return c.previewCovers;
    final members = evaluateShelf(c.rules!, followed, contentKindOf: (s) => scope.novelsEnabled ? scope.modeOf(s.sourceId).name : null);
    return [for (final s in members.take(4)) s.coverUrl];
  }

  Widget _lens(LensSituation s, String title, {String? description, LensAction? primary, GlassLensTone tone = GlassLensTone.empty}) =>
      SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.symmetric(vertical: 32), child: GlassObjectLens(situation: s, title: title, description: description, tone: tone, primary: primary)));

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(collectionsProvider);
    final sort = ref.watch(collectionSortProvider);
    final query = ref.watch(collectionSearchProvider);
    final scope = ref.watch(contentModeScopeProvider);
    final followed = ref.watch(librarySeriesPickerProvider).valueOrNull ?? const <FollowedSeries>[];
    final shared = ref.watch(sharedCollectionsProvider).valueOrNull;
    final frame = GlassFrame.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final cols = frame == GlassFrameKind.phone ? 1 : (width >= 1280 ? 3 : 2);
    final all = async.valueOrNull ?? const <Collection>[];
    final known = _known;
    if (async.hasValue) _known = {...?known, for (final c in all) c.id};
    final dropping = known == null ? const <int>{} : {for (final c in all) if (!known.contains(c.id)) c.id};
    final shown = sortCollections(filterCollections(all, query), sort);
    final withMe = shared?.sharedWithMe ?? const <SharedShelf>[];
    final sharedNames = <int, String>{
      for (final s in shared?.collections ?? const <SharedShelf>[])
        if (s.shared != null && s.shared!.members.isNotEmpty) s.id: s.shared!.members.first.name,
    };

    final List<Widget> slivers;
    if (async.isLoading && all.isEmpty) {
      slivers = [
        SliverToBoxAdapter(
          child: GlassSkeletonGroup(child: Column(children: [for (var i = 0; i < 4; i++) Padding(padding: const EdgeInsets.only(bottom: 12), child: GlassSkeleton(height: 136, radius: 20, index: i))])),
        ),
      ];
    } else if (async.hasError && all.isEmpty) {
      slivers = [_lens(LensSituation.loadError, "Couldn't load your collections", tone: GlassLensTone.error, primary: LensAction('Try again', () => unawaited(ref.read(collectionsProvider.notifier).refresh())))];
    } else if (all.isEmpty && withMe.isEmpty) {
      slivers = [_lens(LensSituation.collection, 'No collections yet', description: 'Group your series by theme, mood or reading list.', primary: LensAction('Create your first collection', () => _openSheet('collection-new')))];
    } else {
      slivers = [
        if (all.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GlassSearchField(variant: GlassSearchVariant.filter, controller: _search, focusNode: _searchFocus, placeholder: 'Search collections', onQuery: (v) => ref.read(collectionSearchProvider.notifier).state = v),
            ),
          ),
        if (shown.isEmpty && all.isNotEmpty)
          _lens(LensSituation.nothingFound, 'No collections match your search')
        else if (sort == CollectionSort.custom && query.trim().isEmpty && cols == 1)
          SliverToBoxAdapter(
            child: GlassReorderList<Collection>(
              items: shown,
              nameOf: (c) => c.name,
              onReorder: (a, b) => unawaited(_reorder(shown, a, b)),
              itemBuilder: (context, c, i, info) => Padding(padding: const EdgeInsets.only(bottom: 12), child: _card(c, followed, scope, sharedNames, width - 2 * GlassFrame.screenMargin(context), dropping)),
            ),
          )
        else
          SliverLayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.crossAxisExtent;
              final cardW = (w - 12 * (cols - 1)) / cols;
              return SliverToBoxAdapter(
                child: Wrap(spacing: 12, runSpacing: 12, children: [for (final c in shown) _card(c, followed, scope, sharedNames, cardW, dropping)]),
              );
            },
          ),
        // Others' shared shelves (mobile/43, glass 8.18, 9.3.3).
        if (withMe.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 20, bottom: 4),
              child: Semantics(header: true, headingLevel: 2, child: GlassText('From your Circle', role: gt.typeTitle3)),
            ),
          ),
        if (withMe.isNotEmpty)
          SliverLayoutBuilder(
            builder: (context, constraints) {
              final cardW = (constraints.crossAxisExtent - 12 * (cols - 1)) / cols;
              return SliverPadding(
                padding: const EdgeInsets.only(top: 12),
                sliver: SliverToBoxAdapter(
                  child: Wrap(spacing: 12, runSpacing: 12, children: [
                    for (final s in withMe)
                      LibraryCollectionCard(
                        collection: Collection(id: s.id, name: s.name, seriesCount: s.seriesCount, sortOrder: 0, previewCovers: s.previewCovers),
                        covers: s.previewCovers,
                        sharedWith: s.owner?.name ?? 'a friend',
                        width: cardW,
                        onTap: () => unawaited(GoRouter.of(context).push<void>(Routes.collection(s.id))),
                      ),
                  ],),
                ),
              );
            },
          ),
      ];
    }

    final n = all.length;
    return LibraryKeys(
      group: 'Collections',
      section: LibrarySection.collections,
      bindings: [
        LibraryKey(description: 'New collection', keys: const ['n'], single: true, match: kChar('n'), action: () => _openSheet('collection-new')),
        LibraryKey(description: 'Move through the cards', keys: const ['↑', '↓'], match: kKey(LogicalKeyboardKey.arrowDown), action: () => FocusManager.instance.primaryFocus?.focusInDirection(TraversalDirection.down)),
        LibraryKey(description: '', keys: const [], match: kKey(LogicalKeyboardKey.arrowUp), action: () => FocusManager.instance.primaryFocus?.focusInDirection(TraversalDirection.up)),
        LibraryKey(description: '', keys: const [], match: kKey(LogicalKeyboardKey.arrowRight), action: () => FocusManager.instance.primaryFocus?.focusInDirection(TraversalDirection.right)),
        LibraryKey(description: '', keys: const [], match: kKey(LogicalKeyboardKey.arrowLeft), action: () => FocusManager.instance.primaryFocus?.focusInDirection(TraversalDirection.left)),
      ],
      child: LibrarySectionFrame(
        section: LibrarySection.collections,
        refreshSliver: GlassPullToRefresh(controller: _pull, onRefresh: _refresh),
        physics: kGlassRefreshPhysics,
        countLine: n == 0 ? 'Group your series by theme, mood or reading list.' : (n == 1 ? '1 collection' : '$n collections'),
        trailing: [GlassBarAction(id: 'new-collection', label: 'New collection', glyph: roleGlyph(GlassIconRole.edit), onPress: () => _openSheet('collection-new'))],
        overflow: [
          GlassMenuEntry(label: 'New collection', onSelected: () => _openSheet('collection-new')),
          GlassMenuEntry(label: 'Sort', onSelected: () => _sortMenu(Rect.fromLTWH(MediaQuery.sizeOf(context).width - 24, 80, 1, 1))),
          GlassMenuEntry(label: 'Refresh', onSelected: () => unawaited(_pull.refresh())),
        ],
        slivers: slivers,
      ),
    );
  }

  Widget _card(Collection c, List<FollowedSeries> followed, ContentModeScope scope, Map<int, String> sharedNames, double width, Set<int> dropping) {
    final key = _keys.putIfAbsent(c.id, GlobalKey<GlassCollectionCardState>.new);
    return _CardDrop(
      key: ValueKey('collection-${c.id}'),
      drop: dropping.contains(c.id),
      child: LibraryCollectionCard(
        cardKey: key,
        collection: c,
        covers: _coversOf(c, followed, scope),
        sharedWith: sharedNames[c.id],
        width: width,
        onTap: () => unawaited(_open(c)),
      ),
    );
  }
}

/// Card drop (glass 4.10, 8.18): a new collection card lands in the list from 24 px above at scale 0.9 on `springCelebrate`; under
/// reduced motion a 150 ms fade. Cards already shown mount at rest.
class _CardDrop extends StatefulWidget {
  const _CardDrop({super.key, required this.drop, required this.child});
  final bool drop;
  final Widget child;

  @override
  State<_CardDrop> createState() => _CardDropState();
}

class _CardDropState extends State<_CardDrop> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController.unbounded(vsync: this, value: widget.drop ? 0 : 1);

  @override
  void initState() {
    super.initState();
    if (widget.drop) unawaited(GlassMotion.play(MotionName.cardDrop, controller: _c, target: 1));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        child: widget.child,
        builder: (context, child) {
          final t = _c.value;
          return Opacity(
            opacity: t.clamp(0.0, 1.0),
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..translateByDouble(0, -24 * (1 - t), 0, 1)
                ..scaleByDouble(0.9 + 0.1 * t, 0.9 + 0.1 * t, 1, 1),
              child: child,
            ),
          );
        },
      );
}
