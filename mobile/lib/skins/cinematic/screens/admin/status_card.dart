import 'package:flutter/material.dart';
import 'package:manhwamaniacs/features/admin/utils/status_summary.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_image.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// The tint of a state on `paper.0`: `set` healthy, `spot` warning, `proof` down, `ink.60` unknown
/// (`ink.45` is only for `paper.0` folios; cards and banners take `ink.60`).
Color stateColor(CineTokens c, StatusState s) => switch (s) {
      StatusState.healthy => c.colorSet,
      StatusState.warning => c.colorSpot,
      StatusState.down => c.colorProof,
      StatusState.unknown => c.colorInk60,
    };

String stateWord(StatusState s) => switch (s) {
      StatusState.healthy => 'HEALTHY',
      StatusState.warning => 'WARNING',
      StatusState.down => 'DOWN',
      StatusState.unknown => 'UNKNOWN',
    };

/// A status card: a kicker over a hairline and then its body, its loading (greeked at the exact
/// heights of the rows it will hold) or its error (`CORRECTION` and a `Retry` for this card only).
class StatusCard extends StatelessWidget {
  const StatusCard({
    super.key,
    required this.kicker,
    required this.child,
    this.loading = false,
    this.greekRows = 4,
    this.error,
    this.onRetry,
  });

  final String kicker;
  final Widget child;
  final bool loading;
  final int greekRows;
  final String? error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final Widget body;
    if (error != null) {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: 'CORRECTION  ', style: CineText.style(context, c.typeKicker).copyWith(color: c.colorProof)),
                TextSpan(text: error, style: CineText.style(context, c.typeCaption).copyWith(color: c.colorInk60)),
              ],
            ),
          ),
          SizedBox(height: c.space2),
          CineButton(label: 'Retry', variant: CineButtonVariant.quiet, size: CineButtonSize.sm, onPressed: onRetry),
        ],
      );
    } else if (loading) {
      body = Column(
        key: const Key('status-greek'),
        children: [
          for (var i = 0; i < greekRows; i++)
            SizedBox(height: 40, child: Padding(padding: EdgeInsets.symmetric(vertical: c.space1), child: const CinePlate(flicker: true))),
        ],
      );
    } else {
      body = child;
    }
    return Padding(
      padding: EdgeInsets.only(top: c.space8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(header: true, child: CineRoleText(kicker, c.typeKicker, color: c.colorInk60)),
          SizedBox(height: c.space2),
          Container(height: 1, color: c.colorRule1),
          SizedBox(height: c.space2),
          body,
        ],
      ),
    );
  }
}

/// One label/value pair in the single credits column (label in `type.credit.label`, value in
/// `type.credit`, or Plex Mono when [mono]).
class StatusCredit extends StatelessWidget {
  const StatusCredit({super.key, required this.label, required this.value, this.color, this.mono = false});
  final String label, value;
  final Color? color;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    return Semantics(
      container: true,
      label: '$label: $value',
      excludeSemantics: true,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: c.space1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CineRoleText(label, c.typeCreditLabel, color: c.colorInk60),
            mono
                ? CineLit(value, CineFace.plexMono, 14, 20, wght: 500, color: color ?? c.colorInk100)
                : CineRoleText(value, c.typeCredit, color: color),
          ],
        ),
      ),
    );
  }
}

/// A server error in Plex Mono on `paper.1`, text `ink.60`.
class ErrorBlock extends StatelessWidget {
  const ErrorBlock(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    return Container(
      width: double.infinity,
      color: c.colorPaper1,
      padding: EdgeInsets.all(c.space3),
      child: SelectableText(text, style: CineText.literal(context, CineFace.plexMono, 12, 16).copyWith(color: c.colorInk60)),
    );
  }
}
