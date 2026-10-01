import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/features/library/models/world_item.dart';
import 'package:manhwamaniacs/skins/cinematic/ai_copy.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/typed_text.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/cine_extras.dart' show RetryCountdown;
import 'package:manhwamaniacs/skins/cinematic/screens/discover/cine_kit.dart' show DelayedShow, LeaderDial;
import 'package:manhwamaniacs/skins/cinematic/screens/picks/world_card_tile.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// A short static notice: a kicker, one typed line and its actions. An AI notice is a `NOTE` in
/// `spot` (never `proof`); a rate limit is `SLOW DOWN` with the live wait.
class PicksNotice extends StatelessWidget {
  const PicksNotice({super.key, required this.kicker, required this.text, this.actions = const [], this.retryAfter, this.spot = false, this.error = false});
  final String kicker, text;
  final List<Widget> actions;
  final int? retryAfter;
  final bool spot, error;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    return Semantics(
      container: true,
      liveRegion: true,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
        CineRoleText(kicker, c.typeKicker, color: error ? c.colorProof : (spot ? c.colorSpot : c.colorInk60)),
        SizedBox(height: c.space2),
        if (retryAfter != null)
          RetryCountdown(seconds: retryAfter!, prefix: 'Too many asks at once. Try again in', style: CineText.style(context, c.typePull).copyWith(color: c.colorInk100))
        else
          TypedText.plain(text, key: ValueKey(text), style: CineText.style(context, c.typePull).copyWith(color: c.colorInk100)),
        if (actions.isNotEmpty) ...[SizedBox(height: c.space3), Wrap(spacing: c.space3, runSpacing: c.space1, children: actions)],
      ],),
    );
  }
}

/// Where the editors' answer lands (cinematic 9.1.3): the typed thinking line with a leader dial
/// after 1 s, the timeout copy, every failure of the ask by its `code`, or the result cards.
class EditorsSuggest extends StatelessWidget {
  const EditorsSuggest({
    super.key,
    required this.value,
    required this.timedOut,
    required this.everywhere,
    required this.onTryAgain,
    required this.onBrowseSources,
    required this.onAskEverywhere,
  });

  final AsyncValue<WorldSuggestResponse?> value;
  final bool timedOut, everywhere;
  final VoidCallback onTryAgain, onBrowseSources, onAskEverywhere;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    if (value.isLoading) {
      if (timedOut) {
        return PicksNotice(
          kicker: 'NOTE',
          spot: true,
          text: 'The editors took too long. Try a shorter description.',
          actions: [CineButton(label: 'Try again', variant: CineButtonVariant.quiet, onPressed: onTryAgain)],
        );
      }
      return Row(children: [
        Expanded(child: TypedText.plain(kAiThinkingPicks, style: CineText.style(context, c.typePull).copyWith(color: c.colorInk100))),
        SizedBox(width: c.space3),
        const DelayedShow(child: LeaderDial(size: 24)),
      ],);
    }
    if (value.hasError) return _error(context, value.error!);
    final items = value.valueOrNull?.items;
    if (items == null) return const SizedBox.shrink();
    if (items.isEmpty) {
      return PicksNotice(kicker: 'NOTE', spot: true, text: aiCopyForCode('ai_no_matches').text);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Semantics(header: true, child: CineRoleText('THE EDITORS SUGGEST', c.typeKicker, color: c.colorInk60)),
      SizedBox(height: c.space3),
      LayoutBuilder(builder: (context, box) {
        // Two columns from 600 dp, one column on phones.
        final cols = MediaQuery.sizeOf(context).width >= 600 ? 2 : 1;
        final w = (box.maxWidth - c.space3 * (cols - 1)) / cols;
        return Wrap(spacing: c.space3, runSpacing: c.space3, children: [
          for (var i = 0; i < items.length; i++)
            SizedBox(width: w, child: WorldCardTile(key: ValueKey('r-${items[i].title}-$i'), item: items[i], index: i, animateIn: true)),
        ],);
      },),
    ],);
  }

  Widget _error(BuildContext context, Object error) {
    final code = error is ApiError ? error.code : null;
    switch (code) {
      case 'suggest_shelf_empty':
        return PicksNotice(
          kicker: 'NOTHING TO PICK FROM YET',
          text: "There isn't enough in the catalogue cache yet. Browse a few sources, then ask again.",
          actions: [
            CineButton(label: 'Browse sources', onPressed: onBrowseSources),
            if (!everywhere) CineButton(label: 'Ask everywhere instead', variant: CineButtonVariant.quiet, onPressed: onAskEverywhere),
          ],
        );
      case 'ai_no_matches':
        return PicksNotice(kicker: 'NOTE', spot: true, text: aiCopyForCode('ai_no_matches').text);
      case 'rate_limited':
        final after = error is ApiError ? retryAfterSeconds(error) : null;
        return PicksNotice(kicker: 'SLOW DOWN', text: '', retryAfter: after ?? 12, actions: [CineButton(label: 'Try again', variant: CineButtonVariant.quiet, onPressed: onTryAgain)]);
      case 'ai_not_configured':
      case 'ai_budget_exhausted':
        final copy = aiCopyForCode(code);
        return PicksNotice(kicker: copy.kicker, spot: true, text: copy.text);
      case 'ai_failed':
        return PicksNotice(
          kicker: 'NOTE',
          spot: true,
          text: "The editors couldn't answer that one. Try describing it differently.",
          actions: [CineButton(label: 'Try again', variant: CineButtonVariant.quiet, onPressed: onTryAgain)],
        );
      default:
        return PicksNotice(
          kicker: 'CORRECTION',
          error: true,
          text: "The editors couldn't be reached.",
          actions: [CineButton(label: 'Try again', variant: CineButtonVariant.quiet, onPressed: onTryAgain)],
        );
    }
  }
}
