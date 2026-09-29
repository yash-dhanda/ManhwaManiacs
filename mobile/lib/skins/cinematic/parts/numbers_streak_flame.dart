import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:manhwamaniacs/features/library/utils/streak_state.dart';
import 'package:manhwamaniacs/skins/cinematic/icons/icon_roles.g.dart';
import 'package:manhwamaniacs/skins/cinematic/kit/cine_text.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

// TODO(mobile/08): mobile/08 owns `primitives/streak_flame.dart` (the one
// `StreakFlame`). This stand-in implements cinematic 9.2.2 for the surfaces of
// mobile/21 (streak block, Annual page 7, milestone card, Streak share card);
// swap the widget for it when that step is integrated. Same inputs: a tier
// (from the day count), a state, a size.

/// The spoken label of the flame.
String streakSemantics(int days, StreakState state) => switch (state) {
      _ when days <= 0 => 'No streak',
      StreakState.readToday => '$days-day streak, read today',
      StreakState.atRisk => '$days-day streak, at risk',
      _ => '$days-day streak',
    };

IconData _glyph(StreakTier tier, {required bool fill}) {
  final role = tier == StreakTier.one ? CineIconRole.streakShort : CineIconRole.streakLong;
  final byWeight = cineIcons[role]!;
  return fill ? byWeight[CineIconWeight.fill]! : byWeight[CineIconWeight.light]!;
}

/// The streak flame (cinematic 9.2.2), on `flutter_animate`.
///
/// Tiers: 0 the ember dot; 1-6 flame-1; 7-29 flame-3 with a second tongue
/// offset 300 ms; 30-99 plus a 1 px `spot` ring turning once per 24 s; 100+
/// plus three 2 px sparks rising 12 px. States: read today (Fill `spot`, the
/// bloom, flicker), not yet today (outlined `ink.100`, still), at risk
/// (outlined `spot`, faster flicker). Reduced motion: static.
///
/// [ignite] plays Ignite once: stroke to fill over 400 ms on `settle`, the
/// bloom rising 0 to 0.35, the tier glyph swapping mid-ignite when [fromTier]
/// differs from the current tier.
class NumbersStreakFlame extends StatelessWidget {
  const NumbersStreakFlame({
    super.key,
    required this.days,
    required this.state,
    this.size = 56,
    this.ignite = false,
    this.fromTier,
    this.forceFill = false,
  });

  final int days;
  final StreakState state;
  final double size;
  final bool ignite;
  final StreakTier? fromTier;

  /// Draw the filled `spot` flame regardless of state (Annual page 7, milestone card).
  final bool forceFill;

  @override
  Widget build(BuildContext context) {
    final tier = streakTier(days);
    final reduced = cineReduced(context);
    final filled = forceFill || state == StreakState.readToday;
    return Semantics(
      image: true,
      label: streakSemantics(days, state),
      child: ExcludeSemantics(
        child: SizedBox(
          width: size * 1.5,
          height: size * 1.5,
          child: tier == StreakTier.ember ? Center(child: Container(width: 6, height: 6, color: CineColors.ink45)) : _body(tier, filled, reduced),
        ),
      ),
    );
  }

