import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/gestures.dart';
import 'package:flutter/semantics.dart' show CustomSemanticsAction;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/glass/focus_ring.dart';
import 'package:manhwamaniacs/skins/glass/glass/glow.dart';
import 'package:manhwamaniacs/skins/glass/glass/shape.dart';
import 'package:manhwamaniacs/skins/glass/motion.dart';
import 'package:manhwamaniacs/skins/glass/motion_names.g.dart';
import 'package:manhwamaniacs/skins/glass/physics/glass_physics.dart';
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/tooltip.dart';
import 'package:manhwamaniacs/skins/glass/tokens.g.dart';
import 'package:motor/motor.dart';

/// Which press behaviour a control has (glass 2.4.2 rules 3 and 4): glass swells and lights up, content sinks.
enum GlassMaterial { glass, content }

/// How far the glass grows on press: `+12 px` on the longest side for the Medium class, `+17 px` capped
/// at `0.35 x side` for Feather and Light.
enum GlassGrowth { medium, light }

/// The states of glass 7.1, forced through [GlassPressable.forceStates] in the gallery.
@immutable
class GlassWidgetStates {
  const GlassWidgetStates({
    this.hovered = false,
    this.pressed = false,
    this.focused = false,
    this.disabled = false,
    this.loading = false,
    this.selected = false,
    this.error = false,
  });

  static const none = GlassWidgetStates();

  final bool hovered;
  final bool pressed;
  final bool focused;
  final bool disabled;
  final bool loading;
  final bool selected;
  final bool error;

  GlassWidgetStates or(GlassWidgetStates o) => GlassWidgetStates(
        hovered: hovered || o.hovered,
        pressed: pressed || o.pressed,
        focused: focused || o.focused,
        disabled: disabled || o.disabled,
        loading: loading || o.loading,
        selected: selected || o.selected,
        error: error || o.error,
      );

  GlassWidgetStates copyWith({bool? hovered, bool? pressed, bool? focused, bool? disabled, bool? loading, bool? selected, bool? error}) =>
      GlassWidgetStates(
        hovered: hovered ?? this.hovered,
        pressed: pressed ?? this.pressed,
        focused: focused ?? this.focused,
        disabled: disabled ?? this.disabled,
        loading: loading ?? this.loading,
        selected: selected ?? this.selected,
        error: error ?? this.error,
      );

  @override
  bool operator ==(Object other) =>
      other is GlassWidgetStates &&
      other.hovered == hovered &&
      other.pressed == pressed &&
      other.focused == focused &&
      other.disabled == disabled &&
      other.loading == loading &&
      other.selected == selected &&
      other.error == error;

  @override
  int get hashCode => Object.hash(hovered, pressed, focused, disabled, loading, selected, error);
}

/// What a [GlassPressable] hands its builder each frame.
class GlassPressInfo {
  const GlassPressInfo({required this.states, required this.glow, required this.press, required this.scale, required this.reduced, this.hover});

  final GlassWidgetStates states;

  /// Feed this to `SkinGlass(glow:)`.
  final ValueListenable<GlassPressGlow?> glow;

  /// 0 at rest, 1 fully pressed (a spring, so it can overshoot a little).
  final double press;

  /// The glass scale currently applied to the whole control; a label counter-scales by `1 / scale`.
  final double scale;
  final bool reduced;
  final Offset? hover;
}

/// A pointer sequence that survives a scroll parent (it loses the arena to a scroll that starts) but does
/// not give up at the 18 px tap slop: it cancels 1.5 x the hit area away (glass 2.4.2 rule 3).
class GlassPressRecognizer extends OneSequenceGestureRecognizer {
  GlassPressRecognizer({super.debugOwner, this.cancelDistance = double.infinity, this.claimAfter});

  double cancelDistance;
  Duration? claimAfter;

  void Function(PointerDownEvent e)? onDown;
  void Function(PointerMoveEvent e)? onMove;
  void Function(PointerUpEvent e)? onUp;
  VoidCallback? onCancel;
  VoidCallback? onClaimed;

  int? _pointer;
  Offset _down = Offset.zero;
  bool _accepted = false;
  bool _active = false;
  PointerUpEvent? _pendingUp;
  Timer? _claim;
  bool _claimFired = false;

