import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/physics.dart' show SpringSimulation;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/glass/focus_ring.dart';
import 'package:manhwamaniacs/skins/glass/physics/glass_physics.dart';
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/press.dart';
import 'package:manhwamaniacs/skins/glass/primitives/slider_math.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

/// The speed dial (glass 8.16.3): a vertical glass capsule 64 x 240 rising out of its anchor on `springMorph` (its tier
/// interpolating from the anchor's tier to T4 through `tierValue`). Dragging up or down anywhere on it sets 0.5x to 3.0x
/// in 0.05 steps (6 px per step), with labelled marks at 0.5, 1, 1.5, 2, 2.5 and 3; `detent.tick` every 0.25x (the 0.05
/// steps are silent); a magnet at 1.0x (values within 0.08 are pulled to 1.0 with `detent.magnet`); past the ends it
/// rubber-bands 12 px; the value previews live while dragging ([onChanged]) and commits on release ([onCommit]); a hold
/// of 600 ms without moving resets to 1.0x; under the value the words-per-minute equivalent; preset chips beneath.
/// It is an anchored picker (no route, no URL state).
class GlassSpeedDial extends ConsumerStatefulWidget {
  const GlassSpeedDial({
    super.key,
    required this.value,
    required this.onChanged,
    required this.onCommit,
    required this.wpmAt,
    this.anchorTier = 3,
    this.anchorOffset = const Offset(0, 120),
  });

  final double value;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onCommit;
  final int Function(double speed) wpmAt;

  /// The tier of the control the dial rises from (1 to 5).
  final int anchorTier;

  /// Where the anchor sits relative to the dial's centre (the dial rises from there).
  final Offset anchorOffset;

  static const presets = [0.8, 1.0, 1.25, 1.5, 2.0];
  static const marks = [0.5, 1.0, 1.5, 2.0, 2.5, 3.0];

  @override
  ConsumerState<GlassSpeedDial> createState() => _GlassSpeedDialState();
}

class _GlassSpeedDialState extends ConsumerState<GlassSpeedDial> with TickerProviderStateMixin {
  late final AnimationController _rise = AnimationController.unbounded(vsync: this, value: ref.read(glassMotionPrefsProvider).reduced ? 1 : 0);
  late final AnimationController _over = AnimationController.unbounded(vsync: this);
  late final Animation<double> _tier = _rise.drive(Tween<double>(begin: widget.anchorTier.toDouble(), end: 4));
  static const double _w = 64, _h = 240;
  double _start = 1;
  double _raw = 1;
  double _dy = 0;
  double _shown = 1;
  bool _magnet = false;
  bool _drag = false;
  Timer? _hold;

  @override
  void initState() {
    super.initState();
    _shown = widget.value;
    if (!ref.read(glassMotionPrefsProvider).reduced) {
      _rise.animateWith(SpringSimulation(springOf(gt.springMorph), 0, 1, 0));
    }
  }

  @override
  void didUpdateWidget(GlassSpeedDial old) {
    super.didUpdateWidget(old);
    if (!_drag) _shown = widget.value;
  }

  @override
  void dispose() {
    _hold?.cancel();
    _rise.dispose();
    _over.dispose();
    super.dispose();
  }

  void _down() {
    _start = widget.value;
    _raw = _start;
    _dy = 0;
    _drag = true;
    _hold?.cancel();
    _hold = Timer(const Duration(milliseconds: 600), _reset);
  }

  void _reset() {
    if (!_drag) return;
    _hold = null;
    glassFire(ref, HapticEvent.detentMagnet);
    _apply(1.0, 1.0, magnet: true);
    widget.onCommit(1.0);
  }

  void _apply(double raw, double value, {required bool magnet}) {
    final prev = _shown;
    if (magnet && !_magnet) glassFire(ref, HapticEvent.detentMagnet);
    _magnet = magnet;
    if (dialTick(prev, value) && !magnet) glassFire(ref, HapticEvent.detentTick);
    _over.value = dialOvershootPx(raw);
    if (value != prev) {
      setState(() => _shown = value);
      widget.onChanged(value);
    }
  }

  void _move(double dy) {
    if (!_drag) return;
    _dy += dy;
    if (_hold != null && _dy.abs() > 4) {
      _hold?.cancel();
      _hold = null;
    }
    _raw = dialRaw(_start, _dy);
    final v = dialValue(_raw);
    _apply(_raw, v.value, magnet: v.magnet);
  }

  void _up() {
    if (!_drag) return;
    _hold?.cancel();
    _hold = null;
    _drag = false;
    _over.animateWith(SpringSimulation(springOf(gt.springTick), _over.value, 0, 0));
    widget.onCommit(_shown);
  }

  void _set(double v, {bool commit = true}) {
    final c = v.clamp(kDialMin, kDialMax);
    glassFire(ref, HapticEvent.detentTick);
    setState(() => _shown = c);
    widget.onChanged(c);
    if (commit) widget.onCommit(c);
  }

