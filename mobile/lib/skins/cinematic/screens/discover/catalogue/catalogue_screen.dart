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
import 'package:manhwamaniacs/skins/cinematic/parts/book_list_row.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_notice.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_poster.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_progress.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_slug_lines.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/catalogue/opening_state.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/catalogue/top_button.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/cine_extras.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/cine_kit.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/cine_poster.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/discover_keys.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/index_field_header.dart';
import 'package:manhwamaniacs/skins/cinematic/shell/cine_scaffold.dart';
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
    // replace, not go: go would rebuild the Discover branch as just this
    // route, dropping Sources/Discover from the back stack.
    GoRouter.of(context).replace<void>(
      Routes.source(widget.sourceId, {
        'mode': m == 'default' ? null : m,
        'genre': (g == null || g.isEmpty) ? null : g,
        'q': s.isEmpty ? null : s,
      }),
    );
  }

  void _setQuery(SourceBrowseQuery Function(SourceBrowseQuery) f) =>
      ref.read(sourceBrowseQueryProvider(widget.sourceId).notifier).update(f);

  void _refresh() => unawaited(_doRefresh());

  Future<void> _doRefresh() async {
    final id = widget.sourceId;
    if (ref.read(sourceGenresProvider(id)).hasError) {
      ref.invalidate(sourceGenresProvider(id));
    }
    final ok = await ref.read(sourceBrowseProvider(id).notifier).refresh();
    if (!ok && mounted) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(content: Text("Couldn't refresh this source.")),
      );
    }
  }

  /// A page shorter than the viewport never scrolls, so it is checked after
  /// each frame that could have grown or shrunk the grid.
  void _fillViewport() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      final p = _scroll.position;
      if (p.hasContentDimensions && p.extentAfter < 600) {
        unawaited(
          ref.read(sourceBrowseProvider(widget.sourceId).notifier).loadMore(),
        );
      }
    });
  }

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
    // A value left over from the previous query (kept while the new one loads
    // or fails) is not drawn under the new query's label.
    final state = browse.valueOrNull?.answers(query) ?? false
        ? browse.valueOrNull
        : null;
    final err = browse.hasError ? browse.error : null;
    final code = err is ApiError ? err.code : null;
    final browsable =
        (source?.browsable ?? true) && code != 'source_not_browsable';
    final name = source?.name ?? id;
    final tablet = isTablet(context);
    final searching = query.search.isNotEmpty;
    final fresh = browseFreshness(state?.cache, DateTime.now());
    final total = state?.countLabel ?? '0';
    final deck =
        'Catalogue · ${_n(total)} series${searching ? ' · "${query.search}"' : ''}';
    if (state != null &&
        state.hasNext &&
        !state.isLoadingMore &&
        !state.loadMoreFailed) {
      _fillViewport();
    }

    Widget content;
    if (code == 'source_not_found' ||
        (sources != null && source == null && err != null)) {
      content = _notice(
        CineNotice(
          tone: CineNoticeTone.empty,
          kicker: 'NOT IN THIS ISSUE',
          headline: "This source isn't available here any more.",
          deck: 'It may have been removed from its source.',
          primary: CineNoticeAction(
            'Back to Tonight',
            () => context.go(Routes.tonight()),
          ),
          quiet: CineNoticeAction(
            'Search for it',
            () => context.go(Routes.discover()),
          ),
        ),
      );
    } else if (!browsable && !searching) {
      content = _notice(
        CineNotice(
          tone: CineNoticeTone.caution,
          headline: 'This source can only be searched, not browsed.',
          quiet: CineNoticeAction('Search it', _searchFocus.requestFocus),
        ),
      );
    } else if (browse.isLoading && state == null) {
      content = OpeningState(sourceId: id, deck: deck);
    } else if (err != null && state == null) {
      content = _error(context, err, code);
    } else if (state != null && state.items.isEmpty && !state.hasNext) {
      content = _notice(
        CineNotice(
          tone: CineNoticeTone.caution,
          headline: searching
              ? 'No results for "${query.search}" on this source.'
              : 'No series found.',
        ),
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
                ? Column(
                    children: [
                      for (final s in state!.items)
                        BookListRow(
                          title: s.title,
                          author: s.author,
                          credits: [
                            if (s.chapterCount > 0) '${s.chapterCount} CHAPTERS',
                            name.toUpperCase(),
                          ].join(' · '),
                          coverUrl: s.coverUrl,
                          heroTag: (id, s.id),
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
                  CineLeaderDial(size: 16),
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
                CineButton(
                  label: 'Retry',
                  variant: CineButtonVariant.quiet,
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
      // The running head carries Back (to Sources when nothing is beneath).
      child: CineScaffold(
        firstRunNote: false,
        body: Scaffold(
        backgroundColor: t.colorPaper0,
        body: SafeArea(
          child: Stack(
            children: [
              if (browse.isLoading && state == null && browsable)
                CatalogueWash(sourceId: id),
              CinePullToReprint(
                onRefresh: _doRefresh,
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
                                      child: CineLeaderDial(size: 16),
                                    )
                                  : CineButton(
                                      label: 'Refresh',
                                      variant: CineButtonVariant.quiet,
                                      leadingGlyph: PhosphorRegular
                                          .arrowClockwise.codePoint,
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
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: CineSpace.s4,
                        ),
                        child: CineSlugLines(
                          items: [
                            for (var i = 0; i < modes.length; i++)
                              CineSlug('$i', modes[i].label),
                          ],
                          selected: {'${modeIndex < 0 ? 0 : modeIndex}'},
                          onChanged: (id) {
                            final i = int.parse(id);
                            unawaited(
                              ref
                                  .read(skinHapticsProvider)
                                  .fire(HapticEvent.select),
                            );
                            _setQuery((q) => q.copyWith(sort: modes[i].id));
                            _url(mode: modes[i].id);
                          },
                        ),
                      ),
                    if (browsable && genres.isNotEmpty)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: CineSpace.s4,
                          ),
                          child: CineButton(
                            label: query.genre == null
                                ? 'Genre'
                                : 'Genre: ${genres.where((g) => g.id == query.genre).firstOrNull?.label ?? query.genre}',
                            variant: CineButtonVariant.quiet,
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
                                        (id: g.id, label: g.label),
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
      return _notice(
        CineNotice(
          tone: CineNoticeTone.offline,
          headline: "Couldn't reach this source.",
          deck: 'Saved chapters still open.',
          primary: CineNoticeAction('Try again', _refresh),
        ),
      );
    }
    return _notice(
      CineNotice(
        tone: CineNoticeTone.error,
        headline: "Couldn't load the catalogue.",
        deck: err is AppError ? err.userMessage : null,
        primary: CineNoticeAction('Try again', _refresh),
      ),
    );
  }

  Widget _notice(Widget n) => Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: CineSpace.s4,
          vertical: CineSpace.s6,
        ),
        child: n,
      );

  /// Groups the digits of a count label ('1234+' reads '1,234+').
  String _n(String label) {
    final plus = label.endsWith('+');
    final s = plus ? label.substring(0, label.length - 1) : label;
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
      b.write(s[i]);
    }
    if (plus) b.write('+');
    return b.toString();
  }
}

/// A novel source's row: small cover, title, author and chapter count.
