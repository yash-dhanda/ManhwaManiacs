import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:manhwamaniacs/core/diagnostics/motion_recorder.dart';
import 'package:manhwamaniacs/skins/cinematic/hit.dart';
import 'package:manhwamaniacs/skins/cinematic/icons/icon_roles.g.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_icon_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_menu.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/tonight/cover_story_parts.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/tonight/tonight_layout.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// One cover story layout (phone, tablet spread, novel title page): the layers the trailer scrub
/// composes. Every method builds at the header's rest size; the composite moves, fades and clips.
abstract class CoverLayout {
  const CoverLayout(this.data);
  final CoverStoryData data;

  /// The header's height at rest (its `maxExtent`).
  double get height;

  /// Where the sharp art sits at rest, in header coordinates.
  Rect get artRest;

  /// Behind the art (the blurred field of a spread).
  Widget field(BuildContext context) => const SizedBox.shrink();

  /// The sharp art, `artRest.size` big.
  Widget art(BuildContext context);

  /// Over the art: scrims, vignette (fade out by p 0.3).
  Widget overlays(BuildContext context);

  /// The text block, positioned in the full-size rest layer.
  Widget text(BuildContext context);
}

/// The trailer scrub's header (cinematic 8.8, 13 moment 17): one pinned sliver whose delegate lays
/// the cover and the now-showing strip out at scroll progress `p` in one build.
class CoverStoryHeaderDelegate extends SliverPersistentHeaderDelegate {
  CoverStoryHeaderDelegate({
    required this.layout,
    required this.topInset,
    required this.side,
    required this.runningHead,
    required this.pageFocus,
    required this.reducedMotion,
    this.signature,
  });

  final CoverLayout layout;
  final double topInset, side;

  /// The running head (title, back, edition badge) shown until the strip takes over.
  final Widget runningHead;
  final FocusNode pageFocus;
  final bool reducedMotion;

  /// What a rebuild has to compare besides the layout's data.
  final Object? signature;

  @override
  double get maxExtent => layout.height;

  @override
  double get minExtent => 64 + topInset;

  @override
  bool shouldRebuild(CoverStoryHeaderDelegate old) =>
      old.layout.data.feed != layout.data.feed ||
      old.layout.data.cover != layout.data.cover ||
      old.layout.data.animateHeadline != layout.data.animateHeadline ||
      old.layout.height != layout.height ||
      old.topInset != topInset ||
      old.side != side ||
      old.reducedMotion != reducedMotion ||
      old.runningHead != runningHead ||
      old.signature != signature;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final p = scrubProgress(shrinkOffset, maxExtent, minExtent);
    return CoverStoryComposite(
      layout: layout,
      p: p,
      shrink: shrinkOffset,
      minExtent: minExtent,
      topInset: topInset,
      side: side,
      runningHead: runningHead,
      pageFocus: pageFocus,
      reduced: reducedMotion,
    );
  }
}

/// Lays the cover story out at scroll progress [p] (cinematic 8.8). Stateful for the focus hand-off
/// and the scroll gesture's motion-timings row only; every visual follows [p] frame for frame.
class CoverStoryComposite extends StatefulWidget {
  const CoverStoryComposite({
    super.key,
    required this.layout,
    required this.p,
    required this.shrink,
    required this.minExtent,
    required this.topInset,
    required this.side,
    required this.runningHead,
    required this.pageFocus,
    required this.reduced,
  });

  final CoverLayout layout;
  final double p, shrink, minExtent, topInset, side;
  final Widget runningHead;
  final FocusNode pageFocus;
  final bool reduced;

  @override
  State<CoverStoryComposite> createState() => _CoverStoryCompositeState();
}

class _CoverStoryCompositeState extends State<CoverStoryComposite> {
  final FocusScopeNode _text = FocusScopeNode(debugLabel: 'tonight-cover-text', skipTraversal: true);
  final FocusNode _stripContinue = FocusNode(debugLabel: 'tonight-strip-continue');
  bool _focusWasInText = false;

  /// The `p` the layers follow: the scrub, or (reduced motion) 0 until the cover is under the head.
  double get _p => widget.reduced ? 0 : widget.p;

  bool get _coverGone => widget.layout.height - widget.shrink <= widget.minExtent + 0.5;

