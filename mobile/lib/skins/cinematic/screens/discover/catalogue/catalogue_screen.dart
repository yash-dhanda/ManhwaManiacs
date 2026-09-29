import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/features/sources/models/source.dart';
import 'package:manhwamaniacs/features/sources/providers/discover_providers.dart';
import 'package:manhwamaniacs/features/sources/providers/sources_provider.dart';
import 'package:manhwamaniacs/features/sources/utils/browse_freshness.dart';
import 'package:manhwamaniacs/skins/cinematic/ai_copy.dart';
import 'package:manhwamaniacs/skins/cinematic/icons/phosphor.g.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_poster.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/catalogue/opening_state.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/catalogue/top_button.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/cine_extras.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/cine_kit.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/cine_poster.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/discover_keys.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/index_field_header.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/skin_haptics.dart';

/// `/sources/:sourceId`: browse modes, genres, search, the poster wall.
class CatalogueScreen extends ConsumerStatefulWidget {
  const CatalogueScreen({
    super.key,
    required this.sourceId,
    this.mode,
    this.genre,
    this.q,
  });

  final String sourceId;
  final String? mode;
  final String? genre;
  final String? q;

  @override
  ConsumerState<CatalogueScreen> createState() => _CatalogueScreenState();
}

class _CatalogueScreenState extends ConsumerState<CatalogueScreen> {
  final _scroll = ScrollController();
  final _search = TextEditingController();
  final _searchFocus = FocusNode();
  Timer? _debounce;
  Timer? _tick;
  bool _showTop = false;
  bool _landed = false;

