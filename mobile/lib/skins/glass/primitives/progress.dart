import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/glass/icons/icon_roles.g.dart' show GlassIconWeight;
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/spring_value.dart';

export 'package:manhwamaniacs/skins/glass/primitives/liquid_progress.dart';

/// glass 7.19 states. Indicators have no hover, pressed or selected state.
enum GlassProgressStatus { normal, complete, paused, error, disabled }

Color _fillFor(GlassProgressStatus s, {double normalAlpha = 1}) => switch (s) {
      GlassProgressStatus.normal => gt.colorIris500.withValues(alpha: normalAlpha),
      GlassProgressStatus.complete => gt.colorSuccess,
      GlassProgressStatus.paused => gt.colorWarning.withValues(alpha: 0.6),
      GlassProgressStatus.error => gt.colorDanger,
      GlassProgressStatus.disabled => gt.colorIris500.withValues(alpha: 0.4),
    };

/// A label and a value ("12 of 40 pages saved"), updated at most once a second.
class GlassProgressSemantics extends StatefulWidget {
  const GlassProgressSemantics({super.key, required this.label, required this.value, required this.child});
  final String label;
  final String value;
  final Widget child;

  @override
  State<GlassProgressSemantics> createState() => _GlassProgressSemanticsState();
}

class _GlassProgressSemanticsState extends State<GlassProgressSemantics> {
  late String _shown = widget.value;
  DateTime _last = DateTime.fromMillisecondsSinceEpoch(0);
  Timer? _later;

  @override
  void didUpdateWidget(GlassProgressSemantics old) {
    super.didUpdateWidget(old);
    if (widget.value == _shown) return;
    final wait = const Duration(seconds: 1) - DateTime.now().difference(_last);
    if (wait <= Duration.zero) {
      _sync();
    } else {
      _later ??= Timer(wait, _sync);
    }
  }

  void _sync() {
    _later = null;
    if (!mounted) return;
    setState(() {
      _shown = widget.value;
      _last = DateTime.now();
    });
  }

  @override
  void dispose() {
    _later?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(label: widget.label, value: _shown, excludeSemantics: true, child: widget.child);
}

/// `linear`: a 4 px capsule track `fill1`, fill `iris500` (`success` when complete), a 1 px `iris300`
/// leading highlight; the width on `springSnappy`. [value] null is indeterminate: a 30 % band sweeps the
/// track every 1.2 s.
class GlassLinearProgress extends ConsumerStatefulWidget {
  const GlassLinearProgress({super.key, this.value, this.status = GlassProgressStatus.normal, this.label = 'Progress', this.valueLabel});
  final double? value;
  final GlassProgressStatus status;
  final String label;
  final String? valueLabel;

  @override
  ConsumerState<GlassLinearProgress> createState() => _GlassLinearProgressState();
}

class _GlassLinearProgressState extends ConsumerState<GlassLinearProgress> with SingleTickerProviderStateMixin {
  late final AnimationController _band = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));

  @override
  void dispose() {
    _band.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = ref.watch(glassReducedProvider);
    final indeterminate = widget.value == null;
    if (indeterminate && !reduced) {
      if (!_band.isAnimating) _band.repeat();
    } else {
      _band.stop();
    }
    final status = widget.status;
    final bar = indeterminate
        ? AnimatedBuilder(
            animation: _band,
            builder: (context, _) => CustomPaint(
              painter: _LinearPainter(value: 0.3, offset: reduced ? 0.35 : _band.value, status: status, band: true),
              child: const SizedBox(height: 4, width: double.infinity),
            ),
          )
        : SpringValue(
            value: widget.value!.clamp(0.0, 1.0),
            spring: gt.springSnappy,
            builder: (context, v, _) => CustomPaint(
              painter: _LinearPainter(value: v, status: status),
              child: const SizedBox(height: 4, width: double.infinity),
            ),
          );
    final pct = widget.value == null ? 'Loading' : '${(widget.value! * 100).round()} percent';
    return GlassProgressSemantics(label: widget.label, value: widget.valueLabel ?? pct, child: Opacity(opacity: status == GlassProgressStatus.disabled ? 0.4 : 1, child: bar));
  }
}

