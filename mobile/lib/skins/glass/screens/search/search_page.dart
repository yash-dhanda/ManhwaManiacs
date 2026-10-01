import 'dart:async';

import 'package:flutter/widgets.dart' hide ShortcutRegistry;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/core/keyboard/shortcut_registry.dart';
import 'package:manhwamaniacs/features/content_mode/content_mode.dart';
import 'package:manhwamaniacs/features/content_mode/content_mode_controller.dart';
import 'package:manhwamaniacs/features/downloads/providers/downloaded_series_provider.dart';
import 'package:manhwamaniacs/features/downloads/providers/mature_gate_provider.dart';
import 'package:manhwamaniacs/features/downloads/utils/search_downloads.dart';
import 'package:manhwamaniacs/features/library/models/followed_series.dart';
import 'package:manhwamaniacs/features/library/providers/device_online_provider.dart';
import 'package:manhwamaniacs/features/library/providers/intelligence_providers.dart';
import 'package:manhwamaniacs/features/library/providers/library_list_provider.dart';
import 'package:manhwamaniacs/features/library/utils/recent_searches.dart';
import 'package:manhwamaniacs/features/novels/providers/novels_gate_provider.dart';
import 'package:manhwamaniacs/features/ocr/providers/ocr_providers.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/features/sources/models/source_search_group.dart';
import 'package:manhwamaniacs/features/sources/providers/discover_providers.dart';
import 'package:manhwamaniacs/features/sources/providers/source_pins_provider.dart';
import 'package:manhwamaniacs/features/sources/utils/discover_scope.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/primitives/chip.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glyphs_more.dart';
import 'package:manhwamaniacs/skins/glass/primitives/segmented.dart';
import 'package:manhwamaniacs/skins/glass/screens/dialogue/dialogue_card.dart';
import 'package:manhwamaniacs/skins/glass/screens/dialogue/dialogue_screen.dart' show openDialogueHit;
import 'package:manhwamaniacs/skins/glass/screens/home/home_actions.dart';
import 'package:manhwamaniacs/skins/glass/screens/search/groups.dart';
import 'package:manhwamaniacs/skins/glass/screens/search/jump_bar.dart';
import 'package:manhwamaniacs/skins/glass/screens/search/novel_text_results.dart';
import 'package:manhwamaniacs/skins/glass/screens/search/result_groups.dart';
import 'package:manhwamaniacs/skins/glass/screens/search/search_common.dart';
import 'package:manhwamaniacs/skins/glass/screens/search/search_idle.dart';
import 'package:manhwamaniacs/skins/glass/screens/search/search_keys.dart';
import 'package:manhwamaniacs/skins/glass/screens/search/search_states.dart';
import 'package:manhwamaniacs/skins/glass/screens/search/tier_capsule.dart';

/// The Discover body of `/search` (glass 8.9), placed above the bottom field by the shell's search page.
class GlassSearchBody extends ConsumerStatefulWidget {
  const GlassSearchBody({super.key, required this.query});
  final String query;

  @override
  ConsumerState<GlassSearchBody> createState() => _GlassSearchBodyState();
}

class _GlassSearchBodyState extends ConsumerState<GlassSearchBody> {
  final ScrollController _scroll = ScrollController();
  final Object _token = Object();
  late final ShortcutRegistry _shortcuts;
  List<String> _order = const [];
  final Set<String> _announced = {};
  final Map<String, GlobalKey> _keys = {};
  bool _showQuiet = false;
  String? _rawScope;
  int _cursor = -1;

  String get _q => widget.query.trim();

  @override
  void initState() {
    super.initState();
    _shortcuts = ref.read(shortcutRegistryProvider.notifier);
    _rawScope = _uriScope();
    Future.microtask(() {
      if (!mounted) return;
      _shortcuts.register(_token, searchShortcutEntries());
      _publish();
    });
  }

  String? _uriScope() {
    try {
      return GoRouter.of(context).state.uri.queryParameters['scope'];
    } catch (_) {
      return null;
    }
  }

  @override
  void didUpdateWidget(GlassSearchBody old) {
    super.didUpdateWidget(old);
    final s = _uriScope();
    if (s != _rawScope) _rawScope = s;
    if (old.query != widget.query) _publish();
  }

  @override
  void dispose() {
    final s = _shortcuts;
    final t = _token;
    Future.microtask(() => s.unregister(t));
    _scroll.dispose();
    super.dispose();
  }

