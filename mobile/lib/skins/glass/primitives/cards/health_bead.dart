import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/skins/glass/motion.dart';
import 'package:manhwamaniacs/skins/glass/motion_names.g.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';

/// A source's health (`capabilities.md` 16.1 `health.status`).
enum GlassSourceHealth {
  ok('working'),
  failing('having trouble'),
  dead('not working'),
  unknown('not checked yet');

  const GlassSourceHealth(this.spoken);
  final String spoken;

  Color get color => switch (this) {
        GlassSourceHealth.ok => gt.colorSuccess,
        GlassSourceHealth.failing => gt.colorWarning,
        GlassSourceHealth.dead => gt.colorDanger,
        GlassSourceHealth.unknown => GlassColors.g600,
      };
}

/// The 10 px health bead (glass 7.7, 8.26), a content twin: a sphere lit from inside in its state colour (`success`, `warning`,
/// `danger` or `g600`) with a 1 px specular highlight at the light angle, no backdrop read; a 1 px `warning` ring when the source is
/// demoted. The semantics text carries the status, and ", skipped by search" when demoted.
///
/// A changed [pulseKey] plays the Bead pulse once (scale 1 -> 1.3 -> 1 on `springTick`); a changed [flickerKey] plays the Bead
/// flicker once (opacity 1 -> 0.3 -> 1 over 120 ms linear). Reduced motion: colour changes only (`GlassMotion` jumps both).
class GlassHealthBead extends StatefulWidget {
  const GlassHealthBead({super.key, required this.status, this.demoted = false, this.pulseKey, this.flickerKey, this.label});
  final GlassSourceHealth status;
  final bool demoted;
  final Object? pulseKey, flickerKey;

  /// Overrides the spoken status (System status says "Healthy", "Down", ...).
  final String? label;

  String get semanticsText => label ?? (demoted ? '${status.spoken}, skipped by search' : status.spoken);

  @override
  State<GlassHealthBead> createState() => _GlassHealthBeadState();
}

class _GlassHealthBeadState extends State<GlassHealthBead> with TickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController.unbounded(vsync: this, value: 1);
  late final AnimationController _flicker = AnimationController(vsync: this, value: 1);

  @override
  void didUpdateWidget(GlassHealthBead old) {
    super.didUpdateWidget(old);
    if (widget.pulseKey != null && widget.pulseKey != old.pulseKey) {
      _pulse.value = 0;
      GlassMotion.play(MotionName.beadPulse, controller: _pulse, target: 1);
    }
    if (widget.flickerKey != null && widget.flickerKey != old.flickerKey) {
      _flicker.value = 0;
      GlassMotion.play(MotionName.beadFlicker, controller: _flicker, target: 1);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    _flicker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.status.color;
    final bead = AnimatedBuilder(
      animation: Listenable.merge([_pulse, _flicker]),
      builder: (context, child) {
        final p = _pulse.value.clamp(0.0, 1.0);
        final f = _flicker.value.clamp(0.0, 1.0);
        return Opacity(
          opacity: 1 - 0.7 * (1 - (2 * f - 1).abs()),
          child: Transform.scale(scale: 1 + 0.3 * math.sin(math.pi * p), child: child),
        );
      },
      child: CustomPaint(size: const Size.square(10), painter: _BeadPainter(color)),
    );
    return Semantics(
      label: widget.semanticsText,
      image: true,
      child: ExcludeSemantics(
        child: Container(
          width: widget.demoted ? 12 : 10,
          height: widget.demoted ? 12 : 10,
          alignment: Alignment.center,
          decoration: BoxDecoration(shape: BoxShape.circle, border: widget.demoted ? Border.all(color: gt.colorWarning) : null),
          child: bead,
        ),
      ),
    );
  }
}

/// A radial gradient lit from the upper left, plus a 1 px specular dot at the light angle.
class _BeadPainter extends CustomPainter {
  const _BeadPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final c = Offset(r, r);
    final rect = Rect.fromCircle(center: c, radius: r);
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.35),
          colors: [Color.lerp(color, const Color(0xFFFFFFFF), 0.35)!, color, Color.lerp(color, const Color(0xFF000000), 0.35)!],
          stops: const [0, 0.55, 1],
        ).createShader(rect),
    );
    canvas.drawCircle(c + Offset(-r * 0.4, -r * 0.4), 1, Paint()..color = const Color(0xCCFFFFFF));
  }

  @override
  bool shouldRepaint(_BeadPainter old) => old.color != color;
}
