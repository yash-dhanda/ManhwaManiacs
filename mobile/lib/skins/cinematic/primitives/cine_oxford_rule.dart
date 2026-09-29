import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

/// The Oxford rule (cinematic 2.6): 3 px, a 2 px gap and 1 px, all `ink.100`. [spotLead] paints its
/// first 12 % in `spot` (the wordmark, 12.2).
class CineOxfordRule extends StatelessWidget {
  const CineOxfordRule({super.key, this.spotLead = false});
  final bool spotLead;

  @override
  Widget build(BuildContext context) {
    final r = context.cine.ruleOxford;
    Widget line(double h) => LayoutBuilder(
          builder: (_, box) => SizedBox(
            height: h,
            width: double.infinity,
            child: Row(children: [
              if (spotLead) SizedBox(width: box.maxWidth * 0.12, child: ColoredBox(color: context.cine.colorSpot)),
              Expanded(child: ColoredBox(color: r.color)),
            ],),
          ),
        );
    return ExcludeSemantics(
      child: Column(mainAxisSize: MainAxisSize.min, children: [line(r.thick), SizedBox(height: r.gap), line(r.thin)]),
    );
  }
}
