import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

/// The shutter (cinematic 4.5, 8.5): an overlay layer at `z.shutter`, the frame mounts it.
///
/// `dip(navigate)` fades to `#000` in 160 ms `lift`, awaits [navigate] through the 40 ms hold, and
/// fades in over 240 ms `settle`; it serves auth to picker, Switch profile and any navigation that
/// must Dip but lands on a branch root, where no route transition runs.
///
/// **Iris** (8.5 steps 2 and 3): `irisClose` paints `#000` outside a circle whose radius shrinks
/// from the viewport diagonal to `endRadius` over 480 ms `turn` and completes when it lands (the
/// caller fires `HapticEvent.profileSelect`); `irisOut` grows the hole from 0 to the diagonal over
/// 560 ms `settle`, revealing whatever the router now shows. The iris out is an overlay rather than
/// a route transition because Tonight is a branch root reached by `go`, where no route transition
/// runs. A tap during a close skips to the open in 120 ms. Reduced: a 200 ms cross-fade through
/// black.
class CineShutter {
  CineShutter._(this._state);
  final CineShutterLayerState _state;

  /// The frame's shutter above [context].
  static CineShutter of(BuildContext context) {
    final s = context.dependOnInheritedWidgetOfExactType<_ShutterScope>();
    assert(s != null, 'no CineShutterLayer above this context');
    return CineShutter._(s!.state);
  }

  static CineShutter? maybeOf(BuildContext context) {
    final s = context.dependOnInheritedWidgetOfExactType<_ShutterScope>();
    return s == null ? null : CineShutter._(s.state);
  }

  Future<void> dip(Future<void> Function() navigate) => _state._dip(navigate);
  Future<void> irisClose(Offset center, double endRadius) => _state._irisClose(center, endRadius);
  Future<void> irisOut(Offset center, {Duration? duration}) => _state._irisOut(center, duration: duration);

  /// Freezes one frame (the harness): black outside a circle of [radius] at [center].
  void irisPreview(Offset center, double radius) => _state._preview(center, radius);

  /// Removes whatever the shutter paints.
  void clear() => _state._clear();
}

class _ShutterScope extends InheritedWidget {
  const _ShutterScope({required this.state, required super.child});
  final CineShutterLayerState state;

  @override
  bool updateShouldNotify(_ShutterScope o) => o.state != state;
}

/// The layer itself: wraps the app so [CineShutter.of] finds it, and paints above it.
class CineShutterLayer extends StatefulWidget {
  const CineShutterLayer({super.key, required this.child});
  final Widget child;

  @override
  State<CineShutterLayer> createState() => CineShutterLayerState();
}

enum _Mode { none, dip, iris }

