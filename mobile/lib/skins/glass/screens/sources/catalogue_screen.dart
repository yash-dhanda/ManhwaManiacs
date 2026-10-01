import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' hide ShortcutRegistry;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/core/keyboard/shortcut_registry.dart';
import 'package:manhwamaniacs/features/library/providers/device_online_provider.dart';
import 'package:manhwamaniacs/features/settings/providers/settings_provider.dart';
import 'package:manhwamaniacs/features/sources/models/source.dart';
import 'package:manhwamaniacs/features/sources/providers/discover_providers.dart';
import 'package:manhwamaniacs/features/sources/providers/source_pins_provider.dart';
import 'package:manhwamaniacs/features/sources/providers/sources_provider.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/menu.dart';
import 'package:manhwamaniacs/skins/glass/primitives/poster.dart';
import 'package:manhwamaniacs/skins/glass/primitives/pull_to_refresh.dart';
import 'package:manhwamaniacs/skins/glass/primitives/search_field.dart';
import 'package:manhwamaniacs/skins/glass/primitives/skeleton.dart';
import 'package:manhwamaniacs/skins/glass/primitives/status_capsule.dart';
import 'package:manhwamaniacs/skins/glass/primitives/toast.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/home_actions.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/home_common.dart';
import 'package:manhwamaniacs/skins/glass/screens/search/search_states.dart' show isNetworkDown, isRateLimited, retryAfterOf;
import 'package:manhwamaniacs/skins/glass/screens/sources/catalogue_header.dart';
import 'package:manhwamaniacs/skins/glass/screens/sources/catalogue_keys.dart';
import 'package:manhwamaniacs/skins/glass/screens/sources/catalogue_states.dart';
import 'package:manhwamaniacs/skins/glass/screens/sources/freshness_label.dart';
import 'package:manhwamaniacs/skins/glass/screens/sources/genre_chip.dart';
import 'package:manhwamaniacs/skins/glass/screens/sources/mode_pager.dart';
import 'package:manhwamaniacs/skins/glass/screens/sources/novel_shelf.dart';
import 'package:manhwamaniacs/skins/glass/screens/sources/opening_lens.dart';
import 'package:manhwamaniacs/skins/glass/screens/sources/top_capsule.dart';
import 'package:manhwamaniacs/skins/glass/shell/glass_scaffold.dart';

/// `/sources/:sourceId` (glass 8.11): the catalogue of one source.
class GlassCatalogueScreen extends ConsumerStatefulWidget {
  const GlassCatalogueScreen({super.key, required this.sourceId, this.mode, this.genre, this.q});
  final String sourceId;
  final String? mode;
  final String? genre;
  final String? q;

  @override
  ConsumerState<GlassCatalogueScreen> createState() => _GlassCatalogueScreenState();
}

class _GlassCatalogueScreenState extends ConsumerState<GlassCatalogueScreen> {
  final TextEditingController _search = TextEditingController();
  final FocusNode _searchFocus = FocusNode(debugLabel: 'catalogue search');
  final GlassPullToRefreshController _refresh = GlassPullToRefreshController();
  ScrollPosition? _pos;
  final Object _token = Object();
  late final ShortcutRegistry _shortcuts;
  Timer? _debounce;
  Timer? _tick;
  Timer? _retry;
  bool _top = false;
  String? _retryFor;

  String get _id => widget.sourceId;

