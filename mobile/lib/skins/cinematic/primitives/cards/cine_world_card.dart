import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/duotone.dart';
import 'package:manhwamaniacs/skins/cinematic/feedback.dart';
import 'package:manhwamaniacs/skins/cinematic/focus_ring.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_badge.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_icon_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_image.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/cinematic/stock.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// available: on the person's sources; infoOnly: worldwide catalogue, not on their sources;
/// shelf: an item of a source's own shelf.
enum CineWorldKind { available, infoOnly, shelf }

/// A World card (cinematic 7.6): poster left, kicker, title, a pull quote with a 2 px `spot` left
/// rule, and the credit line. Info-only posters are duotone (black -> ambient duo).
class CineWorldCard extends StatelessWidget {
  const CineWorldCard({
    super.key,
    required this.kind,
    required this.title,
    required this.kicker,
    this.imageUrl,
    this.why,
    this.credit,
    this.byline,
    this.duo,
    this.adult = false,
    this.gateOpen = false,
    this.readOnLabel,
    this.onOpen,
    this.onSearchMySources,
    this.onReadOn,
    this.onDismiss,
    this.onLongPress,
    this.withCredentials = true,
  });

  final CineWorldKind kind;
  final String title;

  /// `MANHWA · ONGOING · ★ 8.4`, or `{SOURCE NAME} · {n} CHAPTERS` for a shelf.
  final String kicker;
  final String? imageUrl, why, credit, byline, readOnLabel;
  final Color? duo;

  /// The item is mature (18+) and the gate is open: the 16 px certificate shows top-left.
  final bool adult, gateOpen;
  final VoidCallback? onOpen, onSearchMySources, onReadOn, onDismiss, onLongPress;
  final bool withCredentials;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final reduced = CineMotion.reduced(context);
    final info = kind == CineWorldKind.infoOnly;
    return Semantics(
      button: !info,
      label: '$title, $kicker${credit == null ? '' : ', $credit'}',
      excludeSemantics: info ? false : true,
      onTap: info ? null : onOpen,
      onLongPress: onLongPress,
      child: CinePressable(
        hit: false,
        onTap: info ? null : onOpen,
        enabled: !info,
        onLongPress: onLongPress == null
            ? null
            : () {
                cineFeedback(context, HapticEvent.longpressOpen);
                onLongPress!();
              },
        builder: (context, st) {
          final lit = st.hovered || st.focused;
          Widget poster = CineImage(url: imageUrl, title: title, withCredentials: withCredentials);
          if (info) poster = CineDuotone(duo: duo ?? c.colorAmbientFallbackDuo, child: poster);
          poster = ClipRect(child: AnimatedScale(scale: lit && !reduced ? 1.04 : 1, duration: reduced ? Duration.zero : c.durClip, curve: c.easeSettle, child: poster));
          return AnimatedContainer(
            duration: reduced ? Duration.zero : (st.pressed ? c.durTick : c.durBeat),
            transform: Matrix4.translationValues(0, st.pressed ? 1 : 0, 0),
            child: CineStock.raised(Builder(
              builder: (context) => Stack(clipBehavior: Clip.none, children: [
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  SizedBox(
                    width: 104,
                    child: AspectRatio(
                      aspectRatio: 2 / 3,
                      child: Stack(fit: StackFit.expand, children: [
                        poster,
                        IgnorePointer(child: DecoratedBox(decoration: BoxDecoration(border: Border.all(color: c.colorHairlineArt)))),
                        if (adult && gateOpen) Positioned(left: 4, top: 4, child: CineBadge.certificate(onArt: true)),
                      ],),
                    ),
                  ),
                  SizedBox(width: c.space3),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                      CineRoleText(kicker, c.typeKicker, color: context.cine.colorInk45, maxLines: 2, overflow: TextOverflow.ellipsis),
                      SizedBox(height: c.space1),
                      CineRoleText(title, c.typeTitle, maxLines: 2, overflow: TextOverflow.ellipsis, decoration: lit && !info ? TextDecoration.underline : null),
                      if (byline != null) ...[SizedBox(height: c.space1), CineRoleText('by $byline', c.typeCaption, color: context.cine.colorInk60, maxLines: 1, overflow: TextOverflow.ellipsis)],
                      if (why != null) ...[
                        SizedBox(height: c.space2),
                        Container(
                          padding: const EdgeInsets.only(left: 10),
                          decoration: BoxDecoration(border: Border(left: BorderSide(color: c.colorSpot, width: 2))),
                          child: CineRoleText(why!, c.typeBodyItalic, color: context.cine.colorInk80, maxLines: 3, overflow: TextOverflow.ellipsis),
                        ),
                      ],
                      if (credit != null) ...[SizedBox(height: c.space2), CineRoleText(credit!, c.typeCredit, color: context.cine.colorInk45, maxLines: 1, overflow: TextOverflow.ellipsis)],
                      if (info)
                        Wrap(spacing: c.space1, children: [
                          CineButton(label: 'Search my sources', variant: CineButtonVariant.quiet, size: CineButtonSize.sm, onPressed: onSearchMySources),
                          CineButton(label: 'Read on ${readOnLabel ?? 'the site'} ↗', variant: CineButtonVariant.quiet, size: CineButtonSize.sm, onPressed: onReadOn),
                        ],),
                    ],),
                  ),
                ],),
                if (onDismiss != null && lit)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: CineIconButton(label: 'Not for me', codepoint: CineGlyph.x, variant: CineIconButtonVariant.onArt, onPressed: onDismiss),
                  ),
              ],),
            ),),
          );
        },
      ),
    );
  }
}
