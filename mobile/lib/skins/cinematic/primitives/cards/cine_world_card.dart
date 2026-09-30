import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:manhwamaniacs/skins/cinematic/duotone.dart';
import 'package:manhwamaniacs/skins/cinematic/feedback.dart';
import 'package:manhwamaniacs/skins/cinematic/focus_ring.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_badge.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_icon_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_image.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_menu.dart';
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
///
/// Every AI card in the app is this widget. Not for me and More like this live in three places:
/// the long-press menu (450 ms), a trailing `dots-three` on the card (the visible alternative,
/// 44 / 48 hit) and two `on-art` buttons at the poster's top-right while the card has keyboard
/// focus or a pointer over it. `Delete` on a focused card is Not for me.
class CineWorldCard extends StatefulWidget {
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
    this.onMoreLikeThis,
    this.liked = false,
    this.onLongPress,
    this.focusNode,
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
  final VoidCallback? onOpen, onSearchMySources, onReadOn, onDismiss, onMoreLikeThis, onLongPress;

  /// More like this was pressed: the Fill glyph and a 2 px `spot` rule under the square.
  final bool liked;
  final FocusNode? focusNode;
  final bool withCredentials;

  @override
  State<CineWorldCard> createState() => _CineWorldCardState();
}

class _CineWorldCardState extends State<CineWorldCard> {
  bool _hover = false, _within = false;

  bool get _info => widget.kind == CineWorldKind.infoOnly;
  bool get _hasMenu => widget.onDismiss != null || widget.onMoreLikeThis != null;

