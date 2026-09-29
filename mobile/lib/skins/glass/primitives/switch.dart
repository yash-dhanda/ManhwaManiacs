import 'package:flutter/gestures.dart' show DragEndDetails, DragStartDetails, DragUpdateDetails;
import 'package:flutter/physics.dart' show SpringSimulation;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/physics/glass_physics.dart';
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/press.dart';
import 'package:manhwamaniacs/skins/glass/primitives/progress.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart';

/// The switch (glass 7.22): a 51 x 31 track (off `fill1`, on `iris600`), a 27 px white knob. A tap moves the knob
/// on `springTick` (its 4.6 % overshoot is the click) and the track colour shifts over `curveColorShift`.
/// Dragging turns the knob into transient `glassFilm` clear glass stretched to 34 x 27; on release it projects to on
/// or off. Loading shows a 12 px spinner in the knob and is not toggleable; an error springs the knob back to the
/// previous side with the shake (the caller shows the toast).
class GlassSwitch extends ConsumerStatefulWidget {
  const GlassSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
    this.loading = false,
    this.errorTrigger = 0,
    this.forceStates = GlassWidgetStates.none,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String label;
  final bool loading;

  /// Every increase springs the knob back to [value]'s side, shakes and fires `error`.
  final int errorTrigger;
  final GlassWidgetStates forceStates;

  @override
  ConsumerState<GlassSwitch> createState() => _GlassSwitchState();
}

class _GlassSwitchState extends ConsumerState<GlassSwitch> with SingleTickerProviderStateMixin {
  static const double _w = 51, _h = 31, _knob = 27, _pad = 2, _travel = _w - _knob - 2 * _pad;

  late final AnimationController _p = AnimationController.unbounded(vsync: this, value: widget.value ? 1 : 0);
  bool _dragging = false;
  double _dragX = 0;
  double _startP = 0;

  bool get _enabled => widget.onChanged != null && !widget.loading && !widget.forceStates.disabled;
  bool get _reduced => ref.read(glassMotionPrefsProvider).reduced;

  @override
  void didUpdateWidget(GlassSwitch old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value || widget.errorTrigger > old.errorTrigger) _to(widget.value ? 1 : 0);
    if (widget.errorTrigger > old.errorTrigger) glassFire(ref, HapticEvent.error);
  }

  @override
  void dispose() {
    _p.dispose();
    super.dispose();
  }

  void _to(double target, {double velocity = 0}) {
    if (_reduced) {
      _p.stop();
      _p.value = target;
      return;
    }
    _p.animateWith(SpringSimulation(springOf(gt.springTick), _p.value, target, velocity));
  }

  void _toggleTo(bool v) {
    glassFire(ref, v ? HapticEvent.toggleOn : HapticEvent.toggleOff);
    glassSound(ref, v ? SoundEvent.toggleOn : SoundEvent.toggleOff);
    _to(v ? 1 : 0);
    widget.onChanged?.call(v);
  }

  void _tap() {
    if (!_enabled) return;
    _toggleTo(!widget.value);
  }

  void _dragStart(DragStartDetails d) {
    if (!_enabled) return;
    _p.stop();
    _startP = _p.value;
    _dragX = 0;
    setState(() => _dragging = true);
  }

  void _dragUpdate(DragUpdateDetails d) {
    if (!_dragging) return;
    _dragX += d.delta.dx;
    _p.value = (_startP + _dragX / _travel).clamp(0.0, 1.0);
  }

  void _dragEnd(DragEndDetails d) {
    if (!_dragging) return;
    setState(() => _dragging = false);
    final v = d.velocity.pixelsPerSecond.dx / _travel;
    final projected = _p.value + v * 0.499;
    final on = projected >= 0.5;
    if (on != widget.value) {
      _toggleTo(on);
    } else {
      _to(on ? 1 : 0, velocity: v);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hit = GlassFrame.hitMin(context);
    final disabled = widget.onChanged == null || widget.forceStates.disabled;
    return GlassPressable(
      material: GlassMaterial.content,
      growth: GlassGrowth.light,
      sink: 1,
      shape: const GlassShape.capsule(),
      enabled: _enabled,
      loading: widget.loading,
      onTap: _tap,
      toggled: widget.value,
      semanticsLabel: widget.label,
      forceStates: widget.forceStates,
      errorTrigger: widget.errorTrigger,
      shakeAmplitude: 4,
      builder: (context, info) {
        final pressed = info.states.pressed || _dragging;
        final hovered = info.states.hovered && !disabled;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: _dragStart,
          onHorizontalDragUpdate: _dragUpdate,
          onHorizontalDragEnd: _dragEnd,
          child: SizedBox(
            width: _w,
            height: hit > _h ? hit : _h,
            child: Center(
              child: Opacity(
                opacity: disabled ? 0.4 : 1,
                child: SizedBox(
                  width: _w,
                  height: _h,
                  child: AnimatedBuilder(
                    animation: _p,
                    builder: (context, _) {
                      final p = _p.value;
                      final knobW = pressed ? 34.0 : _knob;
                      final base = _pad + p * _travel;
                      // A stretched knob grows toward its travel direction (right when going on).
                      final left = pressed ? base - (p >= 0.5 ? (knobW - _knob) : 0) : base;
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          TweenAnimationBuilder<Color?>(
                            tween: ColorTween(end: Color.lerp(gt.colorFill1, gt.colorIris600, widget.value ? 1 : 0)),
                            duration: gt.curveColorShift.duration,
                            curve: gt.curveColorShift.curve,
                            builder: (context, c, _) => DecoratedBox(
                              decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(_h / 2)),
                              child: const SizedBox(width: _w, height: _h),
                            ),
                          ),
                          Positioned(
                            left: left,
                            top: (_h - 27) / 2,
                            child: _dragging
                                ? SkinGlass(
                                    key: const ValueKey('glass-switch-knob-glass'),
                                    size: const Size(34, 27),
                                    tier: GlassTierId.t1,
                                    finish: GlassFinishKind.clear,
                                    role: GlassRole.transient,
                                    materialize: false,
                                    debugLabel: 'GlassSwitchKnob',
                                    child: const SizedBox.expand(),
                                  )
                                : Container(
                                    key: const ValueKey('glass-switch-knob'),
                                    width: knobW,
                                    height: 27,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFFFFF),
                                      borderRadius: BorderRadius.circular(13.5),
                                      boxShadow: [
                                        const BoxShadow(color: Color(0x66000000), offset: Offset(0, 2), blurRadius: 8),
                                        if (hovered) BoxShadow(color: gt.colorIris400.withValues(alpha: 0.5), blurRadius: 10),
                                      ],
                                    ),
                                    child: widget.loading ? const GlassSpinner(size: 12, color: Color(0xFF5B4AD1)) : null,
                                  ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
