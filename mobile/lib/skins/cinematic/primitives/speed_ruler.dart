import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:manhwamaniacs/skins/cinematic/feedback.dart';
import 'package:manhwamaniacs/skins/cinematic/hit.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_slug_lines.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// The speed ruler's range: 0.50 to 3.00 in 0.05 steps.
const double kSpeedMin = 0.5, kSpeedMax = 3.0, kSpeedStep = 0.05;

/// The labelled ticks.
const List<double> kSpeedLabels = [0.5, 1, 1.5, 2, 2.5, 3];

/// The preset slugs.
const List<double> kSpeedPresets = [0.8, 1, 1.25, 1.5, 2];

/// [x] snapped to the 0.05 step inside 0.50-3.00, free of float noise.
double snapSpeedX(double x) => double.parse(((x.clamp(kSpeedMin, kSpeedMax) / kSpeedStep).round() * kSpeedStep).toStringAsFixed(2));

/// The speed at [dx] px along a track [width] wide.
double speedAt(double dx, double width) => snapSpeedX(kSpeedMin + (dx / (width <= 0 ? 1 : width)).clamp(0.0, 1.0) * (kSpeedMax - kSpeedMin));

/// The x of [speed] on a track [width] wide.
double speedX(double speed, double width) => (speed.clamp(kSpeedMin, kSpeedMax) - kSpeedMin) / (kSpeedMax - kSpeedMin) * width;

/// Whether moving from [from] to [to] crosses a 0.25x mark (a `select` haptic each).
bool crossesQuarter(double from, double to) => (from / 0.25).floor() != (to / 0.25).floor();

/// `1.25×`.
String speedLabel(double x) => '${x.toStringAsFixed(2)}×';

/// The auto-scroll speed ruler (cinematic 9.4.1), shared by Reading setup, Listen and the
/// auto-scroll chip: a track with a tick per step and labels at 0.5, 1, 1.5, 2, 2.5 and 3, a value
/// flag while dragging, the value committed on release, preset slugs, and touch-and-hold anywhere
/// on the track to reset to 1.00x. [pxCaption] says the equivalent in px/s under the value.
class SpeedRuler extends StatefulWidget {
  const SpeedRuler({super.key, required this.value, required this.onChanged, required this.onCommit, this.pxCaption, this.showPresets = true});

  final double value;

  /// Live, while dragging.
  final ValueChanged<double> onChanged;

  /// On release, a preset, a hold reset.
  final ValueChanged<double> onCommit;
  final String Function(double speed)? pxCaption;
  final bool showPresets;

  @override
  State<SpeedRuler> createState() => _SpeedRulerState();
}

class _SpeedRulerState extends State<SpeedRuler> with SingleTickerProviderStateMixin {
  late final AnimationController _settle = AnimationController.unbounded(vsync: this);
  double? _draft;
  double _width = 1;

  @override
  void dispose() {
    _settle.dispose();
    super.dispose();
  }

  double get _shown => _draft ?? widget.value;

  void _drag(double dx) {
    final next = speedAt(dx, _width);
    if (next == _draft) return;
    if (crossesQuarter(_draft ?? widget.value, next)) cineFeedback(context, HapticEvent.select);
    setState(() => _draft = next);
    widget.onChanged(next);
  }

  void _release() {
    final v = _draft;
    if (v == null) return;
    setState(() => _draft = null);
    widget.onCommit(v);
    if (!CineMotion.reduced(context)) {
      final from = speedX(v, _width);
      _settle
        ..value = from
        ..animateWith(SpringSimulation(CineSprings.scrub.description, from, speedX(v, _width), 0));
    }
  }