  @override
  void addAllowedPointer(PointerDownEvent event) {
    if (_active) return;
    startTrackingPointer(event.pointer, event.transform);
    _pointer = event.pointer;
    _down = event.position;
    _accepted = false;
    _claimFired = false;
    _active = true;
    onDown?.call(event);
    if (claimAfter != null) {
      _claim = Timer(claimAfter!, () {
        if (!_active) return;
        _claimFired = true;
        resolve(GestureDisposition.accepted);
        if (_accepted) onClaimed?.call();
      });
    }
  }

  void _finish({required bool cancelled}) {
    _claim?.cancel();
    _claim = null;
    if (!_active) return;
    _active = false;
    _pendingUp = null;
    _pointer = null;
    if (cancelled) onCancel?.call();
  }

  @override
  void handleEvent(PointerEvent event) {
    if (event.pointer != _pointer) return;
    if (event is PointerMoveEvent) {
      if ((event.position - _down).distance > cancelDistance) {
        if (!_accepted) resolve(GestureDisposition.rejected);
        stopTrackingPointer(event.pointer);
        _finish(cancelled: true);
      } else {
        onMove?.call(event);
      }
    } else if (event is PointerUpEvent) {
      stopTrackingPointer(event.pointer);
      if (_accepted) {
        final up = event;
        _finish(cancelled: false);
        onUp?.call(up);
      } else {
        _pendingUp = event;
        resolve(GestureDisposition.accepted);
      }
    } else if (event is PointerCancelEvent) {
      stopTrackingPointer(event.pointer);
      resolve(GestureDisposition.rejected);
      _finish(cancelled: true);
    }
  }

  @override
  void acceptGesture(int pointer) {
    _accepted = true;
    final up = _pendingUp;
    if (up != null) {
      _finish(cancelled: false);
      onUp?.call(up);
    } else if (_claimFired) {
      onClaimed?.call();
    }
  }

  @override
  void rejectGesture(int pointer) {
    _finish(cancelled: true);
  }

  @override
  void didStopTrackingLastPointer(int pointer) {
    _claim?.cancel();
  }

  @override
  String get debugDescription => 'glass press';
}

/// The shared press behaviour (glass 2.4.2 rules 3 to 4, 4.10, 7.1): focus, hover, keyboard activation,
/// semantics, the swell or the sink, the glow at the touch point, the drag stretch, the shake.
class GlassPressable extends ConsumerStatefulWidget {
  const GlassPressable({
    super.key,
    required this.builder,
    this.material = GlassMaterial.glass,
    this.growth = GlassGrowth.medium,
    this.sink = 0.97,
    this.shape = const GlassShape.capsule(),
    this.onTap,
    this.onLongPress,
    this.longPressDuration = const Duration(milliseconds: 450),
    this.enabled = true,
    this.loading = false,
    this.selected = false,
    this.error = false,
    this.forceStates = GlassWidgetStates.none,
    this.haptic,
    this.longPressHaptic,
    this.sound,
    this.semanticsLabel,
    this.semanticsValue,
    this.semanticsHint,
    this.toggled,
    this.semanticsSelected,
    this.checked,
    this.inGroup = false,
    this.isButton = true,
    this.tooltip,
    this.disabledReason,
    this.minHit = true,
    this.errorTrigger = 0,
    this.errorAnnouncement,
    this.shakeAmplitude = 8,
    this.focusNode,
    this.autofocus = false,
    this.onHoverChanged,
    this.customActions = const {},
    this.hoverGlow = true,
    this.focusScale = 1.0,
    this.onPressChanged,
    this.onRawDown,
    this.onRawMove,
    this.onRawUp,
    this.onRawCancel,
    this.claimAfter,
    this.cancelDistance,
    this.suppressTap = false,
    this.noSemantics = false,
  });

  final Widget Function(BuildContext context, GlassPressInfo info) builder;
  final GlassMaterial material;
  final GlassGrowth growth;

  /// Content sink target: cards and posters 0.97, rows 0.99, chips 0.96, plain icons 0.92.
  final double sink;
  final GlassShape shape;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Duration longPressDuration;
  final bool enabled;
  final bool loading;
  final bool selected;
  final bool error;
  final GlassWidgetStates forceStates;
  final HapticEvent? haptic;
  final HapticEvent? longPressHaptic;
  final SoundEvent? sound;
  final String? semanticsLabel;
  final String? semanticsValue;
  final String? semanticsHint;
  final bool? toggled;
  final bool? semanticsSelected;
  final bool? checked;
  final bool inGroup;
  final bool isButton;
  final String? tooltip;
  final String? disabledReason;
  final bool minHit;

