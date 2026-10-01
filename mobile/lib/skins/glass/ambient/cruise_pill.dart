import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/ambient/cruise.dart';
import 'package:manhwamaniacs/skins/glass/ambient/cruise_controller.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/icons/icon_roles.g.dart';
import 'package:manhwamaniacs/skins/glass/motion.dart';
import 'package:manhwamaniacs/skins/glass/motion_names.g.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/shell/bar_icon.dart';
import 'package:manhwamaniacs/skins/glass/shell/shell_common.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

/// The cruise button and, while cruising, the flywheel pill (glass 9.4.1). The pill is a 44 pt sibling inside the bottom capsule's
/// glass; the drag HUD floats 12 px above it as the one extra T2 capsule. Reads and writes [CruiseState]; never moves the page.
class CruisePill extends ConsumerStatefulWidget {
  const CruisePill({
    super.key,
    required this.state,
    required this.onToggle,
    required this.onResume,
    required this.onPreview,
    required this.onCommit,
    required this.onStep,
    required this.reduced,
    this.lb = 1.0,
    this.tint,
  });

  final CruiseState state;
  final VoidCallback onToggle, onResume;
  final ValueChanged<double> onPreview, onCommit;
  final ValueChanged<double> onStep;
  final bool reduced;
  final double lb;
  final Color? tint;

  @override
  ConsumerState<CruisePill> createState() => _CruisePillState();
}

/// The drag the pill and the trailing-edge strip share: 8 px per 0.05x, ticks every 0.25x, the 1.0x magnet, the end stops and the HUD.
class CruiseDrag {
  CruiseDrag({required TickerProvider vsync, required this.fire, required this.onPreview, required this.onCommit, required this.changed})
      : hud = AnimationController(vsync: vsync, duration: const Duration(milliseconds: 250));

  final AnimationController hud;
  final OverlayPortalController portal = OverlayPortalController(debugLabel: 'CruiseHud');
  final void Function(HapticEvent) fire;
  final ValueChanged<double> onPreview, onCommit;
  final VoidCallback changed;

  bool dragging = false;
  double _start = 1, _dy = 0, shown = 1;
  bool _inMagnet = false, _atLimit = false;

  void start(double speed) {
    dragging = true;
    _start = speed;
    _dy = 0;
    shown = speed;
    _inMagnet = speed == 1.0;
    _atLimit = false;
    final box = _anchorKey.currentContext?.findRenderObject();
    if (box is RenderBox && box.hasSize) _anchor = box.localToGlobal(Offset.zero) & box.size;
    portal.show();
    unawaited(GlassMotion.play(MotionName.materialise, controller: hud, target: 1));
    changed();
  }

  void update(double dy) {
    _dy += dy;
    final raw = rawAfterDrag(_start, _dy);
    final next = settle(raw);
    if (tickCrossed(shown, next) != null) fire(HapticEvent.autoscrollStep);
    final inBand = (raw - 1.0).abs() <= Cruise.magnetBand;
    if (inBand && !_inMagnet) fire(HapticEvent.detentMagnet);
    _inMagnet = inBand;
    final limited = rawAfterDrag(_start, _dy) <= kLimitLow || rawAfterDrag(_start, _dy) >= kLimitHigh;
    if (limited && !_atLimit) fire(HapticEvent.detentLimit);
    _atLimit = limited;
    if (next != shown) {
      shown = next;
      onPreview(next);
    }
    changed();
  }

  void end() {
    if (!dragging) return;
    dragging = false;
    onCommit(shown);
    unawaited(GlassMotion.play(MotionName.dematerialise, controller: hud, target: 0).whenComplete(() {
      if (!dragging) portal.hide();
    }),);
    changed();
  }

  void dispose() => hud.dispose();

  /// The gesture: slop 10, vertical only.
  Map<Type, GestureRecognizerFactory> gestures({GestureTapCallback? onTap, required double Function() speed}) => {
        VerticalDragGestureRecognizer: GestureRecognizerFactoryWithHandlers<VerticalDragGestureRecognizer>(
          VerticalDragGestureRecognizer.new,
          (r) => r
            ..onStart = ((_) => start(speed()))
            ..onUpdate = ((d) => update(d.delta.dy))
            ..onEnd = ((_) => end())
            ..onCancel = end,
        ),
        if (onTap != null)
          TapGestureRecognizer: GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(TapGestureRecognizer.new, (r) => r.onTap = onTap),
      };

  final GlobalKey _anchorKey = GlobalKey();
  Rect? _anchor;

  /// Wraps [child] so the HUD floats beside it (above it for the pill, to its leading side for the rail). The anchor is measured when
  /// the drag starts, so the HUD needs no leader/follower pair.
  Widget hudOver(Widget child, {required String text, required double lb, Color? tint, bool beside = false}) => OverlayPortal(
        controller: portal,
        overlayChildBuilder: (context) {
          final a = _anchor;
          if (a == null) return const SizedBox.shrink();
          const w = 200.0, h = 44.0;
          final left = beside ? a.left - 12 - w : a.center.dx - w / 2;
          final top = beside ? a.center.dy - h / 2 : a.top - 12 - h;
          return Positioned(
            left: left,
            top: top,
            width: w,
            height: h,
            child: IgnorePointer(
              child: FadeTransition(
                opacity: hud,
                child: Align(alignment: beside ? Alignment.centerRight : Alignment.bottomCenter, child: _Hud(text: text, lb: lb, tint: tint)),
              ),
            ),
          );
        },
        child: KeyedSubtree(key: _anchorKey, child: child),
      );
}