  void _reset() {
    cineFeedback(context, HapticEvent.select);
    setState(() => _draft = null);
    widget.onChanged(1.0);
    widget.onCommit(1.0);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final hit = cineHitMin(context);
    final v = _shown;
    return Semantics(
      slider: true,
      label: 'Auto-scroll speed',
      value: 'Speed ${v.toStringAsFixed(2)} times',
      increasedValue: 'Speed ${snapSpeedX(v + kSpeedStep)} times',
      decreasedValue: 'Speed ${snapSpeedX(v - kSpeedStep)} times',
      onIncrease: () => widget.onCommit(snapSpeedX(v + kSpeedStep)),
      onDecrease: () => widget.onCommit(snapSpeedX(v - kSpeedStep)),
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CineRoleText(speedLabel(v), c.typeFolio, color: c.colorSpot),
              if (widget.pxCaption != null) ...[
                const SizedBox(width: 8),
                CineRoleText(widget.pxCaption!(v), c.typeCaption, color: c.colorInk60),
              ],
            ],
          ),
          LayoutBuilder(
            builder: (context, box) {
              _width = box.maxWidth.isFinite ? box.maxWidth : 1;
              return GestureDetector(
                key: const ValueKey('speed-ruler-track'),
                behavior: HitTestBehavior.opaque,
                onTapDown: (d) => _drag(d.localPosition.dx),
                onTapUp: (_) => _release(),
                onTapCancel: _release,
                onHorizontalDragStart: (d) => _drag(d.localPosition.dx),
                onHorizontalDragUpdate: (d) => _drag(d.localPosition.dx),
                onHorizontalDragEnd: (_) => _release(),
                onHorizontalDragCancel: _release,
                onLongPress: _reset,
                child: SizedBox(
                  height: hit + 20,
                  child: AnimatedBuilder(
                    animation: _settle,
                    builder: (context, _) {
                      final x = _draft != null ? speedX(_draft!, _width) : (_settle.isAnimating ? _settle.value : speedX(widget.value, _width));
                      return CustomPaint(
                        size: Size(_width, hit + 20),
                        painter: _SpeedPainter(x: x, dragging: _draft != null, track: c.colorRule2, played: c.colorInk100, tick: c.colorInk30, hit: hit),
                        child: Stack(
                          children: [
                            for (final l in kSpeedLabels)
                              Positioned(
                                left: (speedX(l, _width) - 12).clamp(0.0, math.max(0.0, _width - 24)),
                                bottom: 0,
                                child: CineRoleText(l == l.roundToDouble() ? l.toStringAsFixed(l == 0.5 ? 1 : 0) : l.toString(), c.typeFolio, color: c.colorInk60),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
          if (widget.showPresets)
            CineSlugLines(
              items: [for (final p in kSpeedPresets) CineSlug(p.toString(), p == p.roundToDouble() ? p.toStringAsFixed(0) : p.toString())],
              selected: {for (final p in kSpeedPresets) if ((p - v).abs() < 0.001) p.toString()},
              onChanged: (id) => widget.onCommit(double.parse(id)),
            ),
        ],
      ),
    );
  }
}

class _SpeedPainter extends CustomPainter {
  _SpeedPainter({required this.x, required this.dragging, required this.track, required this.played, required this.tick, required this.hit});
  final double x, hit;
  final bool dragging;
  final Color track, played, tick;

  @override
  void paint(Canvas canvas, Size size) {
    final y = hit / 2;
    canvas.drawRect(Rect.fromLTWH(0, y - 1, size.width, 2), Paint()..color = track);
    canvas.drawRect(Rect.fromLTRB(0, y - 1, x, y + 1), Paint()..color = played);
    final steps = ((kSpeedMax - kSpeedMin) / kSpeedStep).round();
    final tp = Paint()..color = tick;
    for (var i = 0; i <= steps; i++) {
      final sx = i / steps * size.width;
      final major = i % 10 == 0;
      canvas.drawRect(Rect.fromLTWH((sx - 0.5).clamp(0.0, size.width - 1), y + 4, 1, major ? 8 : 4), tp);
    }
    final w = dragging ? 3.0 : 2.0, h = dragging ? 24.0 : 16.0;
    canvas.drawRect(Rect.fromLTWH((x - w / 2).clamp(0.0, size.width - w), y - h / 2, w, h), Paint()..color = played);
  }

  @override
  bool shouldRepaint(_SpeedPainter o) => o.x != x || o.dragging != dragging || o.track != track;
}