  Widget _body(StreakTier tier, bool filled, bool reduced) {
    final outline = state == StreakState.atRisk ? CineColors.spot : CineColors.ink100;
    final flicker = filled ? (opacity: 0.85, scaleY: 1.02, half: 1000) : (state == StreakState.atRisk ? (opacity: 0.7, scaleY: 1.0, half: 400) : null);
    Widget glyph(bool fill, Color color, {double bloom = 0}) => Stack(alignment: Alignment.center, children: [
          if (bloom > 0)
            Container(
              width: size * 1.4,
              height: size * 1.4,
              decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [CineColors.spot.withValues(alpha: bloom), CineColors.spot.withValues(alpha: 0)])),
            ),
          Icon(_glyph(tier, fill: fill), size: size, color: color),
        ],);

    Widget flame() {
      if (ignite && !reduced) {
        return _Ignite(size: size, tier: tier, fromTier: fromTier ?? tier, glyph: glyph);
      }
      var w = glyph(filled, filled ? CineColors.spot : outline, bloom: filled ? 0.35 : 0);
      if (tier == StreakTier.three || tier == StreakTier.ring || tier == StreakTier.sparks) {
        // The second tongue: the same glyph, faint, flickering 300 ms out of phase.
        Widget tongue = Opacity(opacity: 0.35, child: Transform.translate(offset: Offset(size * 0.04, 0), child: Icon(_glyph(tier, fill: filled), size: size * 0.92, color: filled ? CineColors.spot : outline)));
        if (!reduced && flicker != null) {
          tongue = tongue.animate(onPlay: (c) => c.repeat(reverse: true)).fade(begin: 0.4, end: 1, delay: 300.ms, duration: flicker.half.ms, curve: CineCurves.drift);
        }
        w = Stack(alignment: Alignment.center, children: [tongue, w]);
      }
      if (!reduced && flicker != null) {
        w = w.animate(onPlay: (c) => c.repeat(reverse: true)).fade(begin: 1, end: flicker.opacity, duration: flicker.half.ms, curve: CineCurves.drift).custom(
              duration: flicker.half.ms,
              curve: CineCurves.drift,
              builder: (context, v, child) => Transform.scale(scaleY: 0.98 + (flicker.scaleY - 0.98) * v, child: child),
            );
      }
      return w;
    }

    final children = <Widget>[Center(child: flame())];
    if (!reduced || tier == StreakTier.ring || tier == StreakTier.sparks) {
      if (tier == StreakTier.ring || tier == StreakTier.sparks) {
        Widget ring = CustomPaint(size: Size.square(size * 1.5), painter: _RingPainter(size * 0.75 + 4, filled ? CineColors.spot : CineColors.ink60));
        if (!reduced) ring = ring.animate(onPlay: (c) => c.repeat()).rotate(duration: CineDur.flameRing, curve: CineCurves.linear);
        children.insert(0, Center(child: ring));
      }
      if (tier == StreakTier.sparks && !reduced) {
        for (var i = 0; i < 3; i++) {
          children.add(_Spark(size: size, index: i));
        }
      }
    }
    return Stack(clipBehavior: Clip.none, children: children);
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter(this.radius, this.color);
  final double radius;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final c = size.center(Offset.zero);
    // A ring of 24 arcs with small gaps, so its turning is visible.
    const n = 24;
    for (var i = 0; i < n; i++) {
      final a = i * 2 * math.pi / n;
      canvas.drawArc(Rect.fromCircle(center: c, radius: radius), a, 2 * math.pi / n * 0.7, false, p);
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.radius != radius || old.color != color;
}

/// One 2 x 2 `spot` spark rising 12 px and fading over 900 ms, one per second,
/// then a rest: a 6 s loop (three sparks + 3 s).
class _Spark extends StatelessWidget {
  const _Spark({required this.size, required this.index});
  final double size;
  final int index;

  @override
  Widget build(BuildContext context) {
    final dx = (index - 1) * size * 0.22;
    return Positioned(
      left: size * 0.75 + dx - 1,
      top: size * 0.35,
      child: Container(width: 2, height: 2, color: CineColors.spot)
          .animate(onPlay: (c) => c.repeat(), delay: (index * 1000).ms)
          .custom(
            duration: 6000.ms,
            curve: CineCurves.linear,
            builder: (context, v, child) {
              final t = (v * 6000 / CineDur.flameSpark.inMilliseconds).clamp(0.0, 1.0);
              return Opacity(opacity: v * 6000 <= CineDur.flameSpark.inMilliseconds ? 1 - t : 0, child: Transform.translate(offset: Offset(0, -12 * t), child: child));
            },
          ),
    );
  }
}

/// Ignite: stroke to fill over 400 ms `settle`, bloom 0 to 0.35, the tier
/// glyph swapping at the midpoint when the tier changed.
class _Ignite extends StatefulWidget {
  const _Ignite({required this.size, required this.tier, required this.fromTier, required this.glyph});
  final double size;
  final StreakTier tier;
  final StreakTier fromTier;
  final Widget Function(bool fill, Color color, {double bloom}) glyph;

  @override
  State<_Ignite> createState() => _IgniteState();
}

class _IgniteState extends State<_Ignite> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: CineDur.glide)..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = CineCurves.settle.transform(_c.value);
          final tier = _c.value < 0.5 ? widget.fromTier : widget.tier;
          final role = tier == StreakTier.one ? CineIconRole.streakShort : CineIconRole.streakLong;
          final by = cineIcons[role]!;
          return Stack(alignment: Alignment.center, children: [
            Container(width: widget.size * 1.4, height: widget.size * 1.4, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [CineColors.spot.withValues(alpha: 0.35 * t), CineColors.spot.withValues(alpha: 0)]))),
            Opacity(opacity: 1 - t, child: Icon(by[CineIconWeight.light], size: widget.size, color: CineColors.ink100)),
            Opacity(opacity: t, child: Icon(by[CineIconWeight.fill], size: widget.size, color: CineColors.spot)),
          ],);
        },
      );
}
