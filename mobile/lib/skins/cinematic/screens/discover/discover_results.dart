import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/features/library/providers/intelligence_providers.dart';
import 'package:manhwamaniacs/features/library/providers/library_list_provider.dart';
import 'package:manhwamaniacs/features/ocr/models/ocr_search_result.dart';
import 'package:manhwamaniacs/features/ocr/providers/ocr_providers.dart';
import 'package:manhwamaniacs/features/ocr/services/ocr_snippet.dart';
import 'package:manhwamaniacs/features/sources/models/source_search_group.dart';
import 'package:manhwamaniacs/features/sources/providers/source_pins_provider.dart';
import 'package:manhwamaniacs/features/sources/utils/discover_scope.dart';
import 'package:manhwamaniacs/skins/cinematic/icons/phosphor.g.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/cine_extras.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/cine_kit.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/group_jump_sheet.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/result_group.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/skin_haptics.dart';

const _filterLabels = ['ALL', 'WITH RESULTS', 'PINNED'];

/// Tiered results: status line, filter slugs, groups, IN DIALOGUE.
/// [scrollController] drives the group jump (400 ms glide, `jumpTo` when
/// motion is reduced); [groupKeys] are shared with the `[` / `]` keys.
class DiscoverResults extends ConsumerStatefulWidget {
  const DiscoverResults({
    super.key,
    required this.query,
    required this.scope,
    required this.dialogueAvailable,
    required this.scrollController,
    required this.onAsk,
  });

  final String query;
  final DiscoverScope scope;
  final bool dialogueAvailable;
  final ScrollController scrollController;
  final VoidCallback onAsk;

  @override
  ConsumerState<DiscoverResults> createState() => DiscoverResultsState();
}

class DiscoverResultsState extends ConsumerState<DiscoverResults> {
  final _keys = <String, GlobalKey>{};
  final _focus = <String, FocusNode>{};
  bool _showEmpty = false;
  int _current = -1;
  List<String> _order = const [];

  @override
  void dispose() {
    for (final f in _focus.values) {
      f.dispose();
    }
    super.dispose();
  }

  /// Scroll to a group by key; focuses its header.
  Future<void> jumpTo(String key) async {
    final ctx = _keys[key]?.currentContext;
    if (ctx == null) return;
    final reduced = cineReduced(context);
    await Scrollable.ensureVisible(
      ctx,
      duration: reduced ? Duration.zero : CineDur.glide,
      curve: CineCurves.settle,
    );
    _focus[key]?.requestFocus();
  }

