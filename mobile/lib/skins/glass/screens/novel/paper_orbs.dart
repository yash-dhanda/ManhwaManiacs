import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/core/color/cover_palette.dart';
import 'package:manhwamaniacs/features/novels/models/glass_novel_prefs.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/press.dart';
import 'package:manhwamaniacs/skins/glass/screens/novel/papers.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart';

/// The papers as seven 44 px orbs (H7): the paper's colour with "Aa" in its ink and a specular highlight at the light angle; the Glass
/// orb shows the book's palette. A radio group named by paper.
class NovelPaperOrbs extends StatelessWidget {
  const NovelPaperOrbs({super.key, required this.selected, required this.onSelected, this.palette, this.lightAngle = -0.75});
  final GlassPaper selected;
  final void Function(GlassPaper paper, Offset globalCentre) onSelected;
  final CoverPalette? palette;

  /// Radians; the specular highlight sits toward it.
  final double lightAngle;

  @override
  Widget build(BuildContext context) => Semantics(
        container: true,
        label: 'Paper',
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [for (final p in GlassPaper.values) _Orb(paper: p, selected: p == selected, onSelected: onSelected, palette: palette, lightAngle: lightAngle)],
        ),
      );
}

class _Orb extends StatelessWidget {
  const _Orb({required this.paper, required this.selected, required this.onSelected, required this.palette, required this.lightAngle});
  final GlassPaper paper;
  final bool selected;
  final void Function(GlassPaper paper, Offset globalCentre) onSelected;
  final CoverPalette? palette;
  final double lightAngle;

  @override
  Widget build(BuildContext context) {
    final c = paperColors(paper);
    final colours = palette?.a ?? const <Color>[];
    final glass = paper == GlassPaper.glass && colours.isNotEmpty;
    final hit = GlassFrame.hitMin(context);
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      label: paper.label,
      button: true,
      excludeSemantics: true,
      onTap: () => _tap(context),
      child: GlassPressable(
        key: ValueKey('paper-orb-${paper.wire}'),
        material: GlassMaterial.content,
        shape: const GlassShape.circle(),
        sink: 0.92,
        noSemantics: true,
        onTap: () => _tap(context),
        builder: (context, info) => SizedBox.square(
          dimension: hit,
          child: Center(
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: c.bg,
                gradient: glass
                    ? RadialGradient(center: const Alignment(-0.4, -0.5), colors: [for (final x in colours.take(3)) x.withValues(alpha: 0.55), c.bg])
                    : null,
                border: selected ? Border.fromBorderSide(gt.borderSelectedRing) : Border.all(color: const Color(0x38FFFFFF)),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // The specular highlight toward the light.
                  Align(
                    alignment: Alignment(0.6 * math.cos(lightAngle), 0.6 * math.sin(lightAngle)),
                    child: const SizedBox(
                      width: 14,
                      height: 8,
                      child: DecoratedBox(decoration: BoxDecoration(borderRadius: BorderRadius.all(Radius.circular(8)), gradient: RadialGradient(colors: [Color(0x66FFFFFF), Color(0x00FFFFFF)]))),
                    ),
                  ),
                  Center(child: Text('Aa', textScaler: TextScaler.noScaling, style: TextStyle(fontFamily: 'LiterataMM', fontSize: 15, color: c.ink, fontVariations: const [FontVariation('wght', 500)]))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _tap(BuildContext context) {
    final ro = context.findRenderObject();
    final centre = ro is RenderBox && ro.hasSize ? ro.localToGlobal(ro.size.center(Offset.zero)) : Offset.zero;
    onSelected(paper, centre);
  }
}