  void _publish() {
    final q = _q;
    Future.microtask(() {
      if (!mounted) return;
      ref.read(searchQueryProvider.notifier).state = q.length >= 2 ? q : '';
      if (q.length >= 2) {
        unawaited(writeRecentSearch(ref.read(sharedPrefsProvider), q, profileId: ref.read(activeProfileProvider)?.id, gateOpen: ref.read(matureGateOpenProvider)).then((_) {
          if (mounted) setState(() {});
        }),);
      }
    });
    _order = const [];
    _announced.clear();
  }

  // -- scopes --------------------------------------------------------------------------------------------------------------

  bool get _dialogueOn => ref.read(ocrFeatureVisibleProvider) && (ref.read(serverOcrCapabilityProvider).valueOrNull ?? true) && ref.read(contentModeControllerProvider) == ContentMode.manga;

  GlassDiscoverScope _scope() => parseGlassDiscoverScope(
        _rawScope,
        aiAvailable: ref.read(suggestAvailabilityProvider).valueOrNull?.available ?? false,
        dialogueAvailable: _dialogueOn,
        novelsEnabled: ref.read(novelsEnabledProvider),
        picksReady: false, // glass `picks` is built by mobile/41; until then `ask` parses to `all`.
      );

  List<GlassDiscoverScope> _scopes() => [
        GlassDiscoverScope.all,
        GlassDiscoverScope.library,
        GlassDiscoverScope.sources,
        if (_dialogueOn) GlassDiscoverScope.dialogue,
        if (ref.read(novelsEnabledProvider)) GlassDiscoverScope.text,
      ];

  void _setScope(GlassDiscoverScope s) {
    glassFire(ref, HapticEvent.select);
    setState(() => _rawScope = s == GlassDiscoverScope.all ? null : s.wire);
    final qp = <String, String>{if (_q.isNotEmpty) 'q': _q, if (s != GlassDiscoverScope.all) 'scope': s.wire};
    try {
      GoRouter.of(context).replace<void>(Uri(path: '/search', queryParameters: qp.isEmpty ? null : qp).toString());
    } catch (_) {}
  }

  void _stepScope(int d) {
    final list = _scopes();
    final i = list.indexOf(_scope());
    _setScope(list[(i + d).clamp(0, list.length - 1)]);
  }

  static const _labels = {
    GlassDiscoverScope.all: 'All',
    GlassDiscoverScope.library: 'Library',
    GlassDiscoverScope.sources: 'Sources',
    GlassDiscoverScope.dialogue: 'Dialogue',
    GlassDiscoverScope.text: 'Novel text',
  };

  // -- groups --------------------------------------------------------------------------------------------------------------

  Future<void> _jumpTo(int i) async {
    if (i < 0 || i >= _order.length) return;
    _cursor = i;
    final ctx = _keys[_order[i]]?.currentContext;
    if (ctx == null) return;
    await Scrollable.ensureVisible(ctx, duration: ref.read(glassReducedProvider) ? Duration.zero : const Duration(milliseconds: 300), curve: Curves.easeOutCubic);
  }

  void _stepGroup(int d) => unawaited(_jumpTo((_cursor + d).clamp(0, _order.isEmpty ? 0 : _order.length - 1)));

