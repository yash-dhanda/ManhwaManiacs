import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/core/time/clock.dart';
import 'package:manhwamaniacs/features/ai/providers/ai_providers.dart';
import 'package:manhwamaniacs/features/auth/providers/session_offline_provider.dart';
import 'package:manhwamaniacs/features/library/models/world_item.dart';
import 'package:manhwamaniacs/features/library/providers/genre_weights_provider.dart';
import 'package:manhwamaniacs/features/library/providers/intelligence_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/ai_copy.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_badge.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_masthead.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_pull_to_reprint.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_section_header.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/discover_keys.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/picks/ask_block.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/picks/because_rails.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/picks/editors_suggest.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/picks/for_you_grid.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/picks/genre_line.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/picks/picks_keys.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/tonight/tonight_layout.dart' show pickedAgo;
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// `/library/recommendations` (cinematic 9.1.3, mobile S11): the Ask block, the editors'
/// suggestions as mini reviews, For you, the Because you read rails and the Your genres line. The
/// AI is the magazine's editorial desk: when it is closed the page says so and the world
/// recommendations still work.
class PicksScreen extends ConsumerStatefulWidget {
  const PicksScreen({super.key, this.focusAsk = false});

  /// Arrived with `?ask=1` (Discover's `Ask`): the field takes focus.
  final bool focusAsk;

  @override
  ConsumerState<PicksScreen> createState() => _PicksScreenState();
}

