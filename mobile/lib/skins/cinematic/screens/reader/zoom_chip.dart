import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// The `200%` chip top-centre while the zoom is changing (cinematic 8.14.5): shown for
/// `durHoldChip` (1200 ms) on the folio-flag ground.
class ReaderZoomChip extends StatelessWidget {
  const ReaderZoomChip({super.key, required this.zoom, required this.visible});

  final double zoom;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final top = MediaQuery.viewPaddingOf(context).top + 8;
    return Positioned(
      top: top,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: Center(
          child: AnimatedOpacity(
            opacity: visible ? 1 : 0,
            duration: c.durBeat,
            child: ExcludeSemantics(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                decoration: BoxDecoration(color: const Color(0xFF000000), border: Border.all(color: c.colorInk100)),
                child: CineRoleText('${(zoom * 100).round()}%', c.typeFolio, color: c.colorInk100),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
