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
import 'package:manhwamaniacs/skins/glass/primitives/press.dart' show GlassWidgetStates;
import 'package:manhwamaniacs/skins/glass/primitives/progress.dart';
import 'package:manhwamaniacs/skins/glass/primitives/slider_math.dart';
import 'package:manhwamaniacs/skins/glass/primitives/spring_value.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

/// The slider (glass 7.21): a 6 px `fill1` track with an `iris500` fill and a 28 px white thumb inside a `hitMin`
/// hit. While dragged the thumb is transient glass, grows to 34 px on `springPress` and the track thickens to 8 px.
/// Stepped sliders ([divisions]) fire `detent.tick` per step and magnetise within 30 % of the step spacing; past
/// min or max the thumb rubber-bands at most 12 px with `detent.limit`. The value shows in `mono` 13 trailing, or in
/// a `glassThin` bubble above the thumb while dragging.
class GlassSlider extends ConsumerStatefulWidget {
  const GlassSlider({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
    this.onChangeEnd,
    this.min = 0,
    this.max = 1,
    this.divisions,
    this.format,
    this.loading = false,
    this.errorTrigger = 0,
    this.forceStates = GlassWidgetStates.none,
    this.forceDragging = false,
  });

  final double value;
  final ValueChanged<double>? onChanged;
  final ValueChanged<double>? onChangeEnd;
  final String label;
  final double min;
  final double max;
  final int? divisions;
  final String Function(double value)? format;
  final bool loading;

  /// Every increase springs the thumb back to the last saved [value] on `springTick`.
  final int errorTrigger;
  final GlassWidgetStates forceStates;

  /// For captures: draw the dragging state.
  final bool forceDragging;

  @override
  ConsumerState<GlassSlider> createState() => _GlassSliderState();
}

class _GlassSliderState extends ConsumerState<GlassSlider> with SingleTickerProviderStateMixin {
  late final AnimationController _pos = AnimationController.unbounded(vsync: this, value: _frac(widget.value));
  bool _drag = false;
  bool _hover = false;
  double _trackLen = 1;
  double _raw = 0;
  double _grab = 0;
  int _lastStep = -1;
  bool _atLimit = false;
  final FocusNode _focus = FocusNode(debugLabel: 'GlassSlider');

  double _frac(double v) => widget.max == widget.min ? 0 : ((v - widget.min) / (widget.max - widget.min)).clamp(0.0, 1.0);
  double _valueOf(double f) => widget.min + f.clamp(0.0, 1.0) * (widget.max - widget.min);
  bool get _enabled => widget.onChanged != null && !widget.forceStates.disabled;
  bool get _reduced => ref.read(glassMotionPrefsProvider).reduced;

  @override
  void didUpdateWidget(GlassSlider old) {
    super.didUpdateWidget(old);
    if (_drag) return;
    if (old.value != widget.value || old.min != widget.min || old.max != widget.max || widget.errorTrigger > old.errorTrigger) {
      _springTo(_frac(widget.value));
    }
    if (widget.errorTrigger > old.errorTrigger) glassFire(ref, HapticEvent.error);
  }

