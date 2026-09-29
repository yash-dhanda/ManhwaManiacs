import 'dart:async';

import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_image.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

const List<int> _ragged = [92, 78, 96, 64, 88];

/// A galley-proof text line (cinematic 7.17): a bar in `galley` at 50 % of the line height,
/// vertically centred, ragged width, flickering with a reading-order phase. Never a shimmer.
class CineGalleyLine extends StatelessWidget {
  const CineGalleyLine({super.key, required this.lineHeight, this.index = 0});
  final double lineHeight;
  final int index;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: CineFlicker(
          index: index,
          child: SizedBox(
            height: lineHeight,
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: _ragged[index % _ragged.length] / 100,
                heightFactor: 0.5,
                child: ColoredBox(color: context.cine.colorGalley),
              ),
            ),
          ),
        ),
      );
}

/// Two bars at the headline's line height, 60 % and 35 % wide.
class CineGalleyHeadline extends StatelessWidget {
  const CineGalleyHeadline({super.key, required this.lineHeight, this.index = 0});
  final double lineHeight;
  final int index;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          for (var i = 0; i < 2; i++)
            CineFlicker(
              index: index + i,
              child: SizedBox(
                height: lineHeight,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(widthFactor: i == 0 ? 0.6 : 0.35, heightFactor: 0.5, child: ColoredBox(color: context.cine.colorGalley)),
                ),
              ),
            ),
        ],),
      );
}

/// A `paper.1` plate with the inner hairline and an optional title card.
class CineGalleyPlate extends StatelessWidget {
  const CineGalleyPlate({super.key, this.title, this.index = 0});
  final String? title;
  final int index;

  @override
  Widget build(BuildContext context) => Stack(fit: StackFit.expand, children: [
        CinePlate(title: title, flicker: true, index: index),
        IgnorePointer(child: DecoratedBox(decoration: BoxDecoration(border: Border.all(color: context.cine.colorHairlineArt)))),
      ],);
}

/// One bar at 40 % of the numeral's size.
class CineGalleyNumeral extends StatelessWidget {
  const CineGalleyNumeral({super.key, required this.size, this.index = 0});
  final double size;
  final int index;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: CineFlicker(
          index: index,
          child: SizedBox(height: size, width: size * 1.2, child: Align(alignment: Alignment.centerLeft, child: SizedBox(height: size * 0.4, width: size * 0.9, child: ColoredBox(color: context.cine.colorGalley)))),
        ),
      );
}

/// Shows [child] only after [delay] of waiting (120 ms): a fast answer never flashes a skeleton.
class CineDelayed extends StatefulWidget {
  const CineDelayed({super.key, this.delay = const Duration(milliseconds: 120), required this.child});
  final Duration delay;
  final Widget child;

  @override
  State<CineDelayed> createState() => _CineDelayedState();
}

class _CineDelayedState extends State<CineDelayed> {
  Timer? _t;
  bool _show = false;

  @override
  void initState() {
    super.initState();
    _t = Timer(widget.delay, () {
      if (mounted) setState(() => _show = true);
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _show ? widget.child : const SizedBox.shrink();
}
