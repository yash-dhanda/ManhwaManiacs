import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/time/clock.dart';
import 'package:manhwamaniacs/features/home/models/home_feed.dart';
import 'package:manhwamaniacs/features/library/utils/streak.dart';
import 'package:manhwamaniacs/skins/cinematic/feedback.dart';
import 'package:manhwamaniacs/skins/cinematic/icons/icon_roles.g.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/on_screen.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// The spoken label of a streak (cinematic 9.2.2).
String streakSemantics(HomeStreak s, DateTime now) => switch (streakState(s, now)) {
      StreakLiveState.none => 'No streak',
      StreakLiveState.aliveToday => '${s.currentDays}-day streak, read today',
      StreakLiveState.aliveNotToday => '${s.currentDays}-day streak, not read yet today',
      StreakLiveState.atRisk => '${s.currentDays}-day streak, at risk',
    };

/// The streak flame (cinematic 9.2.2): always `spot`, never more glow than the one `spotGlow`
/// bloom. Tiers by [streakTier], states by [streakState]; Ignite when the day was just extended;
/// loops pause off screen; reduced motion is static.
class StreakFlame extends ConsumerStatefulWidget {
  const StreakFlame({super.key, required this.streak, required this.size, this.now, this.ignite});

  final HomeStreak streak;

  /// 16, 24, 56 or 96.
  final double size;
  final DateTime? now;

  /// Forces Ignite on or off (tests, the gallery); null asks [streakIgnitionProvider].
  final bool? ignite;

  @override
  ConsumerState<StreakFlame> createState() => _StreakFlameState();
}

class _StreakFlameState extends ConsumerState<StreakFlame> with TickerProviderStateMixin {
  late final AnimationController _flicker;
  late final AnimationController _ring;
  late final AnimationController _spark;
  late final AnimationController _ignite;
  bool _igniting = false;
  bool _started = false;

  DateTime get _now => widget.now ?? ref.read(clockProvider)();

  @override
  void initState() {
    super.initState();
    _flicker = AnimationController(vsync: this);
    _ring = AnimationController(vsync: this, duration: CineDur.flameRing);
    _spark = AnimationController(vsync: this, duration: const Duration(seconds: 6));
    _ignite = AnimationController(vsync: this, duration: CineDur.glide);
    _igniting = widget.ignite ?? ref.read(streakIgnitionProvider((streak: widget.streak, now: _now)));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _sync();
    if (_igniting) {
      cineFeedback(context, HapticEvent.streakExtend, sound: SoundEvent.streakExtend);
      if (CineMotion.reduced(context)) {
        _ignite.value = 1;
      } else {
        CineMotion.play(MotionName.ignite, _ignite, duration: CineDur.glide, curve: CineCurves.settle);
      }
    }
  }

  @override
  void didUpdateWidget(StreakFlame old) {
    super.didUpdateWidget(old);
    _sync();
  }

  void _sync() {
    if (CineMotion.reduced(context)) {
      for (final c in [_flicker, _ring, _spark]) {
        c.stop();
      }
      return;
    }
    final state = streakState(widget.streak, _now);
    final tier = streakTier(widget.streak.currentDays);
    final period = state == StreakLiveState.atRisk ? CineDur.flameRisk : CineDur.flameFlicker;
    final flickers = state == StreakLiveState.aliveToday || state == StreakLiveState.atRisk;
    if (flickers) {
      _flicker.duration = period;
      if (!_flicker.isAnimating) _flicker.repeat(reverse: true);
    } else {
      _flicker.stop();
    }
    if ((tier == StreakTier.ring || tier == StreakTier.sparks) && !_ring.isAnimating) _ring.repeat();
    if (tier == StreakTier.sparks && !_spark.isAnimating) {
      _spark.repeat();
    } else if (tier != StreakTier.sparks) {
      _spark.stop();
    }
  }