  @override
  void dispose() {
    _pos.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _springTo(double f) {
    if (_reduced) {
      _pos.value = f;
      return;
    }
    _pos.animateWith(SpringSimulation(springOf(gt.springTick), _pos.value, f, _pos.velocity));
  }

  void _setFromPx(double px) {
    final spacing = widget.divisions == null ? 0.0 : _trackLen / widget.divisions!;
    var overshoot = 0.0;
    var p = px;
    if (px < 0) {
      overshoot = px;
      p = 0;
    } else if (px > _trackLen) {
      overshoot = px - _trackLen;
      p = _trackLen;
    }
    if (overshoot != 0) {
      if (!_atLimit) glassFire(ref, HapticEvent.detentLimit);
      _atLimit = true;
    } else {
      _atLimit = false;
    }
    if (widget.divisions != null) {
      final m = stepMagnet(p, spacing, widget.divisions!);
      p = m.pos;
      final step = nearestStep(p, spacing, widget.divisions!);
      if (m.magnet && step != _lastStep) {
        glassFire(ref, HapticEvent.detentTick);
        _lastStep = step;
        widget.onChanged?.call(_valueOf(step / widget.divisions!));
      }
    } else {
      widget.onChanged?.call(_valueOf(p / _trackLen));
    }
    _pos.value = p / _trackLen + sliderRubber(overshoot, _trackLen) / _trackLen;
  }

  /// [x] is the pointer in the track's own px (0 at the track's start). Grabbing the thumb keeps the grab offset;
  /// grabbing the track moves the thumb under the finger.
  void _start(double x) {
    if (!_enabled) return;
    _pos.stop();
    final thumbX = _pos.value * _trackLen;
    _grab = (x - thumbX).abs() <= 22 ? x - thumbX : 0;
    setState(() => _drag = true);
    _raw = x - _grab;
    if (widget.divisions != null) _lastStep = nearestStep(_frac(widget.value) * _trackLen, _trackLen / widget.divisions!, widget.divisions!);
    _setFromPx(_raw);
  }

  void _update(double x) {
    if (!_drag) return;
    _raw = x - _grab;
    _setFromPx(_raw);
  }

  void _end() {
    if (!_drag) return;
    setState(() => _drag = false);
    var f = _pos.value.clamp(0.0, 1.0);
    if (widget.divisions != null) f = nearestStep(f * _trackLen, _trackLen / widget.divisions!, widget.divisions!) / widget.divisions!;
    _springTo(f);
    _lastStep = -1;
    _atLimit = false;
    widget.onChangeEnd?.call(_valueOf(f));
  }

  void _key(double delta) {
    final v = (widget.value + delta).clamp(widget.min, widget.max);
    if (v == widget.value) {
      glassFire(ref, HapticEvent.detentLimit);
      return;
    }
    glassFire(ref, HapticEvent.detentTick);
    widget.onChanged?.call(v);
    widget.onChangeEnd?.call(v);
  }

  double get _stepSize => widget.divisions != null ? (widget.max - widget.min) / widget.divisions! : (widget.max - widget.min) / 100;

  @override
  Widget build(BuildContext context) {
    final hit = GlassFrame.hitMin(context);
    final disabled = !_enabled;
    final dragging = _drag || widget.forceDragging;
    final valueText = widget.format?.call(widget.value) ?? widget.value.toStringAsFixed(widget.divisions == null ? 2 : 0);
    final thumbSize = dragging ? 34.0 : (_hover || widget.forceStates.hovered ? 30.0 : 28.0);

    final track = LayoutBuilder(
      builder: (context, c) {
        _trackLen = math.max(1, c.maxWidth - 28);
        return SizedBox(
          height: math.max(hit, 44),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragStart: (d) => _start(d.localPosition.dx - 14),
            onHorizontalDragUpdate: (d) => _update(d.localPosition.dx - 14),
            onHorizontalDragEnd: (_) => _end(),
            onHorizontalDragCancel: _end,
            onTapDown: (d) {
              if (!_enabled) return;
              _focus.requestFocus();
              final px = (d.localPosition.dx - 14).clamp(0.0, _trackLen);
              _drag = true;
              _pos.stop();
              _raw = px;
              _setFromPx(px);
              _drag = false;
              widget.onChangeEnd?.call(_valueOf(_pos.value.clamp(0.0, 1.0)));
              _springTo(widget.divisions == null ? (_pos.value.clamp(0.0, 1.0)) : nearestStep(px, _trackLen / widget.divisions!, widget.divisions!) / widget.divisions!);
            },
            child: AnimatedBuilder(
              animation: _pos,
              builder: (context, _) {
                final f = _pos.value;
                final x = 14 + f * _trackLen;
                final th = dragging ? 8.0 : 6.0;
                return Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.centerLeft,
                  children: [
                    Positioned(
                      left: 14,
                      right: 14,
                      child: Center(
                        child: SizedBox(
                          height: th,
                          child: DecoratedBox(
                            decoration: BoxDecoration(color: disabled ? GlassColors.g300 : gt.colorFill1, borderRadius: BorderRadius.circular(th / 2)),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: FractionallySizedBox(
                                widthFactor: f.clamp(0.0, 1.0),
                                child: DecoratedBox(decoration: BoxDecoration(color: disabled ? GlassColors.g500 : gt.colorIris500, borderRadius: BorderRadius.circular(th / 2)), child: const SizedBox.expand()),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: x - thumbSize / 2,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: GlassFocusRing(
                          shape: const GlassShape.circle(),
                          child: SpringValue(
                            value: thumbSize,
                            spring: gt.springPress,
                            builder: (context, size, _) => dragging
                                ? SkinGlass(
                                    key: const ValueKey('glass-slider-thumb-glass'),
                                    size: Size.square(size),
                                    tier: GlassTierId.t1,
                                    finish: GlassFinishKind.clear,
                                    role: GlassRole.transient,
                                    shape: const GlassShape.circle(),
                                    materialize: false,
                                    debugLabel: 'GlassSliderThumb',
                                    child: const SizedBox.expand(),
                                  )
                                : DecoratedBox(
                                    key: const ValueKey('glass-slider-thumb'),
                                    decoration: BoxDecoration(
                                      color: disabled ? GlassColors.g500 : const Color(0xFFFFFFFF),
                                      shape: BoxShape.circle,
                                      boxShadow: const [BoxShadow(color: Color(0x66000000), offset: Offset(0, 2), blurRadius: 8)],
                                    ),
                                    child: SizedBox.square(dimension: size),
                                  ),
                          ),
                        ),
                      ),
                    ),
                    if (dragging)
                      Positioned(
                        left: x - 28,
                        top: -34,
                        width: 56,
                        height: 30,
                        child: SkinGlass(
                          key: const ValueKey('glass-slider-bubble'),
                          tier: GlassTierId.t2,
                          layer: GlassLayerKind.hud,
                          debugLabel: 'GlassSliderBubble',
                          child: Center(child: GlassText(valueText, role: gt.typeMono, size: 13, onGlass: true)),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );

    return Semantics(
      slider: true,
      excludeSemantics: true,
      enabled: _enabled,
      label: widget.label,
      value: valueText,
      increasedValue: widget.format?.call(math.min(widget.max, widget.value + _stepSize)) ?? '${math.min(widget.max, widget.value + _stepSize)}',
      decreasedValue: widget.format?.call(math.max(widget.min, widget.value - _stepSize)) ?? '${math.max(widget.min, widget.value - _stepSize)}',
      onIncrease: _enabled ? () => _key(_stepSize) : null,
      onDecrease: _enabled ? () => _key(-_stepSize) : null,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: Focus(
          focusNode: _focus,
          canRequestFocus: _enabled,
          onKeyEvent: (n, e) {
            if (e is! KeyDownEvent && e is! KeyRepeatEvent) return KeyEventResult.ignored;
            final k = e.logicalKey;
            if (k == LogicalKeyboardKey.arrowRight || k == LogicalKeyboardKey.arrowUp) {
              _key(_stepSize);
            } else if (k == LogicalKeyboardKey.arrowLeft || k == LogicalKeyboardKey.arrowDown) {
              _key(-_stepSize);
            } else if (k == LogicalKeyboardKey.pageUp) {
              _key(_stepSize * 10);
            } else if (k == LogicalKeyboardKey.pageDown) {
              _key(-_stepSize * 10);
            } else if (k == LogicalKeyboardKey.home) {
              _key(widget.min - widget.value);
            } else if (k == LogicalKeyboardKey.end) {
              _key(widget.max - widget.value);
            } else {
              return KeyEventResult.ignored;
            }
            return KeyEventResult.handled;
          },
          child: Row(
            children: [
              Expanded(child: track),
              SizedBox(
                width: 52,
                child: Center(
                  child: widget.loading
                      ? const GlassSpinner(size: 14)
                      : GlassText(valueText, role: gt.typeMono, size: 13, color: disabled ? GlassColors.g500 : gt.colorLabel2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
