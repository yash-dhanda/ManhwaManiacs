import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/duotone.dart';
import 'package:manhwamaniacs/skins/cinematic/focus_ring.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_avatar.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_image.dart';
import 'package:manhwamaniacs/skins/cinematic/tint.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// A collection plate: a 16:9 mosaic of the first four member covers in duotone, the name over
/// `scrim.foot`, a credit line and the shared-with avatars (cinematic 7.6).
class CineCollectionPlate extends StatelessWidget {
  const CineCollectionPlate({
    super.key,
    required this.name,
    required this.credit,
    this.coverUrls = const [],
    this.duo,
    this.sharedWith = const [],
    this.selected = false,
    this.onTap,
  });

  final String name;

  /// `24 SERIES · SMART · SHARED`.
  final String credit;
  final List<String> coverUrls;
  final Color? duo;

  /// Avatar keys, 20 px, bottom-right.
  final List<String> sharedWith;

  /// Reorder mode: a 2 px `spot` inset frame.
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final reduced = CineMotion.reduced(context);
    final duotone = duo ?? c.colorAmbientFallbackDuo;
    return Semantics(
      button: onTap != null,
      selected: selected,
      label: '$name, $credit',
      excludeSemantics: true,
      onTap: onTap,
      child: CinePressable(
        hit: false,
        onTap: onTap,
        builder: (context, st) {
          final lit = st.hovered || st.focused;
          final nameStyle = CineText.style(context, c.typeSubhead);
          final textBlock = (nameStyle.fontSize ?? 20) * (nameStyle.height ?? 1.2) + 4 + 16 + 16;
          return AnimatedContainer(
            duration: reduced ? Duration.zero : (st.pressed ? c.durTick : c.durBeat),
            transform: Matrix4.translationValues(0, st.pressed ? 1 : 0, 0),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: LayoutBuilder(builder: (context, box) {
                final tiles = [for (var i = 0; i < 4; i++) i < coverUrls.length ? coverUrls[i] : null];
                Widget mosaic = CineDuotone(
                  duo: duotone,
                  child: GridView.count(
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    crossAxisCount: 2,
                    childAspectRatio: box.maxWidth / box.maxHeight,
                    children: [for (final u in tiles) CineImage(url: u)],
                  ),
                );
                mosaic = ClipRect(child: AnimatedScale(scale: lit && !reduced ? 1.03 : 1, duration: reduced ? Duration.zero : c.durClip, curve: c.easeSettle, child: mosaic));
                return Stack(fit: StackFit.expand, children: [
                  mosaic,
                  DecoratedBox(decoration: BoxDecoration(gradient: cineScrimFoot(solidAtPx: box.maxHeight - textBlock - 24, height: box.maxHeight))),
                  IgnorePointer(child: DecoratedBox(decoration: BoxDecoration(border: Border.all(color: c.colorHairlineArt)))),
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 12,
                    child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                          CineRoleText(name, c.typeSubhead, maxLines: 2, overflow: TextOverflow.ellipsis, decoration: lit ? TextDecoration.underline : null),
                          const SizedBox(height: 4),
                          CineRoleText(credit, c.typeCredit, color: c.colorInk80, maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],),
                      ),
                      for (final a in sharedWith.take(4)) Padding(padding: const EdgeInsets.only(left: 4), child: CineAvatar(avatarKey: a, size: 20)),
                    ],),
                  ),
                  if (selected) IgnorePointer(child: DecoratedBox(decoration: BoxDecoration(border: Border.all(color: c.colorSpot, width: 2)))),
                ],);
              },),
            ),
          );
        },
      ),
    );
  }
}