  @override
  void dispose() {
    _flicker.dispose();
    _ring.dispose();
    _spark.dispose();
    _ignite.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final s = widget.streak;
    final now = _now;
    final state = streakState(s, now);
    final reduced = CineMotion.reduced(context);
    final size = widget.size;
    final label = streakSemantics(s, now);

    if (state == StreakLiveState.none) {
      return Semantics(
        image: true,
        label: label,
        child: SizedBox(
          width: size,
          height: size,
          child: Center(child: ExcludeSemantics(child: Container(width: 6, height: 6, color: c.colorInk45))),
        ),
      );
    }

    final days = s.currentDays;
    // On Ignite the glyph is the previous tier until the fill lands (the swap happens mid-flight).
    final tier = streakTier(days);
    final prevTier = _igniting ? streakTier(days - 1) : tier;
    final role = (tier == StreakTier.one) ? CineIconRole.streakShort : CineIconRole.streakLong;
    final prevRole = (prevTier == StreakTier.one || prevTier == StreakTier.none) ? CineIconRole.streakShort : CineIconRole.streakLong;

    final filled = state == StreakLiveState.aliveToday;
    final risk = state == StreakLiveState.atRisk;
    final glyphColor = filled || risk ? c.colorSpot : c.colorInk100;

    Widget glyph(CineIconRole r, CineIconWeight w) => Icon(cineIcons[r]![w], size: size, color: glyphColor);

    final ring = (tier == StreakTier.ring || tier == StreakTier.sparks) ? size * 1.5 : size;

    return OnScreen(
      builder: (context, on) => TickerMode(
        enabled: on,
        child: Semantics(
          image: true,
          label: label,
          child: ExcludeSemantics(
            child: SizedBox(
              width: ring,
              height: ring,
              child: AnimatedBuilder(
                animation: Listenable.merge([_flicker, _ring, _spark, _ignite]),
                builder: (context, _) {
                  final ig = _igniting ? _ignite.value : 1.0;
                  final f = reduced ? 0.0 : CineCurves.drift.transform(_flicker.value);
                  final lo = risk ? 0.7 : 0.85;
                  final opacity = (filled || risk) && !reduced ? lo + (1 - lo) * f : 1.0;
                  final scaleY = filled && !reduced ? 0.98 + 0.04 * f : 1.0;
                  final bloom = filled ? (_igniting ? 0.35 * ig : 0.35) : 0.0;
                  final swapped = !_igniting || ig >= 0.5;
                  final weight = filled && ig >= (_igniting ? 0.5 : 0) ? CineIconWeight.fill : CineIconWeight.light;
                  Widget g = glyph(swapped ? role : prevRole, weight);
                  if (tier == StreakTier.three || tier == StreakTier.ring || tier == StreakTier.sparks) {
                    // Two tongues, 300 ms apart.
                    final f2 = reduced ? 0.0 : CineCurves.drift.transform((_flicker.value + 0.15) % 1);
                    Widget half(Alignment a, double v) => Opacity(
                          opacity: (filled || risk) && !reduced ? lo + (1 - lo) * v : 1,
                          child: ClipRect(child: Align(alignment: a, widthFactor: 0.5, child: g)),
                        );
                    g = Row(mainAxisSize: MainAxisSize.min, children: [half(Alignment.centerLeft, f), half(Alignment.centerRight, f2)]);
                  }
                  return Stack(alignment: Alignment.center, children: [
                    if (bloom > 0)
                      Container(
                        width: size * 2.4,
                        height: size * 2.4,
                        decoration: BoxDecoration(
                          gradient: RadialGradient(colors: [c.colorSpotGlow.withValues(alpha: c.colorSpotGlow.a * bloom / 0.35), c.colorSpotGlow.withValues(alpha: 0)]),
                        ),
                      ),
                    if (ring > size) CustomPaint(size: Size.square(ring), painter: _RingPainter(c.colorSpot, reduced ? 0 : _ring.value)),
                    Transform.scale(scaleY: scaleY, child: Opacity(opacity: opacity, child: g)),
                    if (tier == StreakTier.sparks && !reduced) ..._sparks(c.colorSpot, ring),
                  ],);
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Three 2 x 2 px squares, one per second, rising 12 px and fading over 900 ms, then 3 s of rest.
  List<Widget> _sparks(Color color, double ring) {
    final ms = _spark.value * 6000;
    return [
      for (var i = 0; i < 3; i++)
        if (ms >= i * 1000 && ms < i * 1000 + 900)
          Builder(builder: (_) {
            final t = (ms - i * 1000) / 900;
            final dx = (i - 1) * ring * 0.18;
            return Transform.translate(
              offset: Offset(dx, -ring * 0.3 - 12 * t),
              child: Opacity(opacity: 1 - t, child: Container(width: 2, height: 2, color: color)),
            );
          },),
    ];
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.color, this.turn);
  final Color color;
  final double turn;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2 - 0.5;
    final gap = 4 / r; // a 4 px gap
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawArc(Rect.fromCircle(center: size.center(Offset.zero), radius: r), turn * 2 * math.pi, 2 * math.pi - gap, false, paint);
  }

  @override
  bool shouldRepaint(_RingPainter o) => o.turn != turn || o.color != color;
}