  Future<void> _menu() async {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final rect = box.localToGlobal(Offset.zero) & box.size;
    await showCineMenu<void>(context, anchor: rect, entries: [
      if (widget.onDismiss != null) CineMenuEntry<void>(label: 'Not for me', glyph: CineGlyph.x, onSelected: widget.onDismiss),
      if (widget.onMoreLikeThis != null) CineMenuEntry<void>(label: 'More like this', glyph: CineGlyph.thumbsUp, onSelected: widget.onMoreLikeThis),
      if (_info)
        CineMenuEntry<void>(label: 'Search my sources', glyph: CineGlyph.magnifyingGlass, onSelected: widget.onSearchMySources)
      else
        CineMenuEntry<void>(label: 'Open', glyph: CineGlyph.arrowRight, onSelected: widget.onOpen),
    ],);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final reduced = CineMotion.reduced(context);
    final info = _info;
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onFocusChange: (f) => setState(() => _within = f),
      onKeyEvent: (_, e) {
        if (e is KeyDownEvent && e.logicalKey == LogicalKeyboardKey.delete && widget.onDismiss != null) {
          widget.onDismiss!();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: Stack(clipBehavior: Clip.none, children: [
          Semantics(
            button: !info,
            label: '${widget.title}, ${widget.kicker}${widget.credit == null ? '' : ', ${widget.credit}'}${widget.why == null ? '' : '. ${widget.why}'}',
            excludeSemantics: !info,
            onTap: info ? null : widget.onOpen,
            onLongPress: _hasMenu ? _menu : widget.onLongPress,
            child: CinePressable(
              hit: false,
              onTap: info ? null : widget.onOpen,
              enabled: !info,
              focusNode: widget.focusNode,
              onLongPress: _hasMenu || widget.onLongPress != null
                  ? () {
                      cineFeedback(context, HapticEvent.longpressOpen);
                      if (_hasMenu) {
                        _menu();
                      } else {
                        widget.onLongPress!();
                      }
                    }
                  : null,
              builder: (context, st) {
                final lit = st.hovered || st.focused;
                Widget poster = CineImage(url: widget.imageUrl, title: widget.title, withCredentials: widget.withCredentials);
                if (info) poster = CineDuotone(duo: widget.duo ?? c.colorAmbientFallbackDuo, child: poster);
                poster = ClipRect(child: AnimatedScale(scale: lit && !reduced ? 1.04 : 1, duration: reduced ? Duration.zero : c.durClip, curve: c.easeSettle, child: poster));
                return AnimatedContainer(
                  duration: reduced ? Duration.zero : (st.pressed ? c.durTick : c.durBeat),
                  transform: Matrix4.translationValues(0, st.pressed ? 1 : 0, 0),
                  child: CineStock.raised(Builder(
                    builder: (context) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      SizedBox(
                        width: 104,
                        child: AspectRatio(
                          aspectRatio: 2 / 3,
                          child: Stack(fit: StackFit.expand, children: [
                            poster,
                            IgnorePointer(child: DecoratedBox(decoration: BoxDecoration(border: Border.all(color: c.colorHairlineArt)))),
                            if (widget.adult && widget.gateOpen) Positioned(left: 4, top: 4, child: CineBadge.certificate(onArt: true)),
                          ],),
                        ),
                      ),
                      SizedBox(width: c.space3),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(right: _hasMenu ? 4 : 0),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                            CineRoleText(widget.kicker, c.typeKicker, color: c.colorInk45, maxLines: 2, overflow: TextOverflow.ellipsis),
                            SizedBox(height: c.space1),
                            CineRoleText(widget.title, c.typeTitle, maxLines: 2, overflow: TextOverflow.ellipsis, decoration: lit && !info ? TextDecoration.underline : null),
                            if (widget.byline != null) ...[SizedBox(height: c.space1), CineRoleText('by ${widget.byline}', c.typeCaption, color: c.colorInk60, maxLines: 1, overflow: TextOverflow.ellipsis)],
                            if (widget.why != null) ...[
                              SizedBox(height: c.space2),
                              Container(
                                padding: const EdgeInsets.only(left: 10),
                                decoration: BoxDecoration(border: Border(left: BorderSide(color: c.colorSpot, width: 2))),
                                child: CineRoleText(widget.why!, c.typeBodyItalic, color: c.colorInk80, maxLines: 3, overflow: TextOverflow.ellipsis),
                              ),
                            ],
                            if (widget.credit != null || _hasMenu) ...[
                              SizedBox(height: c.space2),
                              Padding(
                                padding: EdgeInsets.only(right: _hasMenu ? 44 : 0),
                                child: CineRoleText(widget.credit ?? '', c.typeCredit, color: c.colorInk45, maxLines: 1, overflow: TextOverflow.ellipsis),
                              ),
                              if (_hasMenu) const SizedBox(height: 28),
                            ],
                            if (info)
                              Wrap(spacing: c.space1, children: [
                                CineButton(label: 'Search my sources', variant: CineButtonVariant.quiet, size: CineButtonSize.sm, onPressed: widget.onSearchMySources),
                                CineButton(label: 'Read on ${widget.readOnLabel ?? 'the site'} ↗', variant: CineButtonVariant.quiet, size: CineButtonSize.sm, onPressed: widget.onReadOn),
                              ],),
                          ],),
                        ),
                      ),
                    ],),
                  ),),
                );
              },
            ),
          ),
          // Sibling controls sit outside the card's semantics so each is its own labelled node.
          if (_hasMenu)
            Positioned(
              right: 0,
              bottom: 0,
              child: CineIconButton(label: 'More options for ${widget.title}', codepoint: CineGlyph.dotsThree, onPressed: _menu),
            ),
          if (_hasMenu && (_hover || _within || widget.liked))
            Positioned(
              left: 104 - 4 - (widget.onMoreLikeThis != null && widget.onDismiss != null ? 84 : 40),
              top: 4,
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                if (widget.onMoreLikeThis != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Semantics(
                      toggled: widget.liked,
                      child: CineIconButton(
                        label: 'More like this',
                        codepoint: CineGlyph.thumbsUp,
                        variant: CineIconButtonVariant.onArt,
                        selected: widget.liked,
                        onPressed: widget.onMoreLikeThis,
                      ),
                    ),
                  ),
                if (widget.onDismiss != null)
                  CineIconButton(label: 'Not for me', codepoint: CineGlyph.x, variant: CineIconButtonVariant.onArt, onPressed: widget.onDismiss),
              ],),
            ),
        ],),
      ),
    );
  }
}