class _CruisePillState extends ConsumerState<CruisePill> with TickerProviderStateMixin {
  late final CruiseDrag _drag = CruiseDrag(
    vsync: this,
    fire: (e) => glassFire(ref, e),
    onPreview: widget.onPreview,
    onCommit: widget.onCommit,
    changed: () {
      if (mounted) setState(() {});
    },
  );
  late final Ticker _spin = createTicker(_onSpin);
  Duration? _last;
  double _angle = 0;

  @override
  void initState() {
    super.initState();
    _drag;
    _syncSpin();
  }

  @override
  void didUpdateWidget(CruisePill old) {
    super.didUpdateWidget(old);
    _syncSpin();
  }

  /// One turn per second at 1.0x (glass 4.10 Cruise disc spin): held still while paused and under Reduce Motion.
  void _syncSpin() {
    final want = widget.state.running && !widget.state.paused && !widget.reduced;
    if (want && !_spin.isActive) {
      _last = null;
      _spin.start();
    } else if (!want && _spin.isActive) {
      _spin.stop();
    }
  }

  void _onSpin(Duration t) {
    final prev = _last;
    _last = t;
    if (prev == null) return;
    final dt = (t - prev).inMicroseconds / 1e6;
    setState(() => _angle = (_angle + 2 * math.pi * (_drag.dragging ? _drag.shown : widget.state.speed) * dt) % (2 * math.pi));
  }

  @override
  void dispose() {
    _spin.dispose();
    _drag.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final side = math.max(44.0, GlassFrame.hitMin(context));
    if (!s.running) {
      return GlassBarIcon(icon: roleIcon(GlassIconRole.autoScroll), label: 'Cruise', onPressed: widget.onToggle);
    }
    final shown = _drag.dragging ? _drag.shown : s.speed;
    final text = formatSpeed(shown);
    final width = 16 + 20 + 6 + measureText(context, text, roleStyle(context, gt.typeMono, onGlass: true)).width + 16;
    final pill = Semantics(
      button: true,
      label: 'Cruise',
      value: '${shown.toStringAsFixed(shown * 100 % 10 == 0 ? 1 : 2)} times, ${s.paused ? 'paused' : 'playing'}',
      increasedValue: formatSpeed(clampSpeed(shown + Cruise.tick)),
      decreasedValue: formatSpeed(clampSpeed(shown - Cruise.tick)),
      onIncrease: () => widget.onStep(Cruise.tick),
      onDecrease: () => widget.onStep(-Cruise.tick),
      onTap: widget.onToggle,
      excludeSemantics: true,
      child: slop10(
        context,
        RawGestureDetector(
        behavior: HitTestBehavior.opaque,
        gestures: _drag.gestures(
          onTap: (s.paused && widget.reduced) ? widget.onResume : widget.onToggle,
          speed: () => widget.state.speed,
        ),
        child: SizedBox(
          height: side,
          width: width,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Transform.rotate(angle: _angle, child: Icon(roleIcon(GlassIconRole.autoScroll).regular, size: 20, color: gt.colorOnGlass)),
              const SizedBox(width: 6),
              GlassText(text, role: gt.typeMono, onGlass: true),
            ],
          ),
        ),
        ),
      ),
    );
    return _drag.hudOver(pill, text: text, lb: widget.lb, tint: widget.tint);
  }
}

/// The drag slop of glass 4.10 is 10 px (`thresholdDragSlopTouch`): a recogniser takes its slop from the nearest `MediaQuery`.
Widget slop10(BuildContext context, Widget child) =>
    MediaQuery(data: MediaQuery.of(context).copyWith(gestureSettings: const DeviceGestureSettings(touchSlop: 10)), child: child);

/// Raw values past which the drag has hit an end of the range.
const double kLimitLow = 0.25, kLimitHigh = 4.0;

/// The drag HUD: a T2 capsule, 44 pt tall, the value in `monoLarge`.
class _Hud extends StatelessWidget {
  const _Hud({required this.text, required this.lb, required this.tint});
  final String text;
  final double lb;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final w = measureText(context, text, roleStyle(context, gt.typeMonoLarge, onGlass: true)).width + 32;
    return SkinGlass(
      size: Size(w, 44),
      tier: GlassTierId.t2,
      lb: lb,
      tint: tint,
      debugLabel: 'cruise hud',
      child: Center(child: GlassText(text, role: gt.typeMonoLarge, onGlass: true)),
    );
  }
}

/// The trailing-edge drag while cruising (glass 9.4.1, 11): a vertical drag on the rail's hit strip changes the speed by the same
/// 8 px per 0.05x rule instead of scrubbing, with the same HUD to its leading side.
class CruiseRailStrip extends ConsumerStatefulWidget {
  const CruiseRailStrip({super.key, required this.speed, required this.onPreview, required this.onCommit, required this.child, this.lb = 1.0, this.tint});
  final double speed;
  final ValueChanged<double> onPreview, onCommit;
  final Widget child;
  final double lb;
  final Color? tint;

  @override
  ConsumerState<CruiseRailStrip> createState() => _CruiseRailStripState();
}

class _CruiseRailStripState extends ConsumerState<CruiseRailStrip> with TickerProviderStateMixin {
  late final CruiseDrag _drag = CruiseDrag(
    vsync: this,
    fire: (e) => glassFire(ref, e),
    onPreview: widget.onPreview,
    onCommit: widget.onCommit,
    changed: () {
      if (mounted) setState(() {});
    },
  );

  @override
  void initState() {
    super.initState();
    _drag;
  }

  @override
  void dispose() {
    _drag.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _drag.hudOver(
        slop10(context, RawGestureDetector(behavior: HitTestBehavior.opaque, gestures: _drag.gestures(speed: () => widget.speed), child: widget.child)),
        text: formatSpeed(_drag.dragging ? _drag.shown : widget.speed),
        lb: widget.lb,
        tint: widget.tint,
        beside: true,
      );
}