class _PicksScreenState extends ConsumerState<PicksScreen> {
  final _text = TextEditingController();
  final _ask = FocusNode(debugLabel: 'picks-ask');
  final _heading = FocusNode(debugLabel: 'picks-heading');
  bool _everywhere = true, _timedOut = false;
  Timer? _timeout;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      (widget.focusAsk ? _ask : _heading).requestFocus();
    });
  }

  @override
  void dispose() {
    _timeout?.cancel();
    _text.dispose();
    _ask.dispose();
    _heading.dispose();
    super.dispose();
  }

  AsyncValue<WorldSuggestResponse?> get _answer => ref.read(_everywhere ? suggestionsProvider : localSuggestionsProvider);

  void _submit(String prompt) {
    _timeout?.cancel();
    setState(() => _timedOut = false);
    if (_everywhere) {
      unawaited(ref.read(suggestionsProvider.notifier).submit(prompt));
    } else {
      unawaited(ref.read(localSuggestionsProvider.notifier).submit(prompt));
    }
    // After 40 s with nothing back the timeout copy replaces the thinking line; the request is not
    // cancelled, so a late answer still renders and removes it.
    _timeout = Timer(const Duration(seconds: 40), () {
      if (mounted && _answer.isLoading) setState(() => _timedOut = true);
    });
  }

  void _submitField() {
    if (askValid(_text.text)) _submit(_text.text.trim());
  }

  Future<void> _reprint() async {
    ref
      ..invalidate(recommendationsProvider)
      ..invalidate(suggestAvailabilityProvider);
    try {
      await ref.read(recommendationsProvider.future);
    } catch (_) {}
  }

  String? _code(Object? e) => e is ApiError ? e.code : null;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final tablet = MediaQuery.sizeOf(context).width >= 600;
    final avail = ref.watch(suggestAvailabilityProvider).valueOrNull;
    final recs = ref.watch(recommendationsProvider);
    final genres = ref.watch(genreWeightsProvider(40)).valueOrNull ?? const [];
    final dismissed = ref.watch(dismissedPicksProvider);
    final answer = ref.watch(_everywhere ? suggestionsProvider : localSuggestionsProvider);
    ref.listen(_everywhere ? suggestionsProvider : localSuggestionsProvider, (prev, next) {
      if (!next.isLoading) {
        _timeout?.cancel();
        if (_timedOut) setState(() => _timedOut = false);
      }
    });
    final now = ref.read(clockProvider)();
    final code = _code(answer.error);
    final notConfigured = avail?.reason == 'not_configured' || code == 'ai_not_configured';
    final budget = avail?.reason == 'budget_exhausted' || code == 'ai_budget_exhausted';
    final aiOn = avail != null && !notConfigured;
    final pad = tablet ? c.space8 : c.space4;

    final deck = budget
        ? '${aiCopyForCode('budget_exhausted').text} The picks below still work.'
        : (aiOn ? 'Describe it in your own words. Suggestions are weighed against what you already read.' : 'Titles from everywhere, picked from what you read.');
    final ago = pickedAgo(recs.valueOrNull?.generatedAt, now);

    final data = recs.valueOrNull;
    final forYou = [for (final i in data?.forYou ?? const <WorldItem>[]) if (!dismissed.contains(pickId(i))) i];
    final sections = [for (final s in data?.sections ?? const <WorldSection>[]) if (s.items.isNotEmpty) s];
    final partial = data != null && ((data.sections.any((s) => s.items.isEmpty)) || (data.forYou.isEmpty && sections.isNotEmpty));
    var folio = 0;
    String nextFolio() => (++folio).toString().padLeft(2, '0');

    final children = <Widget>[
      CineMasthead(kicker: 'No. 12 — PICKS', title: 'Picks', deck: deck, focusNode: _heading, id: 'picks'),
      if (ago != null) Padding(padding: EdgeInsets.only(bottom: c.space4), child: Align(alignment: Alignment.centerLeft, child: CineBadge.pickedAgo(ago))),
      if (data?.unavailableReason != null) Padding(padding: EdgeInsets.only(bottom: c.space4), child: CineRoleText(data!.unavailableReason!, c.typeCaption, color: c.colorInk60)),
      if (notConfigured && avail != null)
        Padding(padding: EdgeInsets.only(bottom: c.space6), child: PicksNotice(kicker: 'NOTE', spot: true, text: aiCopyForCode('not_configured').text))
      else if (aiOn) ...[
        PicksAskBlock(
          controller: _text,
          focusNode: _ask,
          onAsk: _submit,
          everywhere: _everywhere,
          onEverywhere: (v) => setState(() {
            _everywhere = v;
            _timedOut = false;
          }),
          asking: answer.isLoading,
          disabled: budget,
          remaining: budget ? 0 : avail.remainingToday,
          caption: budget ? aiCopyForCode('budget_exhausted').text : null,
        ),
        SizedBox(height: c.space6),
      ],
      if (genres.isNotEmpty) ...[PicksGenreLine(genres: genres), SizedBox(height: c.space6)],
      if (answer.isLoading || answer.hasError || answer.valueOrNull != null) ...[
        EditorsSuggest(
          value: answer,
          timedOut: _timedOut,
          everywhere: _everywhere,
          onTryAgain: _submitField,
          onBrowseSources: () => context.go(Routes.sources()),
          onAskEverywhere: () => setState(() => _everywhere = true),
        ),
        SizedBox(height: c.space8),
      ],
      if (recs.isLoading && !recs.hasValue) ...[
        CineSectionHeader(headingId: 'picks-for-you', heading: 'For you', folio: nextFolio()),
        SizedBox(height: c.space3),
        const ForYouGrid(items: [], loading: true),
      ] else if (recs.hasError && !recs.hasValue)
        PicksNotice(
          kicker: ref.watch(sessionOfflineProvider) ? 'OFFLINE EDITION' : 'CORRECTION',
          error: !ref.watch(sessionOfflineProvider),
          text: ref.watch(sessionOfflineProvider) ? "You're offline. Saved chapters still open." : "The recommendations couldn't be loaded.",
          actions: [CineButton(label: 'Try again', variant: CineButtonVariant.quiet, onPressed: () => unawaited(_reprint()))],
        )
      else if (data != null && data.isEmpty && answer.valueOrNull == null)
        PicksNotice(
          kicker: 'NOTHING TO GO ON YET',
          text: 'Read or follow a few series first. Picks start from what you read.',
          actions: [CineButton(label: 'Find something', onPressed: () => context.go(Routes.discover()))],
        )
      else ...[
        if (forYou.isNotEmpty) ...[
          CineSectionHeader(headingId: 'picks-for-you', heading: 'For you', folio: nextFolio()),
          SizedBox(height: c.space3),
          ForYouGrid(items: forYou),
          if (partial) Padding(padding: EdgeInsets.only(top: c.space3), child: CineRoleText("Some picks didn't come through.", c.typeCaption, color: c.colorInk60)),
          SizedBox(height: c.space8),
        ] else if (partial)
          Padding(padding: EdgeInsets.only(bottom: c.space6), child: CineRoleText("Some picks didn't come through.", c.typeCaption, color: c.colorInk60)),
        for (final s in sections) BecauseRail(section: s, folio: nextFolio(), pickedAgo: ago),
      ],
    ];

    return CineKeys(
      group: picksKeyGroup,
      keys: picksKeys(focusAsk: _ask.requestFocus, ask: _submitField, step: (fwd) => focusStep(context, forward: fwd)),
      child: Scaffold(
        backgroundColor: c.colorPaper0,
        body: SafeArea(
          child: CinePullToReprint(
            onRefresh: _reprint,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(pad, c.space6, pad, c.space10),
              children: children,
            ),
          ),
        ),
      ),
    );
  }
}