class CineShutterLayerState extends State<CineShutterLayer> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  _Mode _mode = _Mode.none;
  double _black = 0; // dip: alpha of the black layer
  Offset _center = Offset.zero;
  double _radius = 0; // iris: the hole's radius
  double _diagonal = 0;
  bool _closing = false;
  Completer<void>? _closeDone;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _run(MotionName name, Duration d, Curve curve, void Function(double t) apply, {double to = 1}) async {
    final h = CineMotion.track(name, d.inMilliseconds);
    _c.duration = d;
    void tick() => setState(() => apply(curve.transform(_c.value)));
    _c
      ..removeListener(tick)
      ..addListener(tick);
    try {
      await _c.animateTo(to, duration: d).orCancel;
      h.end();
    } on TickerCanceled {
      h.end(interrupted: true);
    } finally {
      _c.removeListener(tick);
    }
  }

  Future<void> _dip(Future<void> Function() navigate) async {
    final reduced = CineMotion.reduced(context);
    setState(() {
      _mode = _Mode.dip;
      _black = 0;
    });
    _c.value = 0;
    if (reduced) {
      await _run(MotionName.dip, const Duration(milliseconds: 100), Curves.linear, (t) => _black = t);
      await navigate();
      _c.value = 0;
      await _run(MotionName.dip, const Duration(milliseconds: 100), Curves.linear, (t) => _black = 1 - t);
    } else {
      await _run(MotionName.dip, CineDur.beat, CineCurves.lift, (t) => _black = t);
      await Future.wait([navigate(), Future<void>.delayed(CineDur.holdDip)]);
      if (!mounted) return;
      _c.value = 0;
      await _run(MotionName.dip, CineDur.line, CineCurves.settle, (t) => _black = 1 - t);
    }
    if (mounted) setState(() => _mode = _Mode.none);
  }

  Future<void> _irisClose(Offset center, double endRadius) async {
    final size = MediaQuery.sizeOf(context);
    _diagonal = math.sqrt(size.width * size.width + size.height * size.height);
    final reduced = CineMotion.reduced(context);
    setState(() {
      _mode = reduced ? _Mode.dip : _Mode.iris;
      _center = center;
      _radius = _diagonal;
      _black = 0;
    });
    _closing = true;
    _closeDone = Completer<void>();
    _c.value = 0;
    final start = _diagonal;
    if (reduced) {
      await _run(MotionName.iris, const Duration(milliseconds: 100), Curves.linear, (t) => _black = t);
    } else {
      await _run(MotionName.iris, CineDur.spread, CineCurves.turn, (t) => _radius = start + (endRadius - start) * t);
    }
    _closing = false;
    if (!(_closeDone?.isCompleted ?? true)) _closeDone!.complete();
    if (mounted) setState(() => _radius = endRadius);
  }

  Future<void> _irisOut(Offset center, {Duration? duration}) async {
    final size = MediaQuery.sizeOf(context);
    _diagonal = math.sqrt(size.width * size.width + size.height * size.height);
    final reduced = CineMotion.reduced(context);
    setState(() {
      _mode = reduced ? _Mode.dip : _Mode.iris;
      _center = center;
      _radius = 0;
    });
    _c.value = 0;
    if (reduced) {
      setState(() => _black = 1);
      await _run(MotionName.iris, const Duration(milliseconds: 100), Curves.linear, (t) => _black = 1 - t);
    } else {
      await _run(MotionName.iris, duration ?? CineDur.irisOut, CineCurves.settle, (t) => _radius = _diagonal * t);
    }
    if (mounted) setState(() => _mode = _Mode.none);
  }

  void _preview(Offset center, double radius) => setState(() {
        _mode = _Mode.iris;
        _center = center;
        _radius = radius;
      });

  void _clear() => setState(() => _mode = _Mode.none);

  /// A tap during a close jumps to the open in 120 ms.
  void _tap() {
    if (!_closing) return;
    _c.animateTo(1, duration: const Duration(milliseconds: 120));
  }

  @override
  Widget build(BuildContext context) {
    return _ShutterScope(
      state: this,
      child: Stack(fit: StackFit.passthrough, children: [
        widget.child,
        if (_mode != _Mode.none)
          Positioned.fill(
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: (_) => _tap(),
              child: CustomPaint(
                painter: _ShutterPainter(mode: _mode, black: _black, center: _center, radius: _radius),
              ),
            ),
          ),
      ],),
    );
  }
}

class _ShutterPainter extends CustomPainter {
  _ShutterPainter({required this.mode, required this.black, required this.center, required this.radius});
  final _Mode mode;
  final double black, radius;
  final Offset center;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Color.fromRGBO(0, 0, 0, mode == _Mode.dip ? black.clamp(0.0, 1.0) : 1);
    if (mode == _Mode.dip) {
      canvas.drawRect(Offset.zero & size, paint);
      return;
    }
    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addOval(Rect.fromCircle(center: center, radius: math.max(0, radius)));
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_ShutterPainter o) => o.mode != mode || o.black != black || o.radius != radius || o.center != center;
}