  /// Flutter's slider value is "1.25 times" (glass 8.15.5); the words-per-minute equivalent rides in the hint.
  String get _label => '${_fmt(_shown)} times';
  static String _fmt(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : (v * 100 % 10 == 0 ? v.toStringAsFixed(1) : v.toStringAsFixed(2));

  @override
  Widget build(BuildContext context) {
    final hit = GlassFrame.hitMin(context);
    final frac = (_shown - kDialMin) / (kDialMax - kDialMin);
    return Semantics(
      slider: true,
      explicitChildNodes: true,
      label: 'Speed',
      value: _label,
      hint: 'about ${widget.wpmAt(_shown)} words a minute',
      increasedValue: '${_fmt((_shown + kDialStep).clamp(kDialMin, kDialMax))} times',
      decreasedValue: '${_fmt((_shown - kDialStep).clamp(kDialMin, kDialMax))} times',
      onIncrease: () => _set(_shown + kDialStep),
      onDecrease: () => _set(_shown - kDialStep),
      child: Focus(
        onKeyEvent: (n, e) {
          if (e is! KeyDownEvent && e is! KeyRepeatEvent) return KeyEventResult.ignored;
          final k = e.logicalKey;
          if (k == LogicalKeyboardKey.arrowUp || k == LogicalKeyboardKey.arrowRight) {
            _set(_shown + kDialStep);
          } else if (k == LogicalKeyboardKey.arrowDown || k == LogicalKeyboardKey.arrowLeft) {
            _set(_shown - kDialStep);
          } else if (k == LogicalKeyboardKey.pageUp) {
            _set(_shown + 0.25);
          } else if (k == LogicalKeyboardKey.pageDown) {
            _set(_shown - 0.25);
          } else if (k == LogicalKeyboardKey.home) {
            _set(kDialMin);
          } else if (k == LogicalKeyboardKey.end) {
            _set(kDialMax);
          } else {
            return KeyEventResult.ignored;
          }
          return KeyEventResult.handled;
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: Listenable.merge([_rise, _over]),
              builder: (context, child) {
                final t = _rise.value;
                return Opacity(
                  opacity: t.clamp(0.0, 1.0),
                  child: Transform.translate(
                    offset: Offset(widget.anchorOffset.dx * (1 - t), widget.anchorOffset.dy * (1 - t)),
                    child: Transform.scale(key: const ValueKey('glass-dial-scale'), scale: 0.4 + 0.6 * t.clamp(0.0, 1.2), child: child),
                  ),
                );
              },
              child: GlassFocusRing(
                shape: const GlassShape.superellipse(32),
                child: Listener(
                  onPointerDown: (_) => _down(),
                  onPointerUp: (_) => _up(),
                  onPointerCancel: (_) => _up(),
                  onPointerMove: (e) => _move(e.delta.dy),
                  child: SizedBox(
                    width: _w,
                    height: _h,
                    child: SkinGlass(
                      key: const ValueKey('glass-dial-capsule'),
                      tierValue: _tier,
                      shape: const GlassShape.superellipse(32),
                      layer: GlassLayerKind.overlays,
                      debugLabel: 'GlassSpeedDial',
                      child: ExcludeSemantics(
                        child: AnimatedBuilder(
                        animation: _over,
                        builder: (context, _) => CustomPaint(
                          size: const Size(_w, _h),
                          painter: _DialPainter(frac: frac, over: _over.value),
                          child: Center(child: GlassText('${_fmt(_shown)}×', role: gt.typeMonoLarge, onGlass: true)),
                        ),
                      ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            GlassText('≈ ${widget.wpmAt(_shown)} wpm', role: gt.typeCaption1, onGlass: true, color: gt.colorLabel2),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              alignment: WrapAlignment.center,
              children: [
                for (final p in GlassSpeedDial.presets)
                  GlassPressable(
                    material: GlassMaterial.content,
                    growth: GlassGrowth.light,
                    sink: 0.96,
                    onTap: () => _set(p),
                    semanticsLabel: '${_fmt(p)} times',
                    semanticsSelected: (_shown - p).abs() < 0.001,
                    builder: (context, info) => SizedBox(
                      height: hit,
                      child: Center(
                        child: DecoratedBox(
                          decoration: BoxDecoration(color: (_shown - p).abs() < 0.001 ? gt.colorIris600 : gt.colorFill2, borderRadius: BorderRadius.circular(16)),
                          child: Padding(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), child: GlassText(_fmt(p), role: gt.typeMono, size: 13, onGlass: true)),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DialPainter extends CustomPainter {
  const _DialPainter({required this.frac, required this.over});
  final double frac;
  final double over;

  @override
  void paint(Canvas canvas, Size size) {
    const pad = 22.0;
    final top = pad, bottom = size.height - pad;
    final len = bottom - top;
    double yOf(double v) => bottom - len * (v - kDialMin) / (kDialMax - kDialMin);
    final tick = Paint()..color = const Color(0x66FFFFFF)..strokeWidth = 1.5;
    for (final m in GlassSpeedDial.marks) {
      final y = yOf(m);
      canvas.drawLine(Offset(10, y), Offset(m == 1.0 ? 26 : 20, y), tick);
      final tp = TextPainter(
        text: TextSpan(text: m == m.roundToDouble() ? m.toStringAsFixed(0) : m.toStringAsFixed(1), style: const TextStyle(fontSize: 10, color: Color(0x99FFFFFF), fontFamily: 'GoogleSansCodeMM')),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(size.width - 8 - tp.width, y - tp.height / 2));
      tp.dispose();
    }
    final y = yOf((kDialMin + frac * (kDialMax - kDialMin))) - over;
    canvas.drawRRect(RRect.fromLTRBR(8, y - 1.5, size.width - 8, y + 1.5, const Radius.circular(2)), Paint()..color = gt.colorIris400);
    canvas.drawCircle(Offset(size.width / 2, math.max(top - 6, math.min(bottom + 6, y))), 0, Paint());
  }

  @override
  bool shouldRepaint(_DialPainter old) => old.frac != frac || old.over != over;
}
