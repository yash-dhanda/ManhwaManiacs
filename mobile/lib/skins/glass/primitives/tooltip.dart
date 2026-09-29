import 'dart:async';
import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/glass/physics/glass_physics.dart';
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';
import 'package:motor/motor.dart';

/// 150 ms for the dock and the collapsed sidebar, 600 ms for everything else on hover (glass 7.27).
enum GlassTooltipLevel { standard, bar }

/// The Glass tooltip (glass 7.27), not Material's: a `glassThin` capsule 8 px from its target.
/// Delays: 0 ms on hardware-keyboard focus, 150 ms on `bar`, 600 ms otherwise on hover. On touch a long
/// press shows it, held while pressed and 1,500 ms after release (only where the control has no
/// long-press action of its own, `touch: false` otherwise). WCAG 1.4.13: `Esc` closes it without moving
/// focus; it stays while the pointer is over it or within 8 px; it never leaves on its own while its
/// target is hovered or focused.
class GlassTooltip extends ConsumerStatefulWidget {
  const GlassTooltip({
    super.key,
    required this.message,
    required this.child,
    this.level = GlassTooltipLevel.standard,
    this.touch = true,
    this.above = true,
    this.forceVisible = false,
  });

  final String message;
  final Widget child;
  final GlassTooltipLevel level;
  final bool touch;
  final bool above;

  /// For captures and the gallery.
  final bool forceVisible;

  @override
  ConsumerState<GlassTooltip> createState() => _GlassTooltipState();
}

class _GlassTooltipState extends ConsumerState<GlassTooltip> with SingleTickerProviderStateMixin {
  final OverlayPortalController _portal = OverlayPortalController();
  final LayerLink _link = LayerLink();
  late final SingleMotionController _in = SingleMotionController(motion: SpringMotion(springOf(gt.springSnappy)), vsync: this);

  Timer? _show;
  Timer? _hide;
  Timer? _touchHold;
  bool _hoverTarget = false;
  bool _focusTarget = false;
  bool _overTip = false;
  bool _pressed = false;
  bool _visible = false;

  bool get _keyboardFocus => _focusTarget && FocusManager.instance.highlightMode == FocusHighlightMode.traditional;

  bool get _hasOverlay => Overlay.maybeOf(context) != null;

  @override
  void initState() {
    super.initState();
    _in.value = 0;
    if (widget.forceVisible) WidgetsBinding.instance.addPostFrameCallback((_) => _reveal());
  }

  @override
  void dispose() {
    _show?.cancel();
    _hide?.cancel();
    _touchHold?.cancel();
    HardwareKeyboard.instance.removeHandler(_onKey);
    _in.dispose();
    super.dispose();
  }

  bool _onKey(KeyEvent e) {
    if (_visible && e is KeyDownEvent && e.logicalKey == LogicalKeyboardKey.escape) {
      _dismiss();
      return true;
    }
    return false;
  }

  void _reveal() {
    if (!mounted || _visible || !_hasOverlay) return;
    _hide?.cancel();
    _visible = true;
    _portal.show();
    HardwareKeyboard.instance.addHandler(_onKey);
    if (ref.read(glassMotionPrefsProvider).reduced) {
      _in.value = 1;
    } else {
      _in.animateTo(1);
    }
    setState(() {});
  }

  void _dismiss() {
    _show?.cancel();
    _hide?.cancel();
    _touchHold?.cancel();
    if (!_visible) return;
    _visible = false;
    HardwareKeyboard.instance.removeHandler(_onKey);
    _portal.hide();
    _in.value = 0;
    if (mounted) setState(() {});
  }

  void _maybeHide() {
    _show?.cancel();
    _hide?.cancel();
    if (widget.forceVisible) return;
    if (_hoverTarget || _keyboardFocus || _overTip || _pressed) return;
    _hide = Timer(const Duration(milliseconds: 120), () {
      if (!(_hoverTarget || _keyboardFocus || _overTip || _pressed)) _dismiss();
    });
  }

  void _schedule(int ms) {
    _show?.cancel();
    if (ms == 0) {
      _reveal();
    } else {
      _show = Timer(Duration(milliseconds: ms), _reveal);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget target = MouseRegion(
      onEnter: (_) {
        _hoverTarget = true;
        _schedule(widget.level == GlassTooltipLevel.bar ? 150 : 600);
      },
      onExit: (_) {
        _hoverTarget = false;
        _maybeHide();
      },
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onFocusChange: (f) {
          _focusTarget = f;
          if (_keyboardFocus) {
            _schedule(0);
          } else {
            _maybeHide();
          }
        },
        child: widget.touch
            ? Listener(
                behavior: HitTestBehavior.translucent,
                onPointerDown: (e) {
                  if (e.kind != PointerDeviceKind.touch) return;
                  _pressed = true;
                  _touchHold?.cancel();
                  _touchHold = Timer(const Duration(milliseconds: 450), _reveal);
                },
                onPointerUp: (_) {
                  _pressed = false;
                  _touchHold?.cancel();
                  if (_visible) {
                    _hide?.cancel();
                    _hide = Timer(const Duration(milliseconds: 1500), _dismiss);
                  }
                },
                onPointerCancel: (_) {
                  _pressed = false;
                  _touchHold?.cancel();
                },
                child: widget.child,
              )
            : widget.child,
      ),
    );
    target = CompositedTransformTarget(link: _link, child: target);
    if (!_hasOverlay) return target;
    return OverlayPortal(
      controller: _portal,
      overlayChildBuilder: (context) => _TooltipBubble(
        link: _link,
        message: widget.message,
        above: widget.above,
        anim: _in,
        onOver: (v) {
          _overTip = v;
          _maybeHide();
        },
      ),
      child: target,
    );
  }
}

class _TooltipBubble extends StatelessWidget {
  const _TooltipBubble({required this.link, required this.message, required this.above, required this.anim, required this.onOver});
  final LayerLink link;
  final String message;
  final bool above;
  final SingleMotionController anim;
  final ValueChanged<bool> onOver;

  @override
  Widget build(BuildContext context) {
    final style = roleStyle(context, gt.typeFootnote, onGlass: true);
    final text = measureText(context, message, style, maxWidth: 240, maxLines: 2);
    final size = Size(text.width.ceilToDouble() + 24, text.height.ceilToDouble() < 18 ? 36 : text.height.ceilToDouble() + 18);
    final finalSize = Size(size.width, size.height < 36 ? 36 : size.height);
    return Positioned(
      left: 0,
      top: 0,
      child: CompositedTransformFollower(
        link: link,
        targetAnchor: above ? Alignment.topCenter : Alignment.bottomCenter,
        followerAnchor: above ? Alignment.bottomCenter : Alignment.topCenter,
        child: MouseRegion(
          onEnter: (_) => onOver(true),
          onExit: (_) => onOver(false),
          // The 8 px of padding is the gap to the target and the "within 8 px" the tooltip stays for.
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: AnimatedBuilder(
              animation: anim,
              builder: (context, child) => Opacity(
                opacity: anim.value.clamp(0.0, 1.0),
                child: Transform.scale(scale: 0.9 + 0.1 * anim.value, child: child),
              ),
              child: Semantics(
                container: true,
                liveRegion: false,
                excludeSemantics: true,
                child: SkinGlass(
                  size: finalSize,
                  tier: GlassTierId.t2,
                  layer: GlassLayerKind.hud,
                  role: GlassRole.transient,
                  debugLabel: 'GlassTooltip',
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                      child: GlassText(message, role: gt.typeFootnote, onGlass: true, maxLines: 2, textAlign: TextAlign.center),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