  @override
  void didUpdateWidget(CoverStoryComposite old) {
    super.didUpdateWidget(old);
    final was = _stage(old), now = _stage(widget);
    if (was == now) return;
    // Text went inert (p >= 0.55): focus inside it moves to the page node, then to the strip.
    if (now >= 1 && was < 1 && _text.hasFocus) {
      _focusWasInText = true;
      widget.pageFocus.requestFocus();
    }
    if (now >= 2 && _focusWasInText) {
      _focusWasInText = false;
      // The strip's controls join the focus order with this frame; ask once they have.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _stripContinue.requestFocus();
      });
    }
    if (now < 1) _focusWasInText = false;
  }

  /// 0 text live, 1 text inert, 2 strip controls in the focus order.
  int _stage(CoverStoryComposite w) {
    final p = w.reduced ? (w.layout.height - w.shrink <= w.minExtent + 0.5 ? 1.0 : 0.0) : w.p;
    return p >= 0.8 ? 2 : (p >= 0.55 ? 1 : 0);
  }

  @override
  void dispose() {
    _text.dispose();
    _stripContinue.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.layout;
    final d = l.data;
    final c = context.cine;
    final size = MediaQuery.sizeOf(context);
    final w = size.width;
    final reduced = widget.reduced;
    final p = _p;
    final stripP = reduced ? 1.0 : widget.p;
    final gone = reduced && _coverGone;
    final topInset = widget.topInset;
    final hit = cineHitMin(context);
    // Rest layers scroll with the page until the last 240 px, then the scrub takes over.
    final s0 = math.max(0.0, l.height - widget.minExtent - 240);
    final shift = reduced ? widget.shrink : math.min(widget.shrink, s0);
    final art = l.artRest;
    final thumb = Rect.fromLTWH(widget.side, topInset + 8, 32, 48);
    final rect = Rect.lerp(art.shift(Offset(0, -shift)), reduced ? art.shift(Offset(0, -shift)) : thumb, p)!;
    final scale = reduced ? 1.0 : math.max(rect.width / art.width, rect.height / art.height);
    final restFade = 1 - ramp(p, 0, 0.3);
    final textFade = 1 - ramp(p, 0, 0.55);
    final textInert = reduced ? gone : p >= 0.55;
    final stripOn = stripP >= 0.8 || gone;
    final headH = (reduced ? hit : hit + (64 - hit) * p) + topInset;
    final drift = p < 0.3;

    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        // A scroll-linked move has no planned duration: one motion-timings row per gesture.
        if (n is ScrollStartNotification) {
          _handle = CineMotion.track(MotionName.values.firstWhere((m) => m.label == 'TRAILER SCRUB'), 0);
        } else if (n is ScrollEndNotification) {
          _handle?.end();
          _handle = null;
        }
        return false;
      },
      child: ClipRect(
        child: Stack(children: [
          const Positioned.fill(child: ColoredBox(color: Color(0xFF000000))),
          if (restFade > 0)
            Positioned(left: 0, top: -shift, width: w, height: l.height, child: Opacity(opacity: restFade, child: l.field(context))),
          // The sharp art: one Transform of one fixed-size child, never a relayout of the image.
          Positioned(
            left: rect.left,
            top: rect.top,
            width: rect.width,
            height: rect.height,
            child: ClipRect(
              child: OverflowBox(
                minWidth: art.width,
                maxWidth: art.width,
                minHeight: art.height,
                maxHeight: art.height,
                child: Transform.scale(scale: scale, child: TickerMode(enabled: drift, child: l.art(context))),
              ),
            ),
          ),
          if (restFade > 0)
            Positioned(left: 0, top: -shift, width: w, height: l.height, child: IgnorePointer(child: Opacity(opacity: restFade, child: l.overlays(context)))),
          // The progress rule along the art's bottom edge, then along the strip's.
          if (d.cover.progress != null) ...[
            if (restFade > 0)
              Positioned(
                left: art.left,
                width: art.width,
                top: art.bottom - shift - 2,
                height: 2,
                child: IgnorePointer(child: Opacity(opacity: restFade, child: ColoredBox(color: c.colorSpot))),
              ),
            if (stripP > 0.6 || gone)
              Positioned(
                left: 0,
                right: 0,
                top: headH - 2,
                height: 2,
                child: IgnorePointer(
                  child: Opacity(opacity: reduced ? 1 : ramp(stripP, 0.6, 1), child: Align(alignment: Alignment.centerLeft, child: FractionallySizedBox(widthFactor: d.cover.progress, child: ColoredBox(color: c.colorSpot)))),
                ),
              ),
          ],
          // The text block rises 12 px and is out by p 0.55; inert past it.
          if (textFade > 0 || !reduced)
            Positioned(
              left: 0,
              top: -shift - 12 * ramp(p, 0, 0.55),
              width: w,
              height: l.height,
              child: Opacity(
                opacity: reduced ? 1 : textFade,
                child: ExcludeFocus(
                  excluding: textInert,
                  child: ExcludeSemantics(
                    excluding: textInert,
                    child: FocusScope(node: _text, child: l.text(context)),
                  ),
                ),
              ),
            ),
          // The running head grows into the strip's frame and turns black.
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: headH,
            child: Opacity(
              opacity: reduced ? (gone ? 1 : 0) : math.min(1.0, p * 3),
              child: DecoratedBox(
                decoration: BoxDecoration(color: const Color(0xFF000000), border: Border(bottom: c.ruleHair)),
                child: const SizedBox.expand(),
              ),
            ),
          ),
          // The running head keeps its natural height (a badge under the title grows it).
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: Opacity(opacity: reduced ? (gone ? 0 : 1) : 1 - ramp(p, 0, 0.6), child: IgnorePointer(ignoring: stripOn, child: widget.runningHead)),
          ),
          Positioned(
            left: widget.side,
            right: widget.side,
            top: topInset,
            height: 64,
            child: AnimatedOpacity(
              opacity: reduced ? (gone ? 1 : 0) : ramp(stripP, 0.6, 1),
              duration: reduced ? CineDur.reduced : Duration.zero,
              child: ExcludeFocus(
                excluding: !stripOn,
                child: ExcludeSemantics(
                  excluding: !stripOn,
                  child: _Strip(data: d, thumbGap: 32 + 12, continueNode: _stripContinue),
                ),
              ),
            ),
          ),
          if (textFade > 0) Positioned(right: widget.side - 8 > 0 ? widget.side - 8 : 0, top: topInset + hit, child: Opacity(opacity: reduced ? 1 : textFade, child: ExcludeFocus(excluding: textInert, child: CoverOverflow(data: d)))),
        ],),
      ),
    );
  }

  MotionHandle? _handle;
}