  // -- build ---------------------------------------------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    // The scope getters `ref.read`; watching here keeps them live and holds the autoDispose availability probe open (a bare read
    // disposes it straight away, so `aiAvailable` never saw its value and every build refetched).
    ref
      ..watch(suggestAvailabilityProvider)
      ..watch(ocrFeatureVisibleProvider)
      ..watch(serverOcrCapabilityProvider)
      ..watch(contentModeControllerProvider)
      ..watch(novelsEnabledProvider);
    final scope = _scope();
    final scopes = _scopes();
    final phone = GlassFrame.of(context) == GlassFrameKind.phone;
    final margin = GlassFrame.screenMargin(context);
    final bottom = 50 + 21 + MediaQuery.viewInsetsOf(context).bottom + 28;
    final online = ref.watch(deviceOnlineProvider).valueOrNull ?? true;
    final children = <Widget>[
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Align(
          alignment: Alignment.centerLeft,
          child: GlassSegmented<GlassDiscoverScope>(
            compact: true,
            segments: [for (final s in scopes) GlassSegment(value: s, label: _labels[s]!)],
            selected: scopes.contains(scope) ? scope : GlassDiscoverScope.all,
            onSelected: _setScope,
          ),
        ),
      ),
    ];
    Widget? jump;
    if (_q.length < 2) {
      final prefs = ref.watch(sharedPrefsProvider);
      final pid = ref.watch(activeProfileProvider)?.id;
      children.add(SearchIdle(
        query: _q,
        recent: readRecentSearches(prefs, profileId: pid),
        askAvailable: false, // needs `picksReady` (mobile/41)
        onSearch: (t) => GoRouter.of(context).replace<void>(Uri(path: '/search', queryParameters: {'q': t, if (_rawScope != null) 'scope': _rawScope}).toString()),
        onRemove: (t) async {
          final left = readRecentSearchEntries(prefs, profileId: pid).where((e) => e.q != t).toList();
          await clearRecentSearches(prefs, profileId: pid);
          for (final e in left.reversed) {
            await writeRecentSearch(prefs, e.q, profileId: pid, gateOpen: e.gateOpen);
          }
          if (mounted) setState(() {});
        },
      ),);
    } else if (scope == GlassDiscoverScope.text) {
      children.add(NovelTextResults(query: _q));
    } else if (scope == GlassDiscoverScope.dialogue) {
      children.add(_DialogueInline(query: _q));
    } else if (!online) {
      children.addAll(_offline());
    } else {
      final r = _results(scope, phone);
      children.addAll(r.$1);
      jump = r.$2;
    }
    return SearchKeys(
      onScope: _stepScope,
      onGroup: _stepGroup,
      child: Stack(
        children: [
          ListView(
            controller: _scroll,
            padding: EdgeInsets.fromLTRB(margin, MediaQuery.paddingOf(context).top + 56, margin, bottom),
            children: children,
          ),
          if (jump != null) Positioned(right: 0, top: MediaQuery.paddingOf(context).top + 120, bottom: bottom, child: jump),
        ],
      ),
    );
  }

  List<Widget> _offline() {
    final shelf = ref.watch(downloadedSeriesProvider).valueOrNull ?? const [];
    final hits = searchDownloads(shelf, _q, gateOpen: ref.watch(matureGateOpenProvider));
    return [
      const SearchHelper('Offline: searching this device only', warning: true),
      if (hits.isEmpty) SearchEmptyLens(q: _q) else ...[
        Padding(padding: const EdgeInsets.only(top: 8, bottom: 4), child: GlassLabel('On this device', role: gt.typeHeadline)),
        for (final g in hits)
          GlassTap(
            label: '${g.seriesTitle ?? g.seriesKey}, ${g.chapters.length} chapters',
            onTap: () => unawaited(openSeries(ref, g.sourceId, g.seriesKey)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(GlassGlyph28.cloudArrowDown.regular, size: 18, color: gt.colorLabel3),
              const SizedBox(width: 10),
              Flexible(child: GlassLabel(g.seriesTitle ?? g.seriesKey, role: gt.typeBody)),
            ],),
          ),
      ],
    ];
  }

  (List<Widget>, Widget?) _results(GlassDiscoverScope scope, bool phone) {
    final async = ref.watch(searchListProvider);
    final notifier = ref.read(searchListProvider.notifier);
    final result = async.valueOrNull;
    if (async.hasError && result == null) {
      final e = async.error!;
      if (isRateLimited(e)) return ([SearchRateLimited(seconds: retryAfterOf(e), onRetry: notifier.refresh)], null);
      if (isNetworkDown(e)) return (_offline(), null);
      return ([SearchErrorLens(onRetry: notifier.refresh)], null);
    }
    if (result == null) return ([const SearchLoadingSkeleton()], null);

    var groups = List<SourceSearchGroup>.of(ref.watch(visibleSearchGroupsProvider));
    if (scope == GlassDiscoverScope.library) groups = [for (final g in groups) if (g.isLocal) g];
    if (scope == GlassDiscoverScope.sources) groups = [for (final g in groups) if (!g.isLocal) g];

    final pins = ref.watch(pinnedSourceIdsProvider);
    _order = arrangeGroupKeys(_order, groups, pins);
    final byKey = {for (final g in groups) g.key: g};
    final ordered = [for (final k in _order) if (byKey[k] != null) byKey[k]!];
    final shown = [for (final g in ordered) if (g.items.isNotEmpty || g.hasError) g];
    final quiet = [for (final g in ordered) if (g.items.isEmpty && !g.hasError) g];
    final filter = ref.watch(searchGroupFilterProvider);
    final tier2 = result.phase == SearchPhase.tier2;
    final first = _announced.isEmpty;

    for (final g in shown) {
      if (_announced.add(g.key) && !first && g.items.isNotEmpty) {
        final name = g.isLocal ? 'Library' : g.sourceName;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) announceGroup(context, '$name: ${g.items.length} results');
        });
      }
    }

    final out = <Widget>[
      TierCapsule(
        results: result.resultCount,
        pending: tier2 ? result.sourcesPending : 0,
        answered: (result.sourcesQueried - (tier2 ? result.sourcesPending : 0)).clamp(0, result.sourcesQueried),
        queried: result.sourcesQueried,
      ),
      const SizedBox(height: 8),
      GlassChoiceChips<SearchGroupFilter>(
        options: const [SearchGroupFilter.all, SearchGroupFilter.hasResults, SearchGroupFilter.pinned],
        selected: filter,
        labelOf: (f) => switch (f) { SearchGroupFilter.all => 'All', SearchGroupFilter.hasResults => 'With results', SearchGroupFilter.pinned => 'Pinned' },
        onSelected: (f) => ref.read(searchGroupFilterProvider.notifier).state = f,
      ),
    ];
    if (shown.isEmpty && !tier2) {
      if (filter == SearchGroupFilter.pinned) {
        out.add(const SearchHelper('No pinned sources answered. Pin a source on the Sources tab to keep it here.'));
      } else if (filter == SearchGroupFilter.hasResults) {
        out.add(const SearchHelper('Switch back to All to see every source that answered.'));
      } else {
        out.add(SearchEmptyLens(q: _q, onDialogue: _dialogueOn ? () => _setScope(GlassDiscoverScope.dialogue) : null));
      }
      return (out, null);
    }
    final grid = GlassFrame.of(context) != GlassFrameKind.phone;
    for (var i = 0; i < shown.length; i++) {
      final g = shown[i];
      _keys.putIfAbsent(g.key, GlobalKey.new);
      out.add(KeyedSubtree(
        key: _keys[g.key],
        child: DepthIn(
          key: ValueKey('g-${g.key}'),
          animate: tier2 || (result.tier == 2),
          child: SearchGroupSection(group: g, grid: grid, retrying: notifier.isRetrying(g.source ?? ''), onRetry: () => notifier.retrySource(g.source!)),
        ),
      ),);
    }
    if (quiet.isNotEmpty) {
      out.add(QuietSourcesRow(count: quiet.length, open: _showQuiet, onToggle: () => setState(() => _showQuiet = !_showQuiet)));
      if (_showQuiet) {
        for (final g in quiet) {
          out.add(Padding(padding: const EdgeInsets.only(left: 4), child: GlassLabel(g.sourceName, role: gt.typeFootnote, color: gt.colorLabel3)));
        }
      }
    }
    final jump = phone && shown.length > 6
        ? SearchJumpBar(
            names: [for (final g in shown) g.isLocal ? 'Library' : g.sourceName],
            initials: [for (final g in shown) groupInitial(g)],
            onJump: (i) => unawaited(_jumpTo(i)),
            onTick: () => glassFire(ref, HapticEvent.select),
          )
        : null;
    return (out, jump);
  }
}

/// The Dialogue scope: inline dialogue cards from `GET /ocr/search`.
class _DialogueInline extends ConsumerWidget {
  const _DialogueInline({required this.query});
  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final res = ref.watch(ocrSearchProvider(query));
    final followed = ref.watch(libraryListProvider).valueOrNull?.items ?? const <FollowedSeries>[];
    return res.when(
      loading: () => const SearchLoadingSkeleton(),
      error: (e, _) => isNetworkDown(e) ? const SearchHelper('Dialogue search needs a connection', warning: true) : SearchErrorLens(onRetry: () => ref.invalidate(ocrSearchProvider(query))),
      data: (page) {
        if (page.items.isEmpty) return SearchEmptyLens(q: query);
        return Column(
          children: [
            for (final h in page.items)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Builder(builder: (context) {
                  final s = followed.where((f) => f.sourceId == h.sourceId && f.seriesKey == h.seriesKey).firstOrNull;
                  return GlassDialogueCard(hit: h, title: s?.title, coverUrl: s?.coverUrl, onOpen: () => openDialogueHit(ref, h, query));
                },),
              ),
          ],
        );
      },
    );
  }
}
