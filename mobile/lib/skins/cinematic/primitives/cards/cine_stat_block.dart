import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_galley.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/raised_folio.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// A stat block (cinematic 7.6): a 3 px heavy rule, a kicker, a `typeNumeral` value and a caption.
/// No frame. Loading shows a galley bar at the numeral's height; a new value cross-fades in 160 ms.
class CineStatBlock extends StatelessWidget {
  const CineStatBlock({
    super.key,
    required this.kicker,
    required this.value,
    this.caption,
    this.loading = false,
    this.footnote,
    this.signature = false,
    this.ruleDelay = Duration.zero,
  });
  final String kicker, value;
  final String? caption;
  final bool loading;

  /// A raised folio after the caption (The Numbers' footnote marks).
  final int? footnote;

  /// The first-paint moment (cinematic 13, moment 13): the rule draws left to right after
  /// [ruleDelay] and the numeral types 120 ms after its rule starts.
  final bool signature;
  final Duration ruleDelay;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final reduced = CineMotion.reduced(context);
    final s = CineText.style(context, c.typeNumeral);
    final numeralH = (s.fontSize ?? 40) * (s.height ?? 1);
    return Semantics(
      label: '$kicker, ${loading ? 'loading' : value}${caption == null ? '' : ', $caption'}${footnote == null ? '' : ', footnote $footnote'}',
      excludeSemantics: true,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        signature ? CineRuleDraw(kind: CineRuleKind.heavy, delay: ruleDelay) : Container(height: c.ruleHeavy.width, color: c.colorInk100),
        SizedBox(height: c.space2),
        CineRoleText(kicker, c.typeKicker, color: c.colorInk45),
        SizedBox(height: c.space1),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: AnimatedSwitcher(
          duration: reduced ? Duration.zero : c.durBeat,
          child: loading
              ? CineGalleyNumeral(key: const ValueKey('loading'), size: numeralH)
              : signature
                  ? TypedHeadline(
                      value,
                      key: ValueKey(value),
                      style: s.copyWith(color: c.colorInk100, fontFeatures: const [FontFeature.liningFigures(), FontFeature.tabularFigures()]),
                      cap: c.typeNumeral.cap,
                      delay: ruleDelay + const Duration(milliseconds: 120),
                    )
                  : CineRoleText(value, c.typeNumeral, key: ValueKey(value), maxLines: 1),
          ),
        ),
        if (caption != null) ...[
          SizedBox(height: c.space1),
          if (footnote == null)
            CineRoleText(caption!, c.typeCaption, color: c.colorInk60)
          else
            CaptionWithFolio(caption!, footnote!, style: CineText.style(context, c.typeCaption).copyWith(color: c.colorInk60), scaler: CineText.scaler(context, c.typeCaption)),
        ],
      ],),
    );
  }
}
