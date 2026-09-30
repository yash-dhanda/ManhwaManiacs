import 'dart:async';


import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:manhwamaniacs/skins/cinematic/duotone.dart';
import 'package:manhwamaniacs/skins/cinematic/feedback.dart';
import 'package:manhwamaniacs/skins/cinematic/focus_ring.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_avatar.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_icon_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_image.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_menu.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/cinematic/tint.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// The mosaic of a collection (cinematic 7.6): up to four member covers as vertical strips, each
/// 25 % wide and full height (`BoxFit.cover` at `Alignment(0, -0.56)`, 1 px `#000` gaps; fewer than
/// four widen to fill), all in the collection's duotone. It is the `Hero` of the plate-to-header
/// match cut: [heroTag] tags it, and on iOS the flight follows the edge swipe.
class CineCollectionMosaic extends StatelessWidget {
  const CineCollectionMosaic({super.key, this.coverUrls = const [], this.duo, this.heroTag, this.heroOnGestures = false});

  final List<String> coverUrls;
  final Color? duo;
  final Object? heroTag;
  final bool heroOnGestures;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final urls = coverUrls.take(4).toList();
    Widget mosaic = CineDuotone(
      duo: duo ?? c.colorAmbientFallbackDuo,
      child: Row(children: [
        for (var i = 0; i < urls.length; i++) ...[
          if (i > 0) const SizedBox(width: 1, child: ColoredBox(color: Color(0xFF000000))),
          Expanded(child: CineImage(url: urls[i], alignment: const Alignment(0, -0.56))),
        ],
      ],),
    );
    if (urls.isEmpty) mosaic = ColoredBox(color: c.colorPaper1, child: const SizedBox.expand());
    mosaic = ClipRect(child: SizedBox.expand(child: mosaic));
    if (heroTag != null) mosaic = Hero(tag: heroTag!, transitionOnUserGestures: heroOnGestures, createRectTween: (a, b) => RectTween(begin: a, end: b), child: mosaic);
    return mosaic;
  }
}

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
    this.badges = const [],
    this.selected = false,
    this.onTap,
    this.tint,
    this.heroTag,
    this.heroOnGestures = false,
    this.dragHandle,
    this.moveEntries,
    this.semanticActions,
    this.focusNode,
    this.menuOnLongPress = true,
  });

  final String name;

  /// `24 SERIES · SMART · SHARED`.
  final String credit;
  final List<String> coverUrls;
  final Color? duo;

  /// Avatar keys, 20 px, bottom-right.
  final List<String> sharedWith;

  /// Badges at the top-left (`SHARED`), 8 px in.
  final List<Widget> badges;

  /// Reorder mode: a 2 px `spot` inset frame.
  final bool selected;
  final VoidCallback? onTap;

  /// The solid end of `scrim.foot`: the first member's `ambient.tint`, else `#0E0D0B`.
  final Color? tint;

  /// The mosaic's `Hero` tag (`('collection', id)`).
  final Object? heroTag;
  final bool heroOnGestures;

  /// A 40 px `on-art` `dots-six-vertical` handle, bottom-left (Custom order).
  final Widget? dragHandle;

  /// The row menu the long-press opens (Move up, Move down, Move to top, Move to bottom).
  final List<CineMenuEntry<Object?>>? moveEntries;
  final Map<CustomSemanticsAction, VoidCallback>? semanticActions;
  final FocusNode? focusNode;

  /// False in Custom order on a phone, where the long-press starts the drag.
  final bool menuOnLongPress;

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
      customSemanticsActions: semanticActions,
      child: CinePressable(
        hit: false,
        focusNode: focusNode,
        onTap: onTap,
        onLongPress: !menuOnLongPress || moveEntries == null || moveEntries!.isEmpty
            ? null
            : () {
                cineFeedback(context, HapticEvent.longpressOpen);
                unawaited(showCineMenu<Object?>(context, anchor: cineAnchorRect(context), entries: moveEntries!));
              },
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
                final empty = coverUrls.isEmpty;
                if (empty) {
                  return DecoratedBox(
                    decoration: BoxDecoration(color: c.colorPaper1, border: Border.all(color: c.colorRule2)),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Align(
                        alignment: Alignment.bottomLeft,
                        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                          CineRoleText(name, c.typeSubhead, maxLines: 2, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          CineRoleText(credit, c.typeCredit, color: c.colorInk60, maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],),
                      ),
                    ),
                  );
                }
                Widget mosaic = CineCollectionMosaic(coverUrls: coverUrls, duo: duotone, heroTag: heroTag, heroOnGestures: heroOnGestures);
                mosaic = AnimatedScale(scale: lit && !reduced ? 1.03 : 1, duration: reduced ? Duration.zero : c.durClip, curve: c.easeSettle, child: mosaic);
                return Stack(fit: StackFit.expand, children: [
                  mosaic,
                  DecoratedBox(decoration: BoxDecoration(gradient: cineScrimFoot(solidAtPx: box.maxHeight - textBlock - 24, height: box.maxHeight, tint: tint ?? c.colorAmbientFallbackTint))),
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
                  if (badges.isNotEmpty) Positioned(left: 8, top: 8, child: Wrap(spacing: 4, children: badges)),
                  if (dragHandle != null) Positioned(left: 0, bottom: 0, child: dragHandle!),
                  if (moveEntries != null && moveEntries!.isNotEmpty)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Builder(
                        builder: (btn) => CineIconButton(
                          label: 'More actions',
                          codepoint: CineGlyph.dotsThree,
                          variant: CineIconButtonVariant.onArt,
                          onPressed: () => unawaited(showCineMenu<Object?>(btn, anchor: cineAnchorRect(btn), entries: moveEntries!)),
                        ),
                      ),
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
