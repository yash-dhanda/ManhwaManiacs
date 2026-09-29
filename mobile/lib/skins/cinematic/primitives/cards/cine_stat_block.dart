import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_galley.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// A stat block (cinematic 7.6): a 3 px heavy rule, a kicker, a `typeNumeral` value and a caption.
/// No frame. Loading shows a galley bar at the numeral's height; a new value cross-fades in 160 ms.
class CineStatBlock extends StatelessWidget {
  const CineStatBlock({super.key, required this.kicker, required this.value, this.caption, this.loading = false});
  final String kicker, value;
  final String? caption;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final reduced = CineMotion.reduced(context);
    final s = CineText.style(context, c.typeNumeral);
    final numeralH = (s.fontSize ?? 40) * (s.height ?? 1);
    return Semantics(
      label: '$kicker, ${loading ? 'loading' : value}${caption == null ? '' : ', $caption'}',
      excludeSemantics: true,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Container(height: c.ruleHeavy.width, color: c.colorInk100),
        SizedBox(height: c.space2),
        CineRoleText(kicker, c.typeKicker, color: c.colorInk45),
        SizedBox(height: c.space1),
        AnimatedSwitcher(
          duration: reduced ? Duration.zero : c.durBeat,
          child: loading
              ? CineGalleyNumeral(key: const ValueKey('loading'), size: numeralH)
              : CineRoleText(value, c.typeNumeral, key: ValueKey(value)),
        ),
        if (caption != null) ...[SizedBox(height: c.space1), CineRoleText(caption!, c.typeCaption, color: c.colorInk60)],
      ],),
    );
  }
}