  @override
  void initState() {
    super.initState();
    _shortcuts = ref.read(shortcutRegistryProvider.notifier);
    _search.text = widget.q ?? '';
    _tick = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
    Future.microtask(() {
      if (!mounted) return;
      _shortcuts.register(_token, catalogueShortcutEntries());
      ref.read(sourceBrowseQueryProvider(_id).notifier).update((s) => s.copyWith(search: widget.q ?? '', sort: widget.mode ?? s.sort, genre: widget.genre ?? ''));
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _tick?.cancel();
    _retry?.cancel();
    _search.dispose();
    _searchFocus.dispose();
    _refresh.dispose();
    final reg = _shortcuts;
    final t = _token;
    Future.microtask(() => reg.unregister(t));
    super.dispose();
  }

  bool _onScroll(ScrollNotification n) {
    if (n.depth != 0) return false;
    final p = n.metrics;
    final show = p.pixels > 400;
    if (show != _top) setState(() => _top = show);
    // The next page is fetched once the scroll passes 70 percent of the extent.
    if (p.maxScrollExtent > 0 && p.pixels / p.maxScrollExtent > 0.7) unawaited(ref.read(sourceBrowseProvider(_id).notifier).loadMore());
    return false;
  }

  void _url({String? mode, String? genre, String? q}) {
    final cur = ref.read(sourceBrowseQueryProvider(_id));
    final m = mode ?? cur.sort;
    final g = genre ?? cur.genre;
    final s = q ?? cur.search;
    try {
      GoRouter.of(context).replace<void>(Routes.source(_id, {'mode': m == 'default' ? null : m, 'genre': (g == null || g.isEmpty) ? null : g, 'q': s.isEmpty ? null : s}));
    } catch (_) {}
  }

  void _setQuery(SourceBrowseQuery Function(SourceBrowseQuery) f) => ref.read(sourceBrowseQueryProvider(_id).notifier).update(f);

  Future<RefreshResult> _doRefresh() async {
    await ref.read(sourceBrowseProvider(_id).notifier).refresh();
    return RefreshResult.changed;
  }

  void _stepMode(List<SourceBrowseMode> modes, int d) {
    if (modes.isEmpty) return;
    final cur = ref.read(sourceBrowseQueryProvider(_id)).sort;
    final i = modes.indexWhere((m) => m.id == cur);
    final next = modes[((i < 0 ? 0 : i) + d).clamp(0, modes.length - 1)];
    _setQuery((q) => q.copyWith(sort: next.id));
    _url(mode: next.id);
  }

  @override
  Widget build(BuildContext context) {
    final id = _id;
    final sources = ref.watch(sourcesListProvider).valueOrNull;
    final source = sources?.where((s) => s.id == id).firstOrNull;
    final browse = ref.watch(sourceBrowseProvider(id));
    final query = ref.watch(sourceBrowseQueryProvider(id));
    final modes = ref.watch(sourceBrowseModesProvider(id)).valueOrNull ?? const <SourceBrowseMode>[];
    final genres = ref.watch(sourceGenresProvider(id)).valueOrNull ?? const [];
    final online = ref.watch(deviceOnlineProvider).valueOrNull ?? true;
    final gateOpen = ref.watch(matureContentProvider).valueOrNull ?? false;
    final state = browse.valueOrNull;
    final err = browse.hasError ? browse.error : null;
    final code = err is ApiError ? err.code : null;
    final margin = GlassFrame.screenMargin(context);
    final phone = GlassFrame.of(context) == GlassFrameKind.phone;
    final searching = query.search.isNotEmpty;
    final name = source?.name ?? id;
    final pinned = ref.watch(sourcePinsProvider).valueOrNull?.contains(id) ?? false;
    final fresh = glassFreshness(state?.cache, DateTime.now(), offline: !online && state != null);
    final total = state?.total ?? 0;

    Widget content;
    if (code == 'source_not_found' || (sources != null && source == null && err != null && !(gateOpen == false && false))) {
      content = const CatalogueUnavailableLens(kind: CatalogueUnavailable.notFound);
    } else if (source != null && source.mature && !gateOpen) {
      content = const CatalogueUnavailableLens(kind: CatalogueUnavailable.gated);
    } else if (!(source?.browsable ?? true) && !searching || code == 'source_not_browsable') {
      content = const CatalogueUnavailableLens(kind: CatalogueUnavailable.notBrowsable);
    } else if (browse.isLoading && state == null) {
      content = OpeningLens(sourceId: id, name: name, iconUrl: source?.iconUrl);
    } else if (err != null && state == null) {
      if (isRateLimited(err)) {
        _scheduleRetry(err);
        content = Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Align(alignment: Alignment.centerLeft, child: GlassStatusCapsule(kind: GlassStatusKind.rateLimit, retryInSeconds: retryAfterOf(err))));
      } else if (isNetworkDown(err) || !online) {
        content = const CatalogueOfflineLens();
      } else {
        content = CatalogueErrorLens(message: err is AppError ? err.userMessage : null, onRetry: () => ref.invalidate(sourceBrowseProvider(id)));
      }
    } else if (state != null && state.items.isEmpty) {
      content = CatalogueEmptyLens(q: searching ? query.search : null);
    } else if (state != null) {
      final w = MediaQuery.sizeOf(context).width - 2 * margin;
      final scale = MediaQuery.textScalerOf(context).scale(1);
      var cols = phone ? 3 : (w / 160).floor().clamp(3, 8);
      if (scale >= 1.9) cols = 2;
      final posterW = (w - 12 * (cols - 1)) / cols;
      final novel = source?.contentKind == kNovelContentKind;
      content = Column(
        children: [
          if (novel)
            NovelShelf(items: state.items, sourceId: id)
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final s in state.items)
                  SizedBox(
                    width: posterW,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GlassPoster(cover: HomeCoverImage(url: s.coverUrl, width: posterW), title: s.title, width: posterW, onTap: () => unawaited(openSeries(ref, id, s.id))),
                        const SizedBox(height: 6),
                        GlassLabel(s.title, role: gt.typeFootnote, wght: 600, maxLines: 2),
                      ],
                    ),
                  ),
              ],
            ),
          const SizedBox(height: 16),
          if (state.isLoadingMore)
            const GlassSkeletonGroup(child: GlassSkeleton(width: 120, height: 14, radius: 7))
          else if (state.loadMoreFailed)
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [GlassLabel("Couldn't load more", role: gt.typeFootnote, color: gt.colorLabel2), GlassButton(label: 'Retry', variant: GlassButtonVariant.plain, size: GlassButtonSize.small, onPressed: () => unawaited(ref.read(sourceBrowseProvider(id).notifier).loadMore()))])
          else if (!online && state.hasNext)
            Center(child: GlassLabel('More needs a connection', role: gt.typeFootnote, color: gt.colorLabel2))
          else if (!state.hasNext)
            Center(child: GlassLabel('End of results', role: gt.typeFootnote, color: gt.colorLabel3)),
        ],
      );
    } else {
      content = const SizedBox.shrink();
    }

    final browsableNow = source?.browsable ?? true;
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CatalogueHeader(
          sourceId: id,
          name: name,
          iconUrl: source?.iconUrl,
          countLine: searching ? '$total results for “${query.search}”' : '$total series · ${modes.where((m) => m.id == query.sort).map((m) => m.label).firstOrNull ?? 'Latest'}',
          freshness: fresh,
          health: source?.health,
        ),
        const SizedBox(height: 12),
        GlassSearchField(variant: GlassSearchVariant.filter, controller: _search, focusNode: _searchFocus, placeholder: 'Search this source', onQuery: (v) {
          _debounce?.cancel();
          _debounce = Timer(const Duration(milliseconds: 300), () {
            if (!mounted) return;
            _setQuery((q) => q.copyWith(search: v.trim()));
            _url(q: v.trim());
          });
        },),
        if (!searching && browsableNow && modes.isNotEmpty) ...[
          const SizedBox(height: 10),
          ModeStrip(modes: modes, selected: query.sort, onSelect: (m) {
            _setQuery((q) => q.copyWith(sort: m));
            _url(mode: m);
          },),
        ],
        if (genres.isNotEmpty) ...[
          const SizedBox(height: 8),
          Align(alignment: Alignment.centerLeft, child: GenreChip(genres: genres, selected: query.genre, onSelect: (g) {
            _setQuery((q) => q.copyWith(genre: g));
            _url(genre: g);
          },),),
        ],
        const SizedBox(height: 16),
        ModeSwipe(onSwipe: (d) => _stepMode(modes, d), child: content),
      ],
    );

    return CatalogueKeys(
      onSearch: _searchFocus.requestFocus,
      onMode: (d) => _stepMode(modes, d),
      onRefresh: () => unawaited(_refresh.refresh()),
      onEdge: (top) {
        final p = _pos;
        if (p != null && p.hasPixels) p.jumpTo(top ? 0 : p.maxScrollExtent);
      },
      child: Stack(
        children: [
          NotificationListener<ScrollNotification>(onNotification: _onScroll, child: GlassScaffold(
            title: name,
            largeTitle: false,
            leading: GlassLeading.back,
            trailing: [GlassBarAction(id: 'refresh', label: 'Refresh', glyph: GlassGlyph.arrowClockwise, onPress: () => unawaited(_refresh.refresh()))],
            overflow: [
              GlassMenuEntry(label: 'Copy source id', onSelected: () {
                unawaited(Clipboard.setData(ClipboardData(text: id)));
                showGlassToast(ref, const GlassToastSpec('Copied'));
              },),
              GlassMenuEntry(label: pinned ? 'Unpin' : 'Pin', onSelected: () {
                final s = source;
                if (s != null) unawaited(ref.read(sourcePinsProvider.notifier).toggle(id, name: s.name, iconUrl: s.iconUrl, mature: s.mature).catchError((_) {}));
              },),
            ],
            refreshSliver: GlassPullToRefresh(controller: _refresh, onRefresh: _doRefresh),
            slivers: [SliverPadding(padding: const EdgeInsets.fromLTRB(0, 8, 0, 140), // GlassScaffold insets the slivers
 sliver: SliverToBoxAdapter(child: Builder(builder: (c) {
              _pos = Scrollable.maybeOf(c)?.position;
              return body;
            },),),),],
          ),),
          Positioned(right: phone ? 16 : 24, bottom: phone ? 96 : 24, child: TopCapsule(visible: _top, onTap: GlassScrollTop.scrollToTop)),
        ],
      ),
    );
  }

  /// Rate limited: retry on its own after `Retry-After`.
  void _scheduleRetry(Object err) {
    final key = '${retryAfterOf(err)}-${DateTime.now().minute}';
    if (_retryFor != null) return;
    _retryFor = key;
    _retry = Timer(Duration(seconds: retryAfterOf(err)), () {
      _retryFor = null;
      if (mounted) ref.invalidate(sourceBrowseProvider(_id));
    });
  }
}
