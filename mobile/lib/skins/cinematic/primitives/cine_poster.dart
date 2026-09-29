import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/duotone.dart';
import 'package:manhwamaniacs/skins/cinematic/feedback.dart';
import 'package:manhwamaniacs/skins/cinematic/focus_ring.dart';
import 'package:manhwamaniacs/skins/cinematic/icons/icon_roles.g.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_image.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/cinematic/stock.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

enum CinePosterCaption { wall, below, ranked }

/// Tracks which poster of a rail or wall is hovered so its siblings can dim (cinematic 7.7).
class CinePosterGroup extends StatefulWidget {
  const CinePosterGroup({super.key, required this.child});
  final Widget child;

  @override
  State<CinePosterGroup> createState() => _CinePosterGroupState();
}

class _CinePosterGroupState extends State<CinePosterGroup> {
  final ValueNotifier<int?> _hovered = ValueNotifier(null);

  @override
  void dispose() {
    _hovered.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _GroupScope(notifier: _hovered, child: widget.child);
}

class _GroupScope extends InheritedNotifier<ValueNotifier<int?>> {
  const _GroupScope({required ValueNotifier<int?> notifier, required super.child}) : super(notifier: notifier);

  static ValueNotifier<int?>? maybeOf(BuildContext c) => c.getInheritedWidgetOfExactType<_GroupScope>()?.notifier;
  static int? hoveredOf(BuildContext c) => c.dependOnInheritedWidgetOfExactType<_GroupScope>()?.notifier?.value;
}

List<double> _dimMatrix(double t) {
  const b = 0.55, s = 0.8;
  final bb = 1 + (b - 1) * t, ss = 1 + (s - 1) * t;
  double r(double lum, bool diag) => bb * (lum * (1 - ss) + (diag ? ss : 0));
  return [
    r(0.2126, true), r(0.7152, false), r(0.0722, false), 0, 0, //
    r(0.2126, false), r(0.7152, true), r(0.0722, false), 0, 0,
    r(0.2126, false), r(0.7152, false), r(0.0722, true), 0, 0,
    0, 0, 0, 1, 0,
  ];
}

/// The poster (cinematic 7.7): 2:3, radius 0, `paper.1` plate, inner hairline, and every state of
/// its table.
class CinePoster extends StatefulWidget {
  const CinePoster({
    super.key,
    required this.title,
    this.url,
    this.caption = CinePosterCaption.below,
    this.folio,
    this.rank,
    this.badges = const [],
    this.heroTag,
    this.favourited = false,
    this.disabled = false,
    this.loading = false,
    this.error = false,
    this.selectMode = false,
    this.selected = false,
    this.onTap,
    this.onQuickLook,
    this.onRetry,
    this.hoverIcons,
    this.dragHandle,
    this.groupIndex,
    this.duo,
    this.withCredentials = true,
    this.flickerIndex = 0,
    this.focusNode,
    this.folioColor,
    this.duotone,
  });

  final String title;
  final String? url;
  final CinePosterCaption caption;

  /// The folio caption: `CH 142 · 3 NEW`, `NOT STARTED`, `CAUGHT UP`, `CH 12 OF 40`.
  final String? folio;
  final int? rank;

  /// Badges, top-left in a 4 px inset stack.
  final List<Widget> badges;
  final (String, String)? heroTag;
  final bool favourited, disabled, loading, error, selectMode, selected, withCredentials;
  final VoidCallback? onTap, onQuickLook, onRetry;

  /// Bottom-right icons that appear on hover (favourite, notify): the Library sets them.
  final Widget? hoverIcons;

  /// Bottom-left drag handle for manual order.
  final Widget? dragHandle;
  final int? groupIndex;

  /// The series' `ambient.duo`: the art light behind the frame on hover.
  final Color? duo;
  final int flickerIndex;
  final FocusNode? focusNode;

  /// The folio caption's colour (`spot` for `2 LEFT`); `ink.45` when null.
  final Color? folioColor;

  /// Renders the picture in duotone, black to this colour: a title that is not on the reader's sources.
  final Color? duotone;