  /// `]` / `[`: the next / previous group.
  void step(int delta) {
    if (_order.isEmpty) return;
    _current = (_current + delta).clamp(0, _order.length - 1);
    jumpTo(_order[_current]);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.cine;
    final async = ref.watch(searchListProvider);
    final filter = ref.watch(searchGroupFilterProvider);
    final notifier = ref.read(searchListProvider.notifier);
    var groups = ref.watch(visibleSearchGroupsProvider);
    final scope = widget.scope;
    if (scope == DiscoverScope.library) groups = [for (final g in groups) if (g.isLocal) g];
    if (scope == DiscoverScope.sources) groups = [for (final g in groups) if (!g.isLocal) g];
    final result = async.valueOrNull;
    final pinned = ref.watch(pinnedSourceIdsProvider).length;
    final dialogueOn = widget.dialogueAvailable &&
        (scope == DiscoverScope.all || scope == DiscoverScope.dialogue);

    // Error / offline / rate limited with nothing to show.
    if (async.hasError && result == null) {
      return _failure(context, async.error!, notifier.refresh);
    }
    if (async.isLoading && result == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _status(context, 'Searching your library and $pinned pinned sources…'),
          for (var g = 0; g < 3; g++) ...[
            const Padding(
              padding: EdgeInsets.all(CineSpace.s4),
              child: FlickerPlate(height: 24, width: 160),
            ),
            SizedBox(
              height: 200,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: CineSpace.s4),
                children: [
                  for (var i = 0; i < 4; i++)
                    const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: FlickerPlate(width: 110, height: 180),
                    ),
                ],
              ),
            ),
          ],
        ],
      );
    }

    final withResults = groups.where((g) => g.items.isNotEmpty || g.hasError).toList();
    final empty = groups.where((g) => g.items.isEmpty && !g.hasError).toList();
    final shown = [...withResults, if (_showEmpty) ...empty];
    _order = [for (final g in withResults) g.key];
    final count = result?.resultCount ?? 0;
    final sources = groups.where((g) => !g.isLocal && g.items.isNotEmpty).length;
    final tier2 = result?.phase == SearchPhase.tier2;
    final status = tier2
        ? '$count results so far · searching ${result!.sourcesPending} more sources…'
        : '$count results · $sources sources';
    final failed = result?.sourcesFailed ?? 0;

    final dialogue = dialogueOn ? ref.watch(ocrSearchProvider(widget.query)).valueOrNull : null;

    if (scope == DiscoverScope.dialogue) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [_dialogueGroup(context, dialogue, limit: 20)],
      );
    }

    if (count == 0 && !tier2 && (dialogue?.items.isEmpty ?? true)) {
      final ai = ref.watch(suggestAvailabilityProvider).valueOrNull?.available ?? false;
      return CineNotice(
        kicker: 'NOTHING FOUND',
        headline: 'No series match "${widget.query}" in your library or sources.',
        actions: [if (ai) QuietButton('Ask the editors', onPressed: widget.onAsk)],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _status(context, status),
        if (tier2) const Padding(
          padding: EdgeInsets.symmetric(horizontal: CineSpace.s4),
          child: IndeterminateRule(),
        ),
        if (failed > 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(CineSpace.s4, CineSpace.s2, CineSpace.s4, 0),
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'NOTE  ',
                    style: cineText(context, t.typeKicker, color: t.colorSpot),
                  ),
                  TextSpan(
                    text: "$failed ${failed == 1 ? "source didn't" : "sources didn't"} answer.",
                    style: cineText(context, t.typeCaption, color: t.colorInk60),
                  ),
                ],
              ),
            ),
          ),
        SlugTabs(
          labels: _filterLabels,
          folios: false,
          selected: filter.index == 0 ? 0 : (filter == SearchGroupFilter.hasResults ? 1 : 2),
          onSelected: (i) {
            ref.read(searchGroupFilterProvider.notifier).state = switch (i) {
              1 => SearchGroupFilter.hasResults,
              2 => SearchGroupFilter.pinned,
              _ => SearchGroupFilter.all,
            };
            ref.read(skinHapticsProvider).fire(HapticEvent.select);
          },
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: CineSpace.s4),
            child: QuietButton(
              'Jump to source',
              onPressed: withResults.isEmpty
                  ? null
                  : () async {
                      final k = await showGroupJumpSheet(context, withResults);
                      if (k != null) await jumpTo(k);
                    },
            ),
          ),
        ),
        for (final g in shown)
          KeyedSubtree(
            key: _keys.putIfAbsent(g.key, GlobalKey.new),
            child: ResultGroup(
              group: g,
              retrying: notifier.isRetrying(g.source ?? ''),
              headerFocus: _focus.putIfAbsent(g.key, FocusNode.new),
              onRetry: () => notifier.retrySource(g.source!),
            ),
          ),
        if (empty.isNotEmpty)
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: CineSpace.s4),
              child: QuietButton(
                _showEmpty
                    ? 'Hide ${empty.length} sources with no matches'
                    : 'Show ${empty.length} sources with no matches',
                onPressed: () => setState(() => _showEmpty = !_showEmpty),
              ),
            ),
          ),
        if (dialogueOn) _dialogueGroup(context, dialogue, limit: 3),
        const SizedBox(height: CineSpace.s16),
      ],
    );
  }

  Widget _status(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.fromLTRB(CineSpace.s4, CineSpace.s3, CineSpace.s4, CineSpace.s2),
        child: Semantics(
          liveRegion: true,
          child: Text(text, style: cineText(context, context.cine.typeCaption, color: context.cine.colorInk60)),
        ),
      );

  Widget _dialogueGroup(BuildContext context, OcrSearchPage? page, {required int limit}) {
    final t = context.cine;
    final items = page?.items ?? const <OcrSearchResult>[];
    if (items.isEmpty) {
      return widget.scope == DiscoverScope.dialogue
          ? CineNotice(
              kicker: 'NOTHING FOUND',
              headline: 'Nothing found for "${widget.query}".',
              deck: 'Only chapters whose dialogue was scanned, in series you follow, can be searched.',
            )
          : const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: CineSpace.s4, vertical: CineSpace.s2),
          child: Text('IN DIALOGUE', style: cineText(context, t.typeTitle)),
        ),
        for (final r in items.take(limit))
          _dialogueRow(context, r),
        QuietButton(
          'See all',
          onPressed: () => context.push(Routes.dialogue({'q': widget.query})),
        ),
      ],
    );
  }

  Widget _failure(BuildContext context, Object error, VoidCallback retry) {
    if (error is NetworkError || error is TimeoutError) {
      return CineNotice(
        kicker: 'OFFLINE EDITION',
        headline: 'Search needs a connection to reach your library and sources.',
        deck: 'Saved chapters still open.',
        actions: [QuietButton('Go to Downloads', onPressed: () => context.go(Routes.downloads()))],
      );
    }
    if (error is ApiError && error.code == 'rate_limited') {
      final after = (error.details is Map ? (error.details! as Map)['retry_after'] : null);
      return CineNotice(
        kicker: 'SLOW DOWN',
        headline: 'Too many searches at once.',
        folio: RetryCountdown(
          seconds: after is num ? after.toInt() : 12,
          style: cineText(context, context.cine.typeFolio, color: context.cine.colorSpot),
          onZero: retry,
        ),
        kickerColor: context.cine.colorSpot,
        actions: [QuietButton('Try again', onPressed: retry)],
      );
    }
    return CineNotice(
      kicker: 'CORRECTION',
      headline: "Search didn't finish.",
      deck: error is AppError ? error.userMessage : null,
      kickerColor: context.cine.colorProof,
      actions: [QuietButton('Try again', onPressed: retry)],
    );
  }

  Widget _dialogueRow(BuildContext context, OcrSearchResult r) {
    final t = context.cine;
    void open() => context.push(Routes.dialogue({'q': widget.query}));
    void quickLook() => unawaited(
          showQuickLook(
            context,
            ref,
            title: ocrSnippetSpans(r.snippet).map((s) => s.text).join(),
            coverUrl: null,
            kicker: 'IN DIALOGUE',
            caption: r.page == null ? 'CH ${r.chapterKey}' : 'CH ${r.chapterKey} · PAGE ${r.page}',
            onOpen: open,
            openLabel: 'See in dialogue',
          ),
        );
    return CineFocusRing(
      child: CineLongPress(
        onLongPress: quickLook,
        child: InkWell(
          onTap: open,
          child: Padding(
            padding: const EdgeInsets.only(left: CineSpace.s4),
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: CineSpace.s2),
                    child: RichText(
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(
                        children: [
                          for (final s in ocrSnippetSpans(r.snippet))
                            TextSpan(
                              text: s.text,
                              style: cineText(
                                context,
                                t.typeBody,
                                color: s.highlighted ? t.colorInk100 : t.colorInk60,
                              ).copyWith(backgroundColor: s.highlighted ? t.colorSpotWash : null),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'More for this line',
                  onPressed: quickLook,
                  constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                  icon: Icon(PhosphorRegular.dotsThree, size: 24, color: t.colorInk100),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
