import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/platform/gravity.dart';
import 'package:manhwamaniacs/skins/glass/glass_motion_recorder.dart' show GlassMotionEntry;
import 'package:manhwamaniacs/skins/glass/motion.dart';
import 'package:manhwamaniacs/skins/glass/motion_names.g.dart';
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/flame_geometry.dart';

export 'package:manhwamaniacs/skins/glass/primitives/flame_geometry.dart' show kFlameLeanCap;

/// What the flame looks like (glass 9.2.2), from the server's streak object and the local clock.
enum FlameState { litToday, notYetToday, atRisk, none }

/// The state for [days] (the server's `current_days`), whether today has reading, the server's `atRisk` and the local clock. Never
/// infers a streak: only chooses the look.
FlameState flameStateOf({required int days, required bool readToday, required bool atRisk}) {
  if (days <= 0) return FlameState.none;
  if (readToday) return FlameState.litToday;
  return atRisk ? FlameState.atRisk : FlameState.notYetToday;
}

String flameSemantics(FlameState s, int days) => switch (s) {
      FlameState.litToday => '$days-day streak, read today',
      FlameState.notYetToday => '$days-day streak, not read yet today',
      FlameState.atRisk => '$days-day streak, at risk',
      FlameState.none => 'No streak',
    };

/// The caption under a 44 px or larger flame.
String? flameCaption(FlameState s, int days, {int? longest}) => switch (s) {
      FlameState.litToday => null,
      FlameState.notYetToday => 'Read today to keep your $days-day streak',
      FlameState.atRisk => 'Read one chapter to keep your $days-day streak',
      FlameState.none => longest != null && longest > 0 ? 'Longest: $longest days. Start a new one today.' : 'Read today to start a streak',
    };

/// The physical-candle streak flame (glass 9.2.2): three nested teardrops (`streak`, `#FFB547`, `streakCore`) whose tip is a spring
/// pulled to rest and pushed by device tilt and scroll acceleration, flickering by value noise. The ticker runs only while the flame
/// is on screen; the tilt subscription only while it is visible and "Light follows the device" is on. [flare] increments play the
/// flare (scale 1, 1.3, 1 and 8 embers); [sparks] increments play the 6 record sparks. Frozen under reduced motion.
class StreakFlame extends ConsumerStatefulWidget {
  const StreakFlame({super.key, required this.size, required this.state, this.days = 0, this.flare = 0, this.sparks = 0, this.semanticLabel = true});

  /// 16, 20, 44, 96 or 220.
  final double size;
  final FlameState state;
  final int days;
  final int flare;
  final int sparks;
  final bool semanticLabel;

  @override
  ConsumerState<StreakFlame> createState() => _StreakFlameState();
}

class _Spark {
  _Spark(this.x, this.delay);
  final double x;
  final double delay;
}

