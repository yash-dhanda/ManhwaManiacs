import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/cine_kit.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

/// The floating `TOP` square: 40 px, `paper.2`, 1 px `rule.2`, 44/48 hit.
class TopButton extends StatelessWidget {
  const TopButton({super.key, required this.controller});

  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    final t = context.cine;
    return Semantics(
      button: true,
      label: 'Back to top',
      excludeSemantics: true,
      child: InkWell(
        onTap: () {
          if (cineReduced(context)) {
            controller.jumpTo(0);
          } else {
            controller.animateTo(0, duration: CineDur.glide, curve: CineCurves.settle);
          }
        },
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: t.colorPaper2,
                border: Border.all(color: t.colorRule2),
              ),
              // TODO(icons): arrow-up is not in the generated Phosphor subset yet.
              child: Icon(Icons.arrow_upward, size: 20, color: t.colorInk100),
            ),
          ),
        ),
      ),
    );
  }
}