class _LinearPainter extends CustomPainter {
  const _LinearPainter({required this.value, required this.status, this.offset = 0, this.band = false});
  final double value;
  final double offset;
  final GlassProgressStatus status;
  final bool band;

  @override
  void paint(Canvas canvas, Size size) {
    final r = Radius.circular(size.height / 2);
    canvas.drawRRect(RRect.fromRectAndRadius(Offset.zero & size, r), Paint()..color = gt.colorFill1);
    final w = size.width * value.clamp(0.0, 1.0);
    if (w <= 0) return;
    final left = band ? (size.width + w) * offset - w : 0.0;
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(Offset.zero & size, r));
    final rect = Rect.fromLTWH(left, 0, w, size.height);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, r), Paint()..color = _fillFor(status));
    if (!band && status == GlassProgressStatus.normal) {
      canvas.drawRect(Rect.fromLTWH(math.max(0, w - 1), 0, 1, size.height), Paint()..color = gt.colorIris300);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_LinearPainter old) => old.value != value || old.offset != offset || old.status != status;
}

/// `hairline` (reader, novel running head): 2 px, fill `iris500` at 80 %, following on `springTrack`.
class GlassHairlineProgress extends StatelessWidget {
  const GlassHairlineProgress({super.key, required this.value});
  final double value;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: SpringValue(
          value: value.clamp(0.0, 1.0),
          spring: gt.springTrack,
          builder: (context, v, _) => CustomPaint(painter: _HairlinePainter(v), child: const SizedBox(height: 2, width: double.infinity)),
        ),
      );
}

class _HairlinePainter extends CustomPainter {
  const _HairlinePainter(this.v);
  final double v;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = gt.colorFill1);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width * v.clamp(0.0, 1.0), size.height), Paint()..color = gt.colorIris500.withValues(alpha: 0.8));
  }

  @override
  bool shouldRepaint(_HairlinePainter old) => old.v != v;
}

/// `ring`: 24 or 32 px, 3 px stroke, track `fill1`, arc `iris500`, round caps, the arc on `springSnappy`.
class GlassRingProgress extends StatelessWidget {
  const GlassRingProgress({super.key, required this.value, this.size = 24, this.stroke = 3, this.status = GlassProgressStatus.normal, this.color, this.child});
  final double value;
  final double size;
  final double stroke;
  final GlassProgressStatus status;
  final Color? color;
  final Widget? child;

  @override
  Widget build(BuildContext context) => SpringValue(
        value: value.clamp(0.0, 1.0),
        spring: gt.springSnappy,
        builder: (context, v, _) => CustomPaint(
          painter: RingPainter(v: v, stroke: stroke, color: color ?? _fillFor(status)),
          child: SizedBox(width: size, height: size, child: child == null ? null : Center(child: child)),
        ),
      );
}

class RingPainter extends CustomPainter {
  const RingPainter({required this.v, required this.stroke, required this.color, this.trackColor});
  final double v;
  final double stroke;
  final Color color;
  final Color? trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(stroke / 2);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, math.pi * 2, false, p..color = trackColor ?? gt.colorFill1);
    if (v > 0) canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * v.clamp(0.0, 1.0), false, p..color = color);
  }

  @override
  bool shouldRepaint(RingPainter old) => old.v != v || old.color != color || old.stroke != stroke;
}

/// `spinner` (the liquid ring): a 16 or 24 px ring whose 90 degree arc stretches to 270 and back while
/// rotating once per 900 ms. Reduced motion: a static ring pulsing opacity 0.4 to 1 over 1.2 s.
class GlassSpinner extends ConsumerStatefulWidget {
  const GlassSpinner({super.key, this.size = 16, this.color, this.label});
  final double size;
  final Color? color;

  /// Exposed to assistive tech when the spinner is the only signal.
  final String? label;

  @override
  ConsumerState<GlassSpinner> createState() => _GlassSpinnerState();
}