  @override
  State<CinePoster> createState() => _CinePosterState();
}

class _CinePosterState extends State<CinePoster> {
  bool _hover = false;
  ValueNotifier<int?>? _group;

  void _setHover(bool on) {
    setState(() => _hover = on);
    if (widget.groupIndex != null) _group?.value = on ? widget.groupIndex : (_group!.value == widget.groupIndex ? null : _group!.value);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _group = _GroupScope.maybeOf(context);
  }

  String get _spoken {
    final b = StringBuffer(widget.caption == CinePosterCaption.ranked && widget.rank != null ? 'Number ${widget.rank}, ${widget.title}' : widget.title);
    if (widget.favourited) b.write(', Favourite');
    if (widget.disabled) b.write(', unavailable');
    return b.toString();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final reduced = CineMotion.reduced(context);
    final tap = widget.disabled
        ? null
        : () {
            if (widget.selectMode) cineFeedback(context, HapticEvent.select, sound: SoundEvent.select);
            widget.onTap?.call();
          };
    final press = widget.error && widget.onRetry != null ? widget.onRetry : widget.onQuickLook;
    return Semantics(
      button: true,
      enabled: !widget.disabled,
      selected: widget.selectMode ? widget.selected : null,
      label: _spoken,
      excludeSemantics: true,
      onTap: tap,
      onLongPress: press,
      child: CinePressable(
        hit: false,
        focusNode: widget.focusNode,
        enabled: !widget.disabled && (widget.onTap != null || widget.selectMode),
        onTap: tap,
        onLongPress: press == null
            ? null
            : () {
                cineFeedback(context, HapticEvent.longpressOpen);
                press();
              },
        onHover: _setHover,
        builder: (context, st) => LayoutBuilder(builder: (context, box) => _body(context, c, st, reduced, box.hasBoundedWidth ? box.maxWidth : 120)),
      ),
    );
  }

  Widget _body(BuildContext context, CineTokens c, CinePressState st, bool reduced, double width) {
    final active = st.hovered || st.focused;
    final pressed = st.pressed;
    final hovered = _hover && !widget.disabled;
    final lit = active || hovered;
    final selected = widget.selected;
    final dur = reduced ? Duration.zero : c.durClip;

    Widget image;
    if (widget.loading) {
      image = CinePlate(title: widget.title, flicker: true, index: widget.flickerIndex);
    } else if (widget.error) {
      image = CinePlate(title: widget.title, error: true);
    } else {
      image = CineImage(url: widget.url, title: widget.title, withCredentials: widget.withCredentials, flickerIndex: widget.flickerIndex);
    }
    image = Stack(fit: StackFit.expand, children: [
      // Selected: brightness 0.7.
      AnimatedOpacity(opacity: selected ? 0.7 : 1, duration: reduced ? Duration.zero : c.durSnap, child: image),
    ],);
    if (widget.duotone != null) image = CineDuotone(duo: widget.duotone!, child: image);
    if (widget.heroTag != null) {
      image = Hero(tag: widget.heroTag!, transitionOnUserGestures: defaultTargetPlatform == TargetPlatform.iOS, child: image);
    }
    // Zoom inside the fixed frame (not under reduced motion).
    image = ClipRect(
      child: AnimatedScale(scale: (lit && !reduced) ? 1.04 : 1, duration: dur, curve: c.easeSettle, child: image),
    );

    final outline = (lit || (reduced && pressed)) && !widget.disabled;
    Widget frame = AspectRatio(
      aspectRatio: 2 / 3,
      child: Stack(fit: StackFit.expand, children: [
        image,
        // The inner hairline over the image.
        IgnorePointer(child: DecoratedBox(decoration: BoxDecoration(border: Border.all(color: c.colorHairlineArt)))),
        if (outline) IgnorePointer(child: DecoratedBox(decoration: BoxDecoration(border: Border.all(color: c.colorInk100, width: 2)))),
        if (selected) IgnorePointer(child: DecoratedBox(decoration: BoxDecoration(border: Border.all(color: c.colorSpot, width: 2)))),
        if (widget.badges.isNotEmpty)
          Positioned(left: 4, top: 4, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            for (var i = 0; i < widget.badges.length; i++) ...[if (i > 0) const SizedBox(height: 4), widget.badges[i]],
          ],),),
        if (widget.selectMode)
          Positioned(right: 4, top: 4, child: _selectSquare(c, selected, reduced))
        else if (widget.hoverIcons != null && lit)
          Positioned(right: 4, bottom: 4, child: widget.hoverIcons!),
        if (widget.dragHandle != null) Positioned(left: 4, bottom: 4, child: widget.dragHandle!),
      ],),
    );

