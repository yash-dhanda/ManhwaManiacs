import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:manhwamaniacs/skins/cinematic/hit.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

/// The double ring (cinematic 2.4, 2.8.2): a black band from the edge to [halo] px, the bone
/// ring over it from [offset] to [offset] + [width]. Painted outside the child, never clipped.
class CineFocusRingPainter extends CustomPainter {
  const CineFocusRingPainter({
    required this.visible,
    required this.round,
    required this.ink,
    this.width = 2,
    this.offset = 2,
    this.halo = 6,
  });

  final bool visible;
  final bool round;
  final Color ink;
  final double width, offset, halo;

  @override
  void paint(Canvas canvas, Size size) {
    if (!visible) return;
    void ring(double from, double to, Color color) {
      final mid = (from + to) / 2, w = to - from;
      final p = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w
        ..color = color;
      if (round) {
        canvas.drawCircle(size.center(Offset.zero), size.shortestSide / 2 + mid, p);
      } else {
        canvas.drawRect((Offset.zero & size).inflate(mid), p);
      }
    }

    ring(0, halo, const Color(0xFF000000));
    ring(offset, offset + width, ink);
  }

  @override
  bool shouldRepaint(CineFocusRingPainter o) =>
      o.visible != visible || o.round != round || o.ink != ink || o.width != width || o.offset != offset || o.halo != halo;
}

/// Focus target that paints the ring only on hardware-keyboard focus, never on touch.
class CineFocusRing extends StatefulWidget {
  const CineFocusRing({super.key, required this.child, this.round = false, this.focusNode, this.onActivate, this.canRequestFocus = true, this.onHighlight, this.hit, this.expand = false});

  final Widget child;
  final bool round;
  final FocusNode? focusNode;
  final VoidCallback? onActivate;
  final bool canRequestFocus;

  /// Reports the keyboard-focus highlight (never true on touch).
  final ValueChanged<bool>? onHighlight;

  /// A minimum touch target around the child (the ring still hugs the child).
  final double? hit;

  /// The child takes the width it is given (a full-width button) instead of hugging its content.
  final bool expand;

  @override
  State<CineFocusRing> createState() => _CineFocusRingState();
}

class _CineFocusRingState extends State<CineFocusRing> {
  bool _show = false;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final activate = widget.onActivate;
    return FocusableActionDetector(
      focusNode: widget.focusNode,
      enabled: widget.canRequestFocus,
      onShowFocusHighlight: (v) {
        setState(() => _show = v);
        widget.onHighlight?.call(v);
      },
      shortcuts: activate == null
          ? const {}
          : const {
              SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
              SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
            },
      actions: {
        if (activate != null) ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) {
          activate();
          return null;
        },),
      },
      child: _hit(
        CustomPaint(
          foregroundPainter: CineFocusRingPainter(
            visible: _show,
            round: widget.round,
            ink: c.colorInk100,
            width: c.focusWidth,
            offset: c.focusOffset,
            halo: c.focusHalo,
          ),
          child: widget.child,
        ),
      ),
    );
  }

  Widget _hit(Widget child) {
    final h = widget.hit;
    if (h == null) return child;
    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: h, minHeight: h),
      child: Center(widthFactor: widget.expand ? null : 1, heightFactor: 1, child: child),
    );
  }
}

/// Interaction state handed to a [CinePressable] builder.
class CinePressState {
  const CinePressState({this.hovered = false, this.pressed = false, this.focused = false, this.enabled = true});
  final bool hovered, pressed, focused, enabled;
}

/// Hover (trackpad or mouse only), pressed, keyboard focus, tap and 450 ms long-press with an
/// 8 px slop, in one place. No ink, no ripple.
class CinePressable extends StatefulWidget {
  const CinePressable({
    super.key,
    required this.builder,
    this.onTap,
    this.onLongPress,
    this.enabled = true,
    this.round = false,
    this.focusNode,
    this.onFocusHighlight,
    this.onHover,
    this.hit = true,
    this.expand = false,
  });

  final Widget Function(BuildContext context, CinePressState state) builder;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool enabled;
  final bool round;
  final FocusNode? focusNode;
  final ValueChanged<bool>? onFocusHighlight;
  final ValueChanged<bool>? onHover;

  /// Grow the touch target to 44/48 around the visual.
  final bool hit;

  /// A full-width visual: the target takes the width it is given.
  final bool expand;

  @override
  State<CinePressable> createState() => _CinePressableState();
}

class _CinePressableState extends State<CinePressable> {
  bool _hover = false, _down = false, _focus = false;

  void _set({bool? hover, bool? down, bool? focus}) => setState(() {
        _hover = hover ?? _hover;
        _down = down ?? _down;
        _focus = focus ?? _focus;
      });

  @override
  Widget build(BuildContext context) {
    final on = widget.enabled;
    final state = CinePressState(hovered: on && _hover, pressed: on && _down, focused: _focus, enabled: on);
    final child = widget.builder(context, state);
    return MouseRegion(
      cursor: on ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) {
        _set(hover: true);
        widget.onHover?.call(true);
      },
      onExit: (_) {
        _set(hover: false);
        widget.onHover?.call(false);
      },
      child: RawGestureDetector(
        behavior: HitTestBehavior.opaque,
        gestures: on
            ? {
                TapGestureRecognizer: GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
                  TapGestureRecognizer.new,
                  (t) => t
                    ..onTapDown = ((_) => _set(down: true))
                    ..onTapUp = ((_) => _set(down: false))
                    ..onTapCancel = (() => _set(down: false))
                    ..onTap = widget.onTap,
                ),
                if (widget.onLongPress != null)
                  LongPressGestureRecognizer: GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
                    () => LongPressGestureRecognizer(duration: const Duration(milliseconds: 450), postAcceptSlopTolerance: 8),
                    (l) => l.onLongPress = widget.onLongPress,
                  ),
              }
            : const {},
        child: CineFocusRing(
          round: widget.round,
          focusNode: widget.focusNode,
          canRequestFocus: on,
          hit: widget.hit ? cineHitMin(context) : null,
          expand: widget.expand,
          onActivate: on ? widget.onTap : null,
          onHighlight: (v) {
            _set(focus: v);
            widget.onFocusHighlight?.call(v);
          },
          child: child,
        ),
      ),
    );
  }
}