class _StreakFlameState extends ConsumerState<StreakFlame> with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_onTick);
  final _repaint = ValueNotifier<int>(0);
  final _tip = FlameTip();
  final _rng = math.Random();
  StreamSubscription<Offset>? _grav;
  ScrollPosition? _scroll;
  Offset _gravity = Offset.zero;
  double _lastPx = 0, _lastVel = 0, _accel = 0;
  Duration _last = Duration.zero;
  double _t = 0;
  bool _visible = true;
  double _flareT = 2; // seconds since the flare; >= 0.643 is over
  double _sparkT = 2;
  List<Ember> _embers = [];
  List<_Spark> _sparks = [];
  GlassMotionEntry? _flareEntry;
  GlassMotionEntry? _sparkEntry;

  bool get _reduced => ref.read(glassReducedProvider);
  bool get _animated => widget.state != FlameState.none && !_reduced;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final pos = Scrollable.maybeOf(context)?.position;
    if (pos != _scroll) {
      _scroll?.removeListener(_onScroll);
      _scroll = pos?..addListener(_onScroll);
      _lastPx = pos?.pixels ?? 0;
    }
    _sync();
  }

  @override
  void didUpdateWidget(StreakFlame old) {
    super.didUpdateWidget(old);
    if (widget.flare != old.flare && !_reduced && widget.state != FlameState.none) _startFlare();
    if (widget.sparks != old.sparks && !_reduced) _startSparks();
    _sync();
  }

  @override
  void dispose() {
    _scroll?.removeListener(_onScroll);
    _grav?.cancel();
    _ticker.dispose();
    _repaint.dispose();
    super.dispose();
  }

  void _startFlare() {
    _flareT = 0;
    _embers = spawnEmbers(Offset(widget.size / 2, 0), _rng);
    _flareEntry = GlassMotion.recorder.begin(MotionName.streakFlare.label, 643);
    _sync();
  }

  void _startSparks() {
    _sparkT = 0;
    _sparks = [for (var i = 0; i < 6; i++) _Spark((i - 2.5) * widget.size * 0.08, i * 0.03)];
    _sparkEntry = GlassMotion.recorder.begin(MotionName.recordSparks.label, 900);
    _sync();
  }

  /// Visible = inside the nearest scrollable's viewport and ticking. Starts or stops the ticker and the tilt subscription.
  bool _onScreen() {
    if (!TickerMode.valuesOf(context).enabled) return false;
    final ro = context.findRenderObject();
    if (ro is! RenderBox || !ro.attached || !ro.hasSize) return true;
    final s = Scrollable.maybeOf(context);
    final vp = s?.context.findRenderObject();
    if (vp is! RenderBox || !vp.attached) return true;
    final a = ro.localToGlobal(Offset.zero) & ro.size;
    final b = vp.localToGlobal(Offset.zero) & vp.size;
    return a.overlaps(b);
  }

  void _onScroll() {
    final v = _onScreen();
    if (v != _visible) {
      _visible = v;
      _sync();
    }
  }

  void _sync() {
    final run = _animated && _visible && TickerMode.valuesOf(context).enabled;
    if (run && !_ticker.isActive) {
      _last = Duration.zero;
      _ticker.start();
    } else if (!run && _ticker.isActive) {
      _ticker.stop();
    }
    final tilt = run && ref.read(glassInAppPrefsProvider).lightFollowsDevice;
    if (tilt && _grav == null) {
      _grav = ref.read(gravityProvider).stream.listen((g) => _gravity = g, onError: (Object _) {});
    } else if (!tilt && _grav != null) {
      unawaited(_grav!.cancel());
      _grav = null;
      _gravity = Offset.zero;
    }
    if (!run) _repaint.value++;
  }

  void _onTick(Duration elapsed) {
    final dt = _last == Duration.zero ? 1 / 60 : (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    _t += dt;
    final px = (_scroll?.hasPixels ?? false) ? _scroll!.pixels : _lastPx;
    final vel = dt > 0 ? (px - _lastPx) / dt : 0.0;
    _accel = dt > 0 ? (vel - _lastVel) / dt : 0.0;
    _lastPx = px;
    _lastVel = vel;
    _tip.step(dt, flameLean(gravity: _gravity, scrollAccel: _accel, height: widget.size));
    if (_flareT < 0.9) {
      _flareT += dt;
      for (final e in _embers) {
        e.step(dt);
      }
      if (_flareT >= 0.643 && _flareEntry != null) {
        GlassMotion.recorder.end(_flareEntry!);
        _flareEntry = null;
      }
    }
    if (_sparkT < 0.95) {
      _sparkT += dt;
      if (_sparkT >= 0.9 && _sparkEntry != null) {
        GlassMotion.recorder.end(_sparkEntry!);
        _sparkEntry = null;
      }
    }
    _repaint.value++;
  }

  /// Scale 1 -> 1.3 -> 1 over 643 ms (a half sine is the spring's overshoot shape).
  double get _scale {
    if (_flareT >= 0.643) return 1;
    return 1 + 0.3 * math.sin(math.pi * (_flareT / 0.643)).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    final box = SizedBox(
      width: s,
      height: s,
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _FlamePainter(this, widget.state),
          isComplex: false,
        ),
      ),
    );
    if (!widget.semanticLabel) return ExcludeSemantics(child: box);
    return Semantics(image: true, label: flameSemantics(widget.state, widget.days), child: ExcludeSemantics(child: box));
  }
}

class _FlamePainter extends CustomPainter {
  _FlamePainter(this.s, this.state) : super(repaint: s._repaint);
  final _StreakFlameState s;
  final FlameState state;

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height;
    if (state == FlameState.none) {
      _wick(canvas, size);
      return;
    }
    final scale = state == FlameState.atRisk ? 0.8 : 1.0;
    final dim = state == FlameState.notYetToday ? 0.55 : 1.0;
    final flick = s._reduced ? 0.0 : flameFlicker(s._t, h, slow: state == FlameState.notYetToday);
    final tipOff = s._tip.pos + Offset(0, flick);
    canvas.save();
    canvas.translate(size.width / 2, h);
    canvas.scale(scale * s._scale, scale * s._scale);
    canvas.translate(-size.width / 2, -h);
    final tip = Offset(size.width / 2, 0) + tipOff;
    Paint p(Color c) => Paint()..color = c.withValues(alpha: c.a * dim);
    canvas.drawPath(teardrop(size, tip, 0), p(gt.colorStreak));
    canvas.drawPath(teardrop(size, tip + Offset(0, h * 0.14), h * 0.14), p(const Color(0xFFFFB547)));
    if (state == FlameState.litToday) canvas.drawPath(teardrop(size, tip + Offset(0, h * 0.34), h * 0.26), p(gt.colorStreakCore));
    canvas.restore();
    // Embers and record sparks rise from the tip.
    for (final e in s._embers) {
      if (e.dead) continue;
      canvas.drawCircle(e.pos, math.max(1, size.width * 0.02), Paint()..color = gt.colorStreak.withValues(alpha: e.opacity));
    }
    if (s._sparkT < 0.9) {
      for (final sp in s._sparks) {
        final t = ((s._sparkT - sp.delay) / 0.9).clamp(0.0, 1.0);
        if (t <= 0) continue;
        canvas.drawCircle(Offset(size.width / 2 + sp.x, tip.dy - 40 * t), math.max(1.2, size.width * 0.025), Paint()..color = gt.colorStreakCore.withValues(alpha: 1 - t));
      }
    }
  }

  /// The unlit wick: a 2 px `g500` stroke.
  void _wick(Canvas canvas, Size size) {
    final w = Paint()
      ..color = gt.colorG500
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final c = size.width / 2;
    canvas.drawPath(
      Path()
        ..moveTo(c, size.height * 0.92)
        ..lineTo(c, size.height * 0.5)
        ..quadraticBezierTo(c, size.height * 0.36, c + size.width * 0.1, size.height * 0.3),
      w,
    );
  }

  @override
  bool shouldRepaint(_FlamePainter old) => old.state != state;
}