  @override
  void initState() {
    super.initState();
    _search.text = widget.q ?? '';
    _scroll.addListener(_onScroll);
    // Re-renders the freshness credit every 30 s.
    _tick = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
    unawaited(
      Future<void>.microtask(() {
        ref.read(sourceBrowseQueryProvider(widget.sourceId).notifier).update(
              (s) => s.copyWith(
                search: widget.q ?? '',
                sort: widget.mode ?? s.sort,
                genre: widget.genre ?? '',
              ),
            );
      }),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _tick?.cancel();
    _scroll.dispose();
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onScroll() {
    final show = _scroll.hasClients && _scroll.offset > 400;
    if (show != _showTop) setState(() => _showTop = show);
    if (_scroll.hasClients && _scroll.position.extentAfter < 600) {
      unawaited(
        ref.read(sourceBrowseProvider(widget.sourceId).notifier).loadMore(),
      );
    }
  }

  void _url({String? mode, String? genre, String? q}) {
    final cur = ref.read(sourceBrowseQueryProvider(widget.sourceId));
    final m = mode ?? cur.sort;
    final g = genre ?? cur.genre;
    final s = q ?? cur.search;
    context.go(
      Routes.source(widget.sourceId, {
        'mode': m == 'default' ? null : m,
        'genre': (g == null || g.isEmpty) ? null : g,
        'q': s.isEmpty ? null : s,
      }),
    );
  }

  void _setQuery(SourceBrowseQuery Function(SourceBrowseQuery) f) =>
      ref.read(sourceBrowseQueryProvider(widget.sourceId).notifier).update(f);

  void _refresh() => unawaited(
        ref.read(sourceBrowseProvider(widget.sourceId).notifier).refresh(),
      );

  @override
  Widget build(BuildContext context) {
    final t = context.cine;
    final id = widget.sourceId;
    ref.listen(sourceBrowseProvider(id), (prev, next) {
      if (!_landed &&
          next.valueOrNull != null &&
          next.valueOrNull!.items.isNotEmpty) {
        _landed = true;
        unawaited(ref.read(skinHapticsProvider).fire(HapticEvent.select));
      }
    });
    final sources = ref.watch(sourcesListProvider).valueOrNull;
    final source = sources?.where((s) => s.id == id).firstOrNull;
    final browse = ref.watch(sourceBrowseProvider(id));
    final query = ref.watch(sourceBrowseQueryProvider(id));
    final modes = ref.watch(sourceBrowseModesProvider(id)).valueOrNull ??
        const <SourceBrowseMode>[];
    final genres = ref.watch(sourceGenresProvider(id)).valueOrNull ?? const [];
    final state = browse.valueOrNull;
    final err = browse.hasError ? browse.error : null;
    final code = err is ApiError ? err.code : null;
    final browsable =
        (source?.browsable ?? true) && code != 'source_not_browsable';
    final name = source?.name ?? id;
    final tablet = isTablet(context);
    final searching = query.search.isNotEmpty;
    final fresh = browseFreshness(state?.cache, DateTime.now());
    final total = state?.total ?? 0;
    final deck =
        'Catalogue · ${_n(total)} series${searching ? ' · "${query.search}"' : ''}';

    Widget content;
    if (code == 'source_not_found' ||
        (sources != null && source == null && err != null)) {
      content = CineNotice(
        kicker: 'NOT IN THIS ISSUE',
        headline: "This source isn't available here any more.",
        deck: 'It may have been removed from its source.',
        actions: [
          QuietButton(
            'Back to Tonight',
            onPressed: () => context.go(Routes.tonight()),
          ),
          QuietButton(
            'Search for it',
            onPressed: () => context.go(Routes.discover()),
          ),
        ],
      );
    } else if (!browsable && !searching) {
      content = CineNotice(
        kicker: 'NOTE',
        headline: 'This source can only be searched, not browsed.',
        actions: [
          QuietButton('Search it', onPressed: _searchFocus.requestFocus),
        ],
      );
    } else if (browse.isLoading && state == null) {
      content = OpeningState(sourceId: id, deck: deck);
    } else if (err != null && state == null) {
      content = _error(context, err, code);
    } else if (state != null && state.items.isEmpty) {
      content = CineNotice(
        kicker: 'NOTE',
        headline: searching
            ? 'No results for "${query.search}" on this source.'
            : 'No series found.',
      );
    } else {
      final cols = tablet ? 5 : 3;
      final w = MediaQuery.sizeOf(context).width;
      final gap = tablet ? 12.0 : 8.0;
      final posterW = (w - CineSpace.s4 * 2 - gap * (cols - 1)) / cols;
      final novel = source?.contentKind == kNovelContentKind;
      content = Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: CineSpace.s4),
            child: novel
                // TODO(mobile/09): swap for the Cinematic book list.
                ? Column(
                    children: [
                      for (final s in state!.items)
                        _BookRow(
                          title: s.title,
                          author: s.author,
                          chapters: s.chapterCount,
                          coverUrl: s.coverUrl,
                          onTap: () => context.push(Routes.feature(id, s.id)),
                        ),
                    ],
                  )
                : GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: state!.items.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: cols,
                      mainAxisSpacing: CineSpace.s3,
                      crossAxisSpacing: gap,
                      childAspectRatio: posterW /
                          (posterW * 1.5 +
                              CineSpace.s2 +
                              2 *
                                  22 *
                                  MediaQuery.textScalerOf(context).scale(1)),
                    ),
                    itemBuilder: (context, i) {
                      final s = state.items[i];
                      return SizedBox(
                        width: posterW,
                        child: CinePoster(
                          title: s.title,
                          url: s.coverUrl,
                          heroTag: (id, s.id),
                          onTap: () => context.push(Routes.feature(id, s.id)),
                          onQuickLook: () => showQuickLook(
                            context,
                            ref,
                            title: s.title,
                            coverUrl: s.coverUrl,
                            kicker: name,
                            caption: s.chapterCount > 0
                                ? 'CHAPTERS ${s.chapterCount}'
                                : null,
                            onOpen: () =>
                                context.push(Routes.feature(id, s.id)),
                            haptic: false,
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (state.isLoadingMore)
            const Padding(
              padding: EdgeInsets.all(CineSpace.s4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Kicker('Loading more'),
                  SizedBox(width: 8),
                  LeaderDial(),
                ],
              ),
            )
          else if (state.loadMoreFailed)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Couldn't load more.",
                  style: cineText(context, t.typeCaption, color: t.colorInk60),
                ),
                QuietButton(
                  'Retry',
                  onPressed: () => unawaited(
                    ref.read(sourceBrowseProvider(id).notifier).loadMore(),
                  ),
                ),
              ],
            )
          else if (!state.hasNext) ...[
            const SizedBox(height: CineSpace.s6),
            Divider(height: 1, thickness: 1, color: t.colorRule1),
            const SizedBox(height: CineSpace.s3),
            const Center(child: Kicker('End of catalogue')),
          ],
          const SizedBox(height: CineSpace.s16),
        ],
      );
    }

    final modeIndex = modes.indexWhere((m) => m.id == query.sort);
    void stepMode(int d) {
      if (modes.isEmpty || !browsable) return;
      final i =
          ((modeIndex < 0 ? 0 : modeIndex) + d).clamp(0, modes.length - 1);
      _setQuery((q) => q.copyWith(sort: modes[i].id));
      _url(mode: modes[i].id);
    }

    return CineKeys(
      group: 'Catalogue',
      keys: [
        CineKey(
          key(LogicalKeyboardKey.slash),
          _searchFocus.requestFocus,
          whenTextFieldFree: true,
        ),
        CineKey(
          key(LogicalKeyboardKey.bracketRight),
          () => stepMode(1),
          whenTextFieldFree: true,
        ),
        CineKey(
          key(LogicalKeyboardKey.bracketLeft),
          () => stepMode(-1),
          whenTextFieldFree: true,
        ),
        CineKey(
          key(LogicalKeyboardKey.keyR),
          _refresh,
          whenTextFieldFree: true,
        ),
        CineKey(
          key(LogicalKeyboardKey.home),
          () => _scroll.jumpTo(0),
          whenTextFieldFree: true,
        ),
        CineKey(
          key(LogicalKeyboardKey.end),
          () => _scroll.jumpTo(_scroll.position.maxScrollExtent),
          whenTextFieldFree: true,
        ),
        for (final (k, dir) in [
          (LogicalKeyboardKey.keyJ, 1),
          (LogicalKeyboardKey.keyL, 1),
          (LogicalKeyboardKey.arrowRight, 1),
          (LogicalKeyboardKey.keyK, -1),
          (LogicalKeyboardKey.keyH, -1),
          (LogicalKeyboardKey.arrowLeft, -1),
        ])
          CineKey(
            key(k),
            () => dir > 0
                ? focusStep(context, forward: true)
                : focusStep(context, forward: false),
            whenTextFieldFree: true,
          ),
      ],
      child: Scaffold(
        backgroundColor: t.colorPaper0,
        body: SafeArea(
          child: Stack(
            children: [
              if (browse.isLoading && state == null && browsable)
                CatalogueWash(sourceId: id),
              CinePullToReprint(
                onRefresh: () async {
                  await ref.read(sourceBrowseProvider(id).notifier).refresh();
                },
                child: ListView(
                  controller: _scroll,
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        tablet ? CineSpace.s8 : CineSpace.s4,
                        CineSpace.s4,
                        CineSpace.s4,
                        CineSpace.s2,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              IconButton(
                                tooltip: 'Back',
                                onPressed: () => context.canPop()
                                    ? context.pop()
                                    : context.go(Routes.sources()),
                                icon: Icon(
                                  PhosphorRegular.arrowLeft,
                                  color: t.colorInk100,
                                ),
                              ),
                              if (source?.iconUrl != null)
                                SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CineCover(
                                    url: source!.iconUrl,
                                    displayWidth: 24,
                                  ),
                                ),
                            ],
                          ),
                          const Kicker('No. 04 — Discover / Catalogue'),
                          HeadingFocus(
                            child: Semantics(
                              header: true,
                              headingLevel: 1,
                              child: SetHeading(
                                name,
                                key: ValueKey('h-$name'),
                                id: 'catalogue-$name',
                                style: cineText(context, t.typeMasthead),
                                cap: t.typeMasthead.cap,
                                level: 1,
                                trigger: SetTrigger.mount,
                              ),
                            ),
                          ),
                          if (!(browse.isLoading && state == null))
                            _retrySeconds(err) != null
                                ? RetryCountdown(
                                    key:
                                        ValueKey('retry-${_retrySeconds(err)}'),
                                    seconds: _retrySeconds(err)!,
                                    prefix: 'Rate limited · retrying in',
                                    style: cineText(
                                      context,
                                      t.typeDeck,
                                      color: t.colorInk60,
                                    ),
                                    onZero: _refresh,
                                  )
                                : Text(
                                    deck,
                                    style: cineText(
                                      context,
                                      t.typeDeck,
                                      color: t.colorInk60,
                                    ),
                                  ),
                          Row(
                            children: [
                              if (fresh != null)
                                fresh.stale
                                    ? Semantics(
                                        label:
                                            'NOTE. The source is down; this is the last copy we saved.',
                                        excludeSemantics: true,
                                        child: Tooltip(
                                          message:
                                              'The source is down; this is the last copy we saved.',
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: t.colorSpot,
                                              ),
                                            ),
                                            child: Text(
                                              fresh.text,
                                              style: cineText(
                                                context,
                                                t.typeMicro,
                                                color: t.colorSpot,
                                              ),
                                            ),
                                          ),
                                        ),
                                      )
                                    : Text(
                                        fresh.text,
                                        style: cineText(
                                          context,
                                          t.typeFolio,
                                          color: t.colorInk60,
                                        ),
                                      ),
                              const Spacer(),
                              browse.isLoading && state != null
                                  ? const Padding(
                                      padding: EdgeInsets.all(16),
                                      child: LeaderDial(),
                                    )
                                  : QuietButton(
                                      'Refresh',
                                      icon: PhosphorRegular.arrowClockwise,
                                      onPressed: _refresh,
                                    ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: CineSpace.s4),
                      child: IndexField(
                        controller: _search,
                        focusNode: _searchFocus,
                        hint: 'Search this source',
                        compact: true,
                        onChanged: (v) {
                          _debounce?.cancel();
                          _debounce =
                              Timer(const Duration(milliseconds: 300), () {
                            if (!mounted) return;
                            _setQuery((q) => q.copyWith(search: v.trim()));
                            _url(q: v.trim());
                          });
                        },
                        onSubmitted: (v) {
                          _setQuery((q) => q.copyWith(search: v.trim()));
                          _url(q: v.trim());
                        },
                      ),
                    ),
                    if (browsable && !searching && modes.isNotEmpty)
                      SlugTabs(
                        folios: false,
                        labels: [for (final m in modes) m.label],
                        selected: modeIndex < 0 ? 0 : modeIndex,
                        onSelected: (i) {
                          unawaited(
                            ref
                                .read(skinHapticsProvider)
                                .fire(HapticEvent.select),
                          );
                          _setQuery((q) => q.copyWith(sort: modes[i].id));
                          _url(mode: modes[i].id);
                        },
                      ),
                    if (browsable && genres.isNotEmpty)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: CineSpace.s4,
                          ),
                          child: QuietButton(
                            query.genre == null
                                ? 'Genre'
                                : 'Genre: ${query.genre}',
                            onPressed: () async {
                              final g = await showCineSheet<String>(
                                context,
                                title: 'Genre',
                                body: (context) => ListView(
                                  shrinkWrap: true,
                                  children: [
                                    for (final entry in [
                                      (id: '', label: 'All genres'),
                                      for (final g in genres)
                                        (id: g.label, label: g.label),
                                    ])
                                      InkWell(
                                        onTap: () =>
                                            Navigator.of(context).pop(entry.id),
                                        child: ConstrainedBox(
                                          constraints: const BoxConstraints(
                                            minHeight: 48,
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: CineSpace.s4,
                                            ),
                                            child: Align(
                                              alignment: Alignment.centerLeft,
                                              child: Text(
                                                entry.label,
                                                style: cineText(
                                                  context,
                                                  t.typeTitle,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                              if (g == null) return;
                              _setQuery((q) => q.copyWith(genre: g));
                              _url(genre: g);
                            },
                          ),
                        ),
                      ),
                    content,
                  ],
                ),
              ),
              if (_showTop)
                Positioned(
                  right: CineSpace.s4,
                  bottom: CineSpace.s4,
                  child: TopButton(controller: _scroll),
                ),
            ],
          ),
        ),
      ),
    );
  }

  int? _retrySeconds(Object? err) {
    if (err is ApiError && err.code == 'rate_limited') {
      return retryAfterSeconds(err) ?? 12;
    }
    return null;
  }

  Widget _error(BuildContext context, Object err, String? code) {
    if (err is NetworkError || err is TimeoutError) {
      return CineNotice(
        kicker: 'OFFLINE EDITION',
        headline: "Couldn't reach this source.",
        deck: 'Saved chapters still open.',
        actions: [QuietButton('Try again', onPressed: _refresh)],
      );
    }
    return CineNotice(
      kicker: 'CORRECTION',
      kickerColor: context.cine.colorProof,
      headline: "Couldn't load the catalogue.",
      deck: err is AppError ? err.userMessage : null,
      actions: [QuietButton('Try again', onPressed: _refresh)],
    );
  }

  String _n(int n) {
    final s = n.toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
      b.write(s[i]);
    }
    return b.toString();
  }
}

/// A novel source's row: small cover, title, author and chapter count.
class _BookRow extends StatelessWidget {
  const _BookRow({
    required this.title,
    required this.author,
    required this.chapters,
    required this.coverUrl,
    required this.onTap,
  });

  final String title;
  final String? author;
  final int chapters;
  final String? coverUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.cine;
    return Semantics(
      button: true,
      label: '$title${author == null ? '' : ', $author'}, $chapters chapters',
      excludeSemantics: true,
      child: ChildFocusRing(child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 96),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: CineSpace.s2),
              child: Row(
                children: [
                  SizedBox(
                      width: 48,
                      height: 72,
                      child: CineCover(url: coverUrl, displayWidth: 48),),
                  const SizedBox(width: CineSpace.s3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: cineText(context, t.typeTitle),),
                        if (author != null)
                          Text(author!,
                              style: cineText(context, t.typeCaption,
                                  color: t.colorInk60,),),
                        Text('$chapters CHAPTERS',
                            style: cineText(context, t.typeFolio,
                                color: t.colorInk60,),),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