  /// Every increase shakes the control, fires the `error` haptic and announces [errorAnnouncement].
  final int errorTrigger;
  final String? errorAnnouncement;
  final double shakeAmplitude;
  final FocusNode? focusNode;
  final bool autofocus;
  final ValueChanged<bool>? onHoverChanged;
  final Map<CustomSemanticsAction, VoidCallback> customActions;
  final bool hoverGlow;
  final double focusScale;
  final ValueChanged<bool>? onPressChanged;

  /// Raw pointer passthrough for controls that own their timing (hold-to-confirm).
  final void Function(PointerDownEvent e)? onRawDown;
  final void Function(PointerMoveEvent e)? onRawMove;
  final void Function(PointerUpEvent e)? onRawUp;
  final VoidCallback? onRawCancel;

  /// Claims the pointer after this long (defeating a scroll parent), and cancels [cancelDistance] away.
  final Duration? claimAfter;
  final double? cancelDistance;

  /// A pointer release does not call [onTap] (keyboard and screen-reader activation still do).
  final bool suppressTap;

  /// The control only decorates something that already carries its own semantics (a text field).
  final bool noSemantics;

  @override
  ConsumerState<GlassPressable> createState() => GlassPressableState();
}

class GlassPressableState extends ConsumerState<GlassPressable> with TickerProviderStateMixin {
  late final SingleMotionController _press = SingleMotionController(
    motion: SpringMotion(springOf(glassTokens.springPress)),
    vsync: this,
  );
  late final SingleMotionController _dx = SingleMotionController(motion: SpringMotion(springOf(glassTokens.springTrack)), vsync: this);
  late final SingleMotionController _dy = SingleMotionController(motion: SpringMotion(springOf(glassTokens.springTrack)), vsync: this);
  late final SingleMotionController _focus = SingleMotionController(motion: SpringMotion(springOf(glassTokens.springSnappy)), vsync: this);
  final ValueNotifier<GlassPressGlow?> _glow = ValueNotifier(null);
  final GlobalKey _box = GlobalKey();

  bool _hovered = false;
  bool _focusedKey = false;
  bool _down = false;
  bool _longFired = false;
  Offset? _hoverAt;
  Offset _lastLocal = Offset.zero;
  Size _size = Size.zero;

  bool get _active => widget.enabled && !widget.loading;

