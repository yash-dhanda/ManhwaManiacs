import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/hit.dart';
import 'package:manhwamaniacs/skins/cinematic/icons/cine_icon.dart';
import 'package:manhwamaniacs/skins/cinematic/icons/icon_roles.g.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_icon_button.dart';
import 'package:manhwamaniacs/skins/cinematic/scrim_head.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';

/// The leading control of a pushed screen (a `bare` `arrow-left`, "Back").
class CineBack {
  const CineBack([this.onPressed]);

  /// Defaults to popping the route.
  final VoidCallback? onPressed;
}

/// A trailing `bare` icon button of the running head (at most two).
class CineHeadAction {
  const CineHeadAction({required this.role, required this.label, required this.onPressed, this.count});
  final CineIconRole role;
  final String label;
  final VoidCallback? onPressed;
  final int? count;
}

/// Where the offline edition badge is in its life (cinematic 7.13).
enum CineEditionPhase { none, badge, glyph, backOnline }

/// The phone running head (cinematic 7.13), a pure view: min height `cineHitMin` plus the top
/// inset, growing to the title line + 2 x 12 px; leading back, the running title centred in
/// `typeNav` `ink.60` (cross-fading in over 160 ms once the masthead is under the bar), up to two
/// trailing icon buttons; transparent over a masthead or art, `#000` with a 1 px `rule.1` bottom
/// once [solid]; [overArt] paints `scrimHead(bar, 44)` behind it.
class CineRunningHead extends StatelessWidget {
  const CineRunningHead({
    super.key,
    required this.title,
    this.titleVisible = true,
    this.back,
    this.trailing = const [],
    this.chip,
    this.solid = false,
    this.overArt = false,
    this.edition = CineEditionPhase.none,
    this.onEditionGlyph,
    this.titleFocusNode,
  });

  final String title;
  final bool titleVisible;
  final CineBack? back;
  final List<CineHeadAction> trailing;

  /// The content-mode chip, first in the trailing slot.
  final Widget? chip;
  final bool solid, overArt;
  final CineEditionPhase edition;
  final VoidCallback? onEditionGlyph;

  /// Takes route focus when the screen has no masthead node of its own.
  final FocusNode? titleFocusNode;

  static const Duration fade = Duration(milliseconds: 160);

  @override
  Widget build(BuildContext context) {
    assert(trailing.length <= 2, 'a running head has at most two trailing icons');
    final c = context.cine;
    final hit = cineHitMin(context);
    final top = MediaQuery.viewPaddingOf(context).top;
    final left = MediaQuery.viewPaddingOf(context).left;
    final right = MediaQuery.viewPaddingOf(context).right;
    final margin = c.space4;
    final sideL = left + 8 > margin ? left + 8 : margin;
    final sideR = right + 8 > margin ? right + 8 : margin;
    final showBadge = edition == CineEditionPhase.badge || edition == CineEditionPhase.backOnline;
    final trailingWidth = hit * trailing.length + (edition == CineEditionPhase.glyph ? hit : 0);
    final sideWidth = hit > trailingWidth ? hit : trailingWidth;

    final row = Stack(alignment: Alignment.center, children: [
      Padding(
        padding: EdgeInsets.symmetric(horizontal: sideWidth + 8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: AnimatedOpacity(
            opacity: titleVisible ? 1 : 0,
            duration: CineMotion.reduced(context) ? Duration.zero : fade,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Focus(
                focusNode: titleFocusNode,
                canRequestFocus: titleFocusNode != null,
                skipTraversal: true,
                child: Semantics(
                  header: true,
                  child: CineRoleText(title, c.typeNav, color: c.colorInk60, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
                ),
              ),
              if (showBadge)
                Padding(
                  padding: EdgeInsets.only(top: c.space1),
                  child: _EditionBadge(text: edition == CineEditionPhase.backOnline ? 'BACK ONLINE' : 'OFFLINE EDITION'),
                ),
            ],),
          ),
        ),
      ),
      if (back != null)
        Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            width: hit,
            height: hit,
            child: CineIconButton(
              label: 'Back',
              role: CineIconRole.back,
              onPressed: back!.onPressed ?? () => Navigator.maybeOf(context)?.maybePop(),
            ),
          ),
        ),
      Align(
        alignment: Alignment.centerRight,
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (chip != null) chip!,
          if (edition == CineEditionPhase.glyph)
            Semantics(
              button: true,
              label: 'Offline edition',
              excludeSemantics: true,
              onTap: onEditionGlyph,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onEditionGlyph,
                child: SizedBox(
                  width: hit,
                  height: hit,
                  child: Center(child: CineIcon(CineIconRole.offline, size: 16, color: c.colorInk60)),
                ),
              ),
            ),
          for (final a in trailing)
            SizedBox(
              width: hit,
              height: hit,
              child: CineIconButton(label: a.label, role: a.role, onPressed: a.onPressed, count: a.count),
            ),
        ],),
      ),
    ],);

    final body = Container(
      constraints: BoxConstraints(minHeight: hit + top),
      padding: EdgeInsets.only(top: top, left: sideL - margin > 0 ? sideL - margin : 0, right: sideR - margin > 0 ? sideR - margin : 0),
      decoration: BoxDecoration(
        color: solid ? const Color(0xFF000000) : const Color(0x00000000),
        border: Border(bottom: solid ? c.ruleHair : BorderSide.none),
      ),
      child: Padding(padding: EdgeInsets.symmetric(horizontal: margin - 8 > 0 ? margin - 8 : 0), child: row),
    );

    return Stack(clipBehavior: Clip.none, children: [
      if (overArt && !solid) scrimHeadLayer(fade: 44),
      body,
    ],);
  }
}

class _EditionBadge extends StatelessWidget {
  const _EditionBadge({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(color: const Color(0xFF000000), border: Border.all(color: c.colorInk45)),
      child: CineRoleText(text, c.typeMicro, color: c.colorInk45, maxLines: 1),
    );
  }
}