/// The now-showing strip inside the grown running head: the thumbnail's slot, the series title,
/// `▸ CH 143` and, when a recap is ready, `dots-three` holding `Previously on`.
class _Strip extends StatelessWidget {
  const _Strip({required this.data, required this.thumbGap, required this.continueNode});
  final CoverStoryData data;
  final double thumbGap;
  final FocusNode continueNode;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final hit = cineHitMin(context);
    final ch = chapterFolio(data.cover.isStart ? (data.cover.chapterNumber ?? 1) : data.cover.chapterNumber);
    return Row(children: [
      SizedBox(width: thumbGap),
      Expanded(
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 96),
          child: CineRoleText(data.cover.title, c.typeTitle, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ),
      SizedBox(width: c.space3),
      Semantics(
        button: true,
        label: '${data.primaryLabel}, ${ch.toLowerCase().replaceFirst('ch ', 'chapter ')}',
        excludeSemantics: true,
        onTap: data.onContinue,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: hit),
          child: Center(
            child: ExcludeSemantics(
              child: CineButton(
                key: const Key('tonight-strip-continue'),
                label: '▸',
                folio: ch,
                variant: CineButtonVariant.split,
                size: CineButtonSize.sm,
                focusNode: continueNode,
                onPressed: data.onContinue,
              ),
            ),
          ),
        ),
      ),
      if (data.hasRecap) const SizedBox(width: 8),
      if (data.hasRecap)
        Builder(
          builder: (ctx) => SizedBox(
            width: hit,
            height: hit,
            child: CineIconButton(
              key: const Key('tonight-strip-more'),
              label: 'More',
              role: CineIconRole.overflow,
              onPressed: () => showCineMenu<String>(ctx, anchor: cineAnchorRect(ctx), entries: [
                CineMenuEntry(label: 'Previously on', value: 'recap', icon: CineIconRole.history, onSelected: data.onRecap),
              ],),
            ),
          ),
        ),
    ],);
  }
}