  @override
  void didUpdateWidget(GlassPressable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.errorTrigger > oldWidget.errorTrigger) {
      glassFire(ref, HapticEvent.error);
      final m = widget.errorAnnouncement;
      if (m != null) announceAssertive(context, m);
    }
    if (!widget.enabled && _down) _release(cancelled: true);
  }

  @override
  void dispose() {
    _press.dispose();
    _dx.dispose();
    _dy.dispose();
    _focus.dispose();
    _glow.dispose();
    super.dispose();
  }

  void _measure() {
    final ro = _box.currentContext?.findRenderObject();
    if (ro is RenderBox && ro.hasSize) _size = ro.size;
  }

  MotionName get _pressName => widget.material == GlassMaterial.glass ? MotionName.pressSwell : MotionName.contentSink;

  void _setDown(PointerDownEvent e) {
    if (!_active) return;
    _measure();
    _down = true;
    _longFired = false;
    widget.onPressChanged?.call(true);
    widget.onRawDown?.call(e);
    final local = _localOf(e.position);
    _lastLocal = local;
    _glow.value = GlassPressGlow(local, on: true);
    unawaited(GlassMotion.playMotor(_pressName, _press, 1));
    setState(() {});
  }

  Offset _localOf(Offset global) {
    final ro = _box.currentContext?.findRenderObject();
    return ro is RenderBox && ro.attached ? ro.globalToLocal(global) : Offset.zero;
  }

  void _move(PointerMoveEvent e) {
    if (!_down) return;
    widget.onRawMove?.call(e);
    final local = _localOf(e.position);
    _lastLocal = local;
    final g = _glow.value;
    if (g != null && g.on) _glow.value = GlassPressGlow(local, on: true);
    if (widget.material == GlassMaterial.glass && !ref.read(glassMotionPrefsProvider).reduced && _size.width > 0) {
      final c = _size.center(Offset.zero);
      _dx.animateTo(((local.dx - c.dx) / _size.width).clamp(-1.0, 1.0));
      _dy.animateTo(((local.dy - c.dy) / _size.height).clamp(-1.0, 1.0));
    }
  }

  void _release({required bool cancelled}) {
    if (!_down) return;
    _down = false;
    if (cancelled) widget.onRawCancel?.call();
    widget.onPressChanged?.call(false);
    _glow.value = GlassPressGlow(_lastLocal, on: false);
    unawaited(GlassMotion.playMotor(_pressName, _press, 0));
    _dx.animateTo(0);
    _dy.animateTo(0);
    if (mounted) setState(() {});
  }

  void _up(PointerUpEvent e) {
    final long = _longFired;
    widget.onRawUp?.call(e);
    _release(cancelled: false);
    if (long || !_active || widget.suppressTap) return;
    _activate();
  }

  void _activate() {
    if (!_active) return;
    if (widget.haptic != null) glassFire(ref, widget.haptic!);
    if (widget.sound != null) glassSound(ref, widget.sound!);
    widget.onTap?.call();
  }

  void _onClaimed() {
    if (!_down || widget.onLongPress == null) return;
    _longFired = true;
    if (widget.longPressHaptic != null) glassFire(ref, widget.longPressHaptic!);
    widget.onLongPress!.call();
  }

  /// Keyboard and screen-reader activation: a click with a short visual pulse, never a press-and-hold.
  void _keyActivate() {
    if (!_active) return;
    _measure();
    if (!_down) {
      _glow.value = GlassPressGlow(_size.center(Offset.zero), on: true);
      unawaited(
        GlassMotion.playMotor(_pressName, _press, 1).then((_) {
          if (!mounted || _down) return;
          _glow.value = GlassPressGlow(_size.center(Offset.zero), on: false);
          unawaited(GlassMotion.playMotor(_pressName, _press, 0));
        }),
      );
    }
    _activate();
  }

  GlassWidgetStates _states() => GlassWidgetStates(
        hovered: _hovered,
        pressed: _down,
        focused: _focusedKey,
        disabled: !widget.enabled,
        loading: widget.loading,
        selected: widget.selected,
        error: widget.error,
      ).or(widget.forceStates);

  double _glassScale(double p) {
    if (_size.isEmpty) return 1;
    final l = math.max(_size.width, _size.height);
    final g = widget.growth == GlassGrowth.medium ? 12.0 : math.min(17.0, 0.35 * l);
    return (l + g * p) / l;
  }

  Map<Type, GestureRecognizerFactory> _recognizers(double hit) => {
        GlassPressRecognizer: GestureRecognizerFactoryWithHandlers<GlassPressRecognizer>(
          () => GlassPressRecognizer(debugOwner: this),
          (r) => r
            ..cancelDistance = widget.cancelDistance ?? hit * 1.5
            ..claimAfter = widget.claimAfter ?? (widget.onLongPress == null ? null : widget.longPressDuration)
            ..onDown = _setDown
            ..onMove = _move
            ..onUp = _up
            ..onCancel = () {
              _release(cancelled: true);
            }
            ..onClaimed = _onClaimed,
        ),
      };

  @override
  Widget build(BuildContext context) {
    final reduced = ref.watch(glassMotionPrefsProvider.select((m) => m.reduced));
    final hit = GlassFrame.hitMin(context);
    final states = _states();
    if (widget.forceStates.pressed && _size.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _measure();
        if (!_size.isEmpty) setState(() {});
      });
    }
    final showFocus = widget.forceStates.focused;
    final tooltipText = !widget.enabled && widget.disabledReason != null ? widget.disabledReason : widget.tooltip;

    Widget body = AnimatedBuilder(
      animation: Listenable.merge([_press, _dx, _dy, _focus]),
      builder: (context, _) {
        final forced = widget.forceStates.pressed ? 1.0 : 0.0;
        final p = math.max(_press.value, forced);
        double scale = 1;
        var sx = 1.0, sy = 1.0;
        if (widget.material == GlassMaterial.glass) {
          if (!reduced) {
            scale = _glassScale(p);
            final ax = _dx.value.abs(), ay = _dy.value.abs();
            final a = 0.06 * math.max(ax, ay);
            final along = 1 + a;
            final other = 1 / math.sqrt(along);
            if (ax >= ay) {
              sx = along;
              sy = other;
            } else {
              sx = other;
              sy = along;
            }
          }
        } else if (!reduced) {
          scale = 1 - (1 - widget.sink) * p;
        }
        if (states.focused && widget.focusScale != 1) scale *= 1 + (widget.focusScale - 1) * _focus.value.clamp(0.0, 1.0);
        final info = GlassPressInfo(states: states, glow: _glow, press: p, scale: widget.material == GlassMaterial.glass ? scale : 1, reduced: reduced, hover: _hoverAt);
        Widget child = KeyedSubtree(key: _box, child: widget.builder(context, info));
        final overlays = <Widget>[];
        if (widget.material == GlassMaterial.content && reduced && p > 0) {
          overlays.add(Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: _WashPainter(shape: widget.shape, opacity: p.clamp(0.0, 1.0))),
            ),
          ),);
        }
        if (widget.hoverGlow && states.hovered && !states.disabled && widget.material == GlassMaterial.glass && _hoverAt != null) {
          overlays.add(Positioned.fill(
            child: IgnorePointer(child: CustomPaint(painter: _HoverPainter(shape: widget.shape, at: _hoverAt!))),
          ),);
        }
        if (overlays.isNotEmpty) child = Stack(clipBehavior: Clip.none, children: [child, ...overlays]);
        if (scale == 1 && sx == 1 && sy == 1) return child;
        return Transform(alignment: Alignment.center, transform: Matrix4.diagonal3Values(scale * sx, scale * sy, 1), child: child);
      },
    );

    body = GlassShake(trigger: widget.errorTrigger, amplitude: widget.shakeAmplitude, child: body);
    body = GlassFocusRing(shape: widget.shape, forceVisible: showFocus, child: body);

    if (widget.minHit) {
      body = ConstrainedBox(constraints: BoxConstraints(minWidth: hit, minHeight: hit), child: Center(widthFactor: 1, heightFactor: 1, child: body));
    }

    body = RawGestureDetector(behavior: HitTestBehavior.opaque, gestures: _recognizers(hit), child: body);
    body = MouseRegion(
      cursor: _active ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) {
        _hovered = true;
        widget.onHoverChanged?.call(true);
        setState(() {});
      },
      onExit: (_) {
        _hovered = false;
        _hoverAt = null;
        widget.onHoverChanged?.call(false);
        setState(() {});
      },
      onHover: (e) {
        _measure();
        setState(() => _hoverAt = _localOf(e.position));
      },
      child: body,
    );
    body = FocusableActionDetector(
      enabled: _active,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      onShowFocusHighlight: (v) {
        if (_focusedKey == v) return;
        setState(() => _focusedKey = v);
        _focus.animateTo(v ? 1 : 0);
      },
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.numpadEnter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            _keyActivate();
            return null;
          },
        ),
      },
      child: body,
    );

    final actions = <CustomSemanticsAction, VoidCallback>{...widget.customActions};
    if (!widget.noSemantics) body = Semantics(
      container: true,
      button: widget.isButton,
      enabled: widget.enabled,
      label: widget.semanticsLabel,
      value: widget.semanticsValue ?? (widget.loading ? 'Loading' : null),
      hint: widget.semanticsHint,
      toggled: widget.toggled,
      selected: widget.semanticsSelected,
      checked: widget.checked,
      inMutuallyExclusiveGroup: widget.inGroup ? true : null,
      tooltip: tooltipText,
      onTap: _active ? _keyActivate : null,
      onLongPress: _active && widget.onLongPress != null ? () => widget.onLongPress!.call() : null,
      customSemanticsActions: actions.isEmpty ? null : actions,
      excludeSemantics: widget.semanticsLabel != null,
      child: body,
    );

    if (tooltipText != null) {
      body = GlassTooltip(message: tooltipText, child: body);
    }
    return body;
  }
}

class _WashPainter extends CustomPainter {
  const _WashPainter({required this.shape, required this.opacity});
  final GlassShape shape;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final c = glassTokens.colorFill2;
    canvas.drawPath(shape.path(Offset.zero & size), Paint()..color = c.withValues(alpha: c.a * opacity));
  }

  @override
  bool shouldRepaint(_WashPainter old) => old.opacity != opacity || old.shape != shape;
}

/// The hover inner glow: 8 % white centred on the pointer, no lag (glass 7.1 hover).
class _HoverPainter extends CustomPainter {
  const _HoverPainter({required this.shape, required this.at});
  final GlassShape shape;
  final Offset at;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipPath(shape.path(Offset.zero & size));
    canvas.drawCircle(
      at,
      120,
      Paint()..shader = const RadialGradient(colors: [Color(0x14FFFFFF), Color(0x00FFFFFF)]).createShader(Rect.fromCircle(center: at, radius: 120)),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_HoverPainter old) => old.at != at || old.shape != shape;
}
