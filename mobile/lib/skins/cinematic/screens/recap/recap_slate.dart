import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_notice.dart' show CineNoticeAction;
import 'package:manhwamaniacs/skins/cinematic/screens/discover/cine_extras.dart' show RetryCountdown;
import 'package:manhwamaniacs/skins/cinematic/screens/discover/cine_kit.dart' show TypedText;
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// A recap that will not stream: one static slate set like a short article, with its way onward.
/// The kicker is `ink.60` (never a `NOTE`, never `proof`), except a correction. A rate limit adds
/// a `SLOW DOWN` line with the live `Retry-After`. Extra widgets (the scan block) sit under it.
class RecapSlate extends StatelessWidget {
  const RecapSlate({
    super.key,
    required this.kicker,
    required this.headline,
    required this.primary,
    this.quiet,
    this.deck,
    this.retryAfter,
    this.error = false,
    this.extra = const [],
  });

  final String kicker, headline;
  final String? deck;
  final CineNoticeAction primary;
  final CineNoticeAction? quiet;
  final Duration? retryAfter;
  final bool error;
  final List<Widget> extra;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    return Semantics(
      container: true,
      liveRegion: true,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
        SizedBox(height: c.ruleHeavy.width, child: const CineRuleDraw(kind: CineRuleKind.heavy)),
        SizedBox(height: c.space4),
        CineRoleText(kicker, c.typeKicker, color: error ? c.colorProof : c.colorInk60),
        SizedBox(height: c.space2),
        TypedText(headline, style: CineText.style(context, c.typePull).copyWith(color: c.colorInk100)),
        if (retryAfter != null) ...[
          SizedBox(height: c.space3),
          CineRoleText('SLOW DOWN', c.typeKicker, color: c.colorInk60),
          SizedBox(height: c.space1),
          RetryCountdown(seconds: retryAfter!.inSeconds, prefix: 'Too many asks at once. Try again in', style: CineText.style(context, c.typeDeck).copyWith(color: c.colorInk60)),
        ],
        if (deck != null) ...[SizedBox(height: c.space3), CineRoleText(deck!, c.typeDeck, color: c.colorInk60)],
        SizedBox(height: c.space5),
        Wrap(spacing: c.space4, runSpacing: c.space2, crossAxisAlignment: WrapCrossAlignment.center, children: [
          CineButton(label: primary.label, onPressed: primary.onPressed),
          if (quiet != null) CineButton(label: quiet!.label, variant: CineButtonVariant.quiet, onPressed: quiet!.onPressed),
        ],),
        for (final w in extra) ...[SizedBox(height: c.space4), w],
      ],),
    );
  }
}