    if (lit && widget.duo != null && !widget.disabled) {
      frame = DecoratedBox(
        decoration: BoxDecoration(boxShadow: [BoxShadow(color: widget.duo!.withValues(alpha: 0.6), blurRadius: 48, spreadRadius: -16)]),
        child: frame,
      );
    }
    frame = AnimatedScale(
      scale: (pressed && !reduced) ? 0.98 : 1,
      duration: pressed ? c.durTick : c.durBeat,
      curve: pressed ? c.easeSet : c.easeSettle,
      child: frame,
    );

    if (widget.caption == CinePosterCaption.ranked && widget.rank != null) {
      final size = 1.5 * width;
      frame = Stack(clipBehavior: Clip.none, children: [
        Positioned(
          left: -size * 0.28 * '${widget.rank}'.length,
          top: 0,
          child: IgnorePointer(child: ExcludeSemantics(child: Text('${widget.rank}', style: CineText.literal(context, CineFace.bodoni, size, size).copyWith(color: c.colorInk45), textScaler: TextScaler.noScaling, softWrap: false))),
        ),
        frame,
      ],);
    }

    Widget out = Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      frame,
      if (widget.caption == CinePosterCaption.below) _caption(context, c, lit),
    ],);
    out = Opacity(opacity: widget.disabled ? 0.4 : 1, child: out);

    // Siblings of a hovered poster dim to brightness 0.55, saturation 0.8 (280 ms).
    final hoveredIndex = _GroupScope.hoveredOf(context);
    final dim = widget.groupIndex != null && hoveredIndex != null && hoveredIndex != widget.groupIndex && !reduced;
    return TweenAnimationBuilder<double>(
      tween: Tween(end: dim ? 1.0 : 0.0),
      duration: reduced ? Duration.zero : c.durDim,
      builder: (_, t, child) => t == 0 ? child! : ColorFiltered(colorFilter: ColorFilter.matrix(_dimMatrix(t)), child: child),
      child: out,
    );
  }

  Widget _caption(BuildContext context, CineTokens c, bool lit) {
    final compact = CineReflow.of(context).railCompact;
    final folio = widget.disabled ? 'UNAVAILABLE' : widget.folio;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: CineStock.raised(Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Builder(
          builder: (context) => CineRoleText(widget.title, c.typeTitle, maxLines: compact ? 2 : 1, overflow: TextOverflow.ellipsis, decoration: lit ? TextDecoration.underline : null),
        ),
        if (folio != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Builder(
              builder: (context) => Row(children: [
                if (widget.favourited) ...[CineGlyphIcon(CineGlyph.star, size: 12, weight: CineIconWeight.fill, color: c.colorSpot), const SizedBox(width: 4)],
                Flexible(child: CineRoleText(folio, c.typeFolio, color: widget.folioColor ?? context.cine.colorInk45, maxLines: 1, overflow: TextOverflow.ellipsis)),
              ],),
            ),
          ),
      ],),),
    );
  }

  Widget _selectSquare(CineTokens c, bool selected, bool reduced) => AnimatedContainer(
        duration: reduced ? Duration.zero : c.durSnap,
        width: 24,
        height: 24,
        decoration: BoxDecoration(color: selected ? c.colorInk100 : c.colorOnart, border: selected ? null : Border.all(color: c.colorInk100)),
        alignment: Alignment.center,
        child: selected ? const CineGlyphIcon(CineGlyph.check, size: 16, color: Color(0xFF000000)) : null,
      );
}
