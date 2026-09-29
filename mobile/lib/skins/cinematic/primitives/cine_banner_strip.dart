import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

enum CineBannerTone { note, correction, plain }

class CineBannerAction {
  const CineBannerAction(this.label, this.onPressed);
  final String label;
  final VoidCallback onPressed;
}

/// A banner strip (cinematic 7.29): `paper.0` with a 2 px left rule in the tone colour (`spot`
/// NOTE, `proof` CORRECTION, `ink.100` plain), a kicker, one line and up to two `quiet` actions.
/// Callers place it under the running head.
class CineBannerStrip extends StatelessWidget {
  const CineBannerStrip({super.key, required this.line, this.kicker, this.tone = CineBannerTone.note, this.actions = const []})
      : assert(actions.length <= 2);

  final String line;
  final String? kicker;
  final CineBannerTone tone;
  final List<CineBannerAction> actions;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final edge = switch (tone) { CineBannerTone.note => c.colorSpot, CineBannerTone.correction => c.colorProof, CineBannerTone.plain => c.colorInk100 };
    final k = kicker ?? switch (tone) { CineBannerTone.note => 'NOTE', CineBannerTone.correction => 'CORRECTION', CineBannerTone.plain => null };
    return Semantics(
      container: true,
      label: [if (k != null) k, line].join(', '),
      child: Container(
        decoration: BoxDecoration(color: c.colorPaper0, border: Border(left: BorderSide(color: edge, width: 2), bottom: c.ruleHair)),
        padding: EdgeInsets.symmetric(horizontal: c.space4, vertical: c.space3),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              if (k != null) CineRoleText(k, c.typeKicker, color: tone == CineBannerTone.correction ? c.colorProof : (tone == CineBannerTone.note ? c.colorSpot : c.colorInk60)),
              CineRoleText(line, c.typeUi),
            ],),
          ),
          for (final a in actions) Padding(padding: EdgeInsets.only(left: c.space2), child: CineButton(label: a.label, variant: CineButtonVariant.quiet, onPressed: a.onPressed)),
        ],),
      ),
    );
  }
}
