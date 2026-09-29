import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/a11y/folio.dart';
import 'package:manhwamaniacs/skins/cinematic/feedback.dart';
import 'package:manhwamaniacs/skins/cinematic/focus_ring.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_badge.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_galley.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_image.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_progress.dart';
import 'package:manhwamaniacs/skins/cinematic/stock.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// A Cutting (Continue reading): a 3:2 crop biased to the top, a 2 px `spot` progress rule flush
/// on the image's bottom edge, a one-line title and a folio caption (cinematic 7.6).
class CineCuttingCard extends StatelessWidget {
  const CineCuttingCard({
    super.key,
    required this.title,
    required this.folio,
    this.imageUrl,
    this.progress,
    this.nudge,
    this.onTap,
    this.onQuickLook,
    this.loading = false,
    this.error = false,
  });

  final String title;

  /// `CH 142 · 63%` or `NEXT · CH 143`.
  final String folio;
  final String? imageUrl;

  /// 0..1: the 2 px `spot` rule on the image's bottom edge.
  final double? progress;

  /// `3 NEW`, `ALMOST DONE`, `PAUSED 21 D`: badge top-left.
  final String? nudge;
  final VoidCallback? onTap, onQuickLook;
  final bool loading, error;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final reduced = CineMotion.reduced(context);
    return Semantics(
      button: true,
      label: '$title, ${folioLabel(folio)}${nudge == null ? '' : ', ${folioLabel(nudge!)}'}',
      excludeSemantics: true,
      onTap: onTap,
      onLongPress: onQuickLook,
      child: CinePressable(
        hit: false,
        onTap: onTap,
        onLongPress: onQuickLook == null
            ? null
            : () {
                cineFeedback(context, HapticEvent.longpressOpen);
                onQuickLook!();
              },
        builder: (context, st) {
          final lit = st.hovered || st.focused;
          Widget image = loading
              ? const CineGalleyPlate()
              : error
                  ? CinePlate(title: title, error: true)
                  : CineImage(url: imageUrl, title: title, alignment: const Alignment(0, -0.56));
          image = ClipRect(child: AnimatedScale(scale: lit && !reduced ? 1.04 : 1, duration: reduced ? Duration.zero : c.durClip, curve: c.easeSettle, child: image));
          return AnimatedContainer(
            duration: reduced ? Duration.zero : (st.pressed ? c.durTick : c.durBeat),
            transform: Matrix4.translationValues(0, st.pressed ? 1 : 0, 0),
            child: CineStock.raised(Builder(
              builder: (context) => Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                AspectRatio(
                  aspectRatio: 3 / 2,
                  child: Stack(fit: StackFit.expand, children: [
                    image,
                    IgnorePointer(child: DecoratedBox(decoration: BoxDecoration(border: Border.all(color: c.colorHairlineArt)))),
                    if (progress != null) Positioned(left: 0, right: 0, bottom: 0, child: CinePosterProgress(value: progress!)),
                    if (nudge != null)
                      Positioned(
                        left: 4,
                        top: 4,
                        child: nudge!.toUpperCase().endsWith('NEW')
                            ? CineBadge(nudge!, variant: CineBadgeVariant.newCount)
                            : CineBadge(nudge!, variant: CineBadgeVariant.text, onArt: true),
                      ),
                  ],),
                ),
                SizedBox(height: c.space2),
                CineRoleText(title, c.typeTitle, maxLines: 1, overflow: TextOverflow.ellipsis, decoration: lit ? TextDecoration.underline : null),
                SizedBox(height: c.space1 / 2),
                CineRoleText(folio, c.typeFolio, color: context.cine.colorInk45, maxLines: 1, overflow: TextOverflow.ellipsis),
              ],),
            ),),
          );
        },
      ),
    );
  }
}
