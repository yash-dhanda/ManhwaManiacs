import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/focus_ring.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/ambient_scope.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_galley.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_image.dart';
import 'package:manhwamaniacs/skins/cinematic/stock.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// A Feature card (cinematic 7.6): image 4:5, kicker, a two-line `typeSubhead` headline and a
/// two-line italic deck; no frame.
class CineFeatureCard extends StatelessWidget {
  const CineFeatureCard({
    super.key,
    required this.title,
    this.kicker,
    this.deck,
    this.imageUrl,
    this.onTap,
    this.loading = false,
    this.error = false,
    this.ambientKicker = false,
    this.heroTag,
  });

  final String title;
  final String? kicker, deck, imageUrl;
  final VoidCallback? onTap;
  final bool loading, error;

  /// Kicker in the series' `ambient.ink` (needs a [CineAmbient] above) instead of `ink.45`.
  final bool ambientKicker;

  /// The `(sourceId, seriesKey)` Hero tag of the match cut to the series page.
  final (String, String)? heroTag;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final reduced = CineMotion.reduced(context);
    return Semantics(
      button: onTap != null,
      label: [if (kicker != null) kicker, title, if (deck != null) deck].join(', '),
      excludeSemantics: true,
      onTap: onTap,
      child: CinePressable(
        hit: false,
        onTap: onTap,
        builder: (context, st) {
          final lit = st.hovered || st.focused;
          Widget image;
          if (loading) {
            image = const CineGalleyPlate();
          } else if (error) {
            image = CinePlate(title: title, error: true);
          } else {
            image = CineImage(url: imageUrl, title: title);
          }
          if (heroTag != null) image = Hero(tag: heroTag!, transitionOnUserGestures: defaultTargetPlatform == TargetPlatform.iOS, child: image);
          image = ClipRect(child: AnimatedScale(scale: lit && !reduced ? 1.04 : 1, duration: reduced ? Duration.zero : c.durClip, curve: c.easeSettle, child: image));
          final tokens = c;
          return AnimatedContainer(
            duration: reduced ? Duration.zero : (st.pressed ? c.durTick : c.durBeat),
            transform: Matrix4.translationValues(0, st.pressed ? 1 : 0, 0),
            child: CineStock.raised(Builder(
              builder: (context) => Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                AspectRatio(aspectRatio: 4 / 5, child: image),
                SizedBox(height: tokens.space3),
                if (loading) ...[
                  const CineGalleyLine(lineHeight: 16),
                  CineGalleyHeadline(lineHeight: CineText.style(context, tokens.typeSubhead).fontSize! * (CineText.style(context, tokens.typeSubhead).height ?? 1.2)),
                  const CineGalleyLine(lineHeight: 20, index: 1),
                  const CineGalleyLine(lineHeight: 20, index: 3),
                ] else ...[
                  if (kicker != null)
                    CineRoleText(kicker!, tokens.typeKicker, color: ambientKicker ? CineAmbient.of(context).ink : context.cine.colorInk45, maxLines: 1, overflow: TextOverflow.ellipsis),
                  SizedBox(height: tokens.space1),
                  CineRoleText(title, tokens.typeSubhead, maxLines: 2, overflow: TextOverflow.ellipsis),
                  if (deck != null) ...[
                    SizedBox(height: tokens.space1),
                    CineRoleText(deck!, tokens.typeBodyItalic, color: context.cine.colorInk60, maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ],
              ],),
            ),),
          );
        },
      ),
    );
  }
}