class _GlassSpinnerState extends ConsumerState<GlassSpinner> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
  bool? _reduced;

  void _sync(bool reduced) {
    if (_reduced == reduced && _c.isAnimating) return;
    _reduced = reduced;
    _c.duration = Duration(milliseconds: reduced ? 1200 : 900);
    if (reduced) {
      _c.repeat(reverse: true);
    } else {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = ref.watch(glassReducedProvider);
    _sync(reduced);
    final color = widget.color ?? gt.colorOnGlass;
    final body = AnimatedBuilder(
      animation: _c,
      builder: (context, _) => CustomPaint(
        painter: _SpinnerPainter(t: _c.value, color: color, stroke: widget.size <= 16 ? 2 : 3, pulse: reduced),
        size: Size.square(widget.size),
      ),
    );
    return widget.label == null ? ExcludeSemantics(child: body) : Semantics(label: widget.label, excludeSemantics: true, child: body);
  }
}

class _SpinnerPainter extends CustomPainter {
  const _SpinnerPainter({required this.t, required this.color, required this.stroke, required this.pulse});
  final double t;
  final Color color;
  final double stroke;
  final bool pulse;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(stroke / 2);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    if (pulse) {
      canvas.drawArc(rect, 0, math.pi * 2, false, p..color = color.withValues(alpha: color.a * (0.4 + 0.6 * t)));
      return;
    }
    canvas.drawArc(rect, 0, math.pi * 2, false, p..color = color.withValues(alpha: color.a * 0.18));
    final sweep = math.pi / 2 + math.pi * (0.5 - 0.5 * math.cos(2 * math.pi * t));
    canvas.drawArc(rect, t * 2 * math.pi - math.pi / 2, sweep, false, p..color = color);
  }

  @override
  bool shouldRepaint(_SpinnerPainter old) => old.t != t || old.color != color || old.pulse != pulse;
}

/// `dots` (button loading): three 5 px dots 6 px apart, each bobbing 3 px on `springTick`, 80 ms apart.
class GlassDots extends ConsumerStatefulWidget {
  const GlassDots({super.key, this.color});
  final Color? color;

  @override
  ConsumerState<GlassDots> createState() => _GlassDotsState();
}

class _GlassDotsState extends ConsumerState<GlassDots> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  /// One bob: a quick rise and a springy return, [ms] into the cycle.
  static double bob(double ms) {
    if (ms < 0 || ms > 420) return 0;
    final x = ms / 420;
    return math.sin(math.pi * x) * (1 - 0.35 * x);
  }

  @override
  Widget build(BuildContext context) {
    final reduced = ref.watch(glassReducedProvider);
    if (reduced) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
    final color = widget.color ?? gt.colorOnGlass;
    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => SizedBox(
          width: 5 * 3 + 6 * 2,
          height: 11,
          child: Stack(
            children: [
              for (var i = 0; i < 3; i++)
                Positioned(
                  left: i * 11.0,
                  top: 3 + 3 - (reduced ? 0 : 3 * bob(_c.value * 1000 - i * 80)),
                  child: Container(width: 5, height: 5, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// `segmented` (read-all scrub, storage breakdown): a capsule divided into segments with 2 px gaps, widths
/// on `springSnappy`.
class GlassSegmentedBar extends StatelessWidget {
  const GlassSegmentedBar({super.key, required this.segments, this.height = 8, this.label = 'Breakdown'});
  final List<({double weight, Color color})> segments;
  final double height;
  final String label;

  @override
  Widget build(BuildContext context) {
    final total = segments.fold<double>(0, (a, s) => a + s.weight);
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(height / 2),
        child: SizedBox(
          height: height,
          child: Row(
            children: [
              for (var i = 0; i < segments.length; i++) ...[
                if (i > 0) const SizedBox(width: 2),
                Expanded(
                  flex: math.max(1, (segments[i].weight / (total == 0 ? 1 : total) * 1000).round()),
                  child: ColoredBox(color: segments[i].color),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The complete state: the check springs in on `springTick`.
class GlassCheckPop extends StatelessWidget {
  const GlassCheckPop({super.key, this.size = 16, this.color});
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) => SpringValue(
        value: 1,
        spring: gt.springTick,
        builder: (context, v, _) => Transform.scale(scale: v.clamp(0.0, 1.3), child: GlyphIcon(GlassGlyph.check, size: size, color: color ?? gt.colorSuccess, weight: GlassIconWeight.bold)),
      );
}
