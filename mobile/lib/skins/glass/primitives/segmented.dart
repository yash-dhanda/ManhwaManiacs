import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/glass/focus_ring.dart';
import 'package:manhwamaniacs/skins/glass/glass/shape.dart';
import 'package:manhwamaniacs/skins/glass/motion.dart';
import 'package:manhwamaniacs/skins/glass/motion_names.g.dart';
import 'package:manhwamaniacs/skins/glass/physics/glass_physics.dart';
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/press.dart';
import 'package:manhwamaniacs/skins/glass/primitives/progress.dart';
import 'package:manhwamaniacs/skins/glass/primitives/segmented_math.dart';
import 'package:manhwamaniacs/skins/glass/primitives/spring_value.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart';
import 'package:motor/motor.dart';

class GlassSegment<T> {
  const GlassSegment({required this.value, required this.label});
  final T value;
  final String label;
}

/// The segmented control (glass 7.6). Tapping a segment moves the thumb on `springTab`. Dragging the thumb
/// turns it into transient glass (`SkinGlass(tier: t1, finish: clear, role: transient)`, registered only
/// while dragged), following on `springTrack`, stretching `1 + min(|v| / 2000, 0.25)`, with a `select`
/// haptic at each boundary; release projects to the nearest segment and settles on `springTab`.
/// 2 to 5 segments (more must be a menu). [axis] vertical is the desktop-frame Search scope column.
class GlassSegmented<T> extends ConsumerStatefulWidget {
  const GlassSegmented({
    super.key,
    required this.segments,
    required this.selected,
    required this.onSelected,
    this.axis = Axis.horizontal,
    this.asTabs = false,
    this.compact = false,
    this.enabled = true,
    this.loadingValue,
    this.errorTrigger = 0,
    this.forceStates = GlassWidgetStates.none,
    this.forceDragging = false,
  }) : assert(segments.length >= 2 && segments.length <= 5, 'A segmented control has 2 to 5 segments; more must be a menu (glass 7.6).');

  final List<GlassSegment<T>> segments;
  final T selected;
  final ValueChanged<T> onSelected;
  final Axis axis;

  /// It switches panels: each segment is `selected` instead of `checked`.
  final bool asTabs;
  final bool compact;
  final bool enabled;

  /// The segment whose data is loading: its label becomes a spinner, the thumb stays.
  final T? loadingValue;

  /// Every increase springs the thumb back to [selected] on `springTick` (the caller shows the toast).
  final int errorTrigger;
  final GlassWidgetStates forceStates;

  /// For captures: draw the thumb as transient glass.
  final bool forceDragging;

  @override
  ConsumerState<GlassSegmented<T>> createState() => _GlassSegmentedState<T>();
}

class _GlassSegmentedState<T> extends ConsumerState<GlassSegmented<T>> with SingleTickerProviderStateMixin {
  late final SingleMotionController _x = SingleMotionController(motion: SpringMotion(springOf(gt.springTab)), vsync: this);
  final FocusNode _focus = FocusNode(debugLabel: 'GlassSegmented');
  bool _dragging = false;
  bool _placed = false;
  int _idx = 0;
  List<double> _widths = const [];
  double _thumbAtDragStart = 0;
  double _dragDx = 0;

  bool get _vertical => widget.axis == Axis.vertical;

  int get _index => math.max(0, widget.segments.indexWhere((s) => s.value == widget.selected));

  @override
  void initState() {
    super.initState();
    _x.value = 0;
  }

  @override
  void didUpdateWidget(GlassSegmented<T> old) {
    super.didUpdateWidget(old);
    if (widget.errorTrigger > old.errorTrigger) {
      _x.motion = SpringMotion(springOf(gt.springTick));
      _x.animateTo(_lefts()[_index]);
    }
  }

  @override
  void dispose() {
    _x.dispose();
    _focus.dispose();
    super.dispose();
  }

  List<double> _lefts() {
    var x = 0.0;
    return [
      for (final w in _widths)
        () {
          final l = x;
          x += w;
          return l;
        }(),
    ];
  }

  void _select(int i) {
    if (!widget.enabled) return;
    final v = widget.segments[i].value;
    if (v != widget.selected) widget.onSelected(v);
  }

  void _dragStart() {
    if (!widget.enabled) return;
    _dragging = true;
    _thumbAtDragStart = _x.value;
    _dragDx = 0;
    setState(() {});
  }

  void _dragUpdate(double delta) {
    if (!_dragging) return;
    final before = _x.value + _widths[_index] / 2;
    _dragDx += delta;
    final total = _widths.fold<double>(0, (a, b) => a + b);
    final target = (_thumbAtDragStart + _dragDx).clamp(0.0, total - _widths[_index]);
    _x.motion = SpringMotion(springOf(gt.springTrack));
    _x.animateTo(target);
    final centre = target + _widths[_index] / 2;
    final n = boundaryCrossings(before, centre, _widths);
    for (var i = 0; i < n; i++) {
      glassFire(ref, HapticEvent.select);
    }
  }

  void _dragEnd(double velocity) {
    if (!_dragging) return;
    _dragging = false;
    final centre = _x.value + _widths[_index] / 2;
    final i = projectedSegment(thumbCentre: centre, velocity: velocity, widths: _widths);
    setState(() {});
    final lefts = _lefts();
    GlassMotion.playMotor(MotionName.tabDroplet, _x, lefts[i], withVelocity: velocity);
    if (i != _index) {
      glassFire(ref, HapticEvent.select);
      _select(i);
    }
  }


  KeyEventResult _key(FocusNode n, KeyEvent e) {
    if (e is! KeyDownEvent && e is! KeyRepeatEvent) return KeyEventResult.ignored;
    final k = e.logicalKey;
    final prev = _vertical ? LogicalKeyboardKey.arrowUp : LogicalKeyboardKey.arrowLeft;
    final next = _vertical ? LogicalKeyboardKey.arrowDown : LogicalKeyboardKey.arrowRight;
    var i = _index;
    if (k == prev) {
      i = math.max(0, i - 1);
    } else if (k == next) {
      i = math.min(widget.segments.length - 1, i + 1);
    } else if (k == LogicalKeyboardKey.home) {
      i = 0;
    } else if (k == LogicalKeyboardKey.end) {
      i = widget.segments.length - 1;
    } else {
      return KeyEventResult.ignored;
    }
    _select(i);
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final legible = ref.watch(glassA11yProvider.select((a) => a.legible));
    final reduced = ref.watch(glassReducedProvider);
    final inHost = GlassHost.of(context);
    final hit = GlassFrame.hitMin(context);
    final n = widget.segments.length;
    final trackH = widget.compact ? 32.0 : 36.0;
    final disabled = !widget.enabled || widget.forceStates.disabled;
    final selectedIdx = _index;

    if (_vertical) return _buildVertical(context, hit, disabled, selectedIdx);

    return LayoutBuilder(
      builder: (context, c) {
        final st = roleStyle(context, gt.typeSubhead, legible: legible, wght: 620, maxScale: 1.5);
        final labelWidths = [for (final s in widget.segments) measureText(context, s.label, st).width];
        final natural = labelWidths.map((w) => w + 32).reduce(math.max) * n + 4;
        final total = (c.hasBoundedWidth ? c.maxWidth : natural).clamp(0.0, 4000.0);
        _widths = segmentWidths(labelWidths: labelWidths, total: total - 4);
        final lefts = _lefts();
        if (!_placed) {
          _placed = true;
          _idx = selectedIdx;
          _x.value = lefts[selectedIdx];
        } else if (!_dragging && _idx != selectedIdx) {
          _idx = selectedIdx;
          if (reduced) {
            _x.stop();
            _x.value = lefts[selectedIdx];
          } else {
            GlassMotion.playMotor(MotionName.tabDroplet, _x, lefts[selectedIdx], withVelocity: _x.velocity);
          }
        } else if (!_dragging && !_x.isAnimating) {
          _x.value = lefts[selectedIdx];
        }
        final trackFill = inHost ? gt.colorWellOnGlass : gt.colorFill3;
        final showGlassThumb = _dragging || widget.forceDragging;

        final rowH = math.max(hit, trackH);
        return Opacity(
          opacity: disabled ? 0.4 : 1,
          child: GlassFocusRing(
            shape: const GlassShape.capsule(),
            forceVisible: widget.forceStates.focused,
            child: Focus(
              focusNode: _focus,
              canRequestFocus: !disabled,
              onKeyEvent: _key,
              child: SizedBox(
                width: total,
                height: rowH,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onHorizontalDragStart: (_) => _dragStart(),
                  onHorizontalDragUpdate: (d) => _dragUpdate(d.delta.dx),
                  onHorizontalDragEnd: (d) => _dragEnd(d.velocity.pixelsPerSecond.dx),
                  onHorizontalDragCancel: () => _dragEnd(0),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // The visual: a 36 px track and its thumb, inside the hit row.
                      SizedBox(
                        width: total,
                        height: trackH,
                        child: DecoratedBox(
                          decoration: BoxDecoration(color: trackFill, borderRadius: BorderRadius.circular(trackH / 2)),
                          child: Padding(
                            padding: const EdgeInsets.all(2),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                AnimatedBuilder(
                                  animation: _x,
                                  builder: (context, _) {
                                    final w = _widths[_index];
                                    final sx = (1 + math.min(_x.velocity.abs() / 2000, 0.25)).toDouble();
                                    final thumbSize = Size(w, trackH - 4);
                                    final thumb = showGlassThumb
                                        ? SkinGlass(
                                            size: thumbSize,
                                            tier: GlassTierId.t1,
                                            finish: GlassFinishKind.clear,
                                            role: GlassRole.transient,
                                            materialize: false,
                                            moving: true,
                                            debugLabel: 'GlassSegmentedThumb',
                                            child: const SizedBox.expand(),
                                          )
                                        : DecoratedBox(
                                            decoration: ShapeDecoration(
                                              color: gt.colorSurface3,
                                              shape: const StadiumBorder(side: BorderSide(color: Color(0x38FFFFFF), width: 0.5)),
                                            ),
                                            child: SizedBox.fromSize(size: thumbSize),
                                          );
                                    return Positioned(
                                      left: _x.value,
                                      top: 0,
                                      width: w,
                                      height: trackH - 4,
                                      child: IgnorePointer(
                                        child: Transform(
                                          alignment: Alignment.center,
                                          transform: Matrix4.diagonal3Values(reduced ? 1 : sx, reduced ? 1 : (1 / math.sqrt(sx)).toDouble(), 1),
                                          child: thumb,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // The hit row: every segment is at least `hitMin` tall.
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Row(
                          children: [
                            for (var i = 0; i < n; i++) SizedBox(width: _widths[i], height: rowH, child: _segment(context, i, selectedIdx, legible)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _segment(BuildContext context, int i, int selectedIdx, bool legible) {
    final s = widget.segments[i];
    final sel = i == selectedIdx;
    final loading = widget.loadingValue != null && widget.loadingValue == s.value;
    return GlassPressable(
      material: GlassMaterial.content,
      sink: 0.96,
      shape: const GlassShape.capsule(),
      minHit: false,
      hoverGlow: false,
      onTap: widget.enabled ? () => _select(i) : null,
      enabled: widget.enabled,
      haptic: HapticEvent.select,
      semanticsLabel: '${s.label}, ${i + 1} of ${widget.segments.length}',
      inGroup: !widget.asTabs,
      checked: widget.asTabs ? null : sel,
      semanticsSelected: widget.asTabs ? sel : null,
      builder: (context, info) => Center(
        child: SizedBox(
          height: (widget.compact ? 32.0 : 36.0) - 4,
          child: DecoratedBox(
            decoration: BoxDecoration(color: !sel && info.states.hovered ? gt.colorFill4 : const Color(0x00000000), borderRadius: BorderRadius.circular(18)),
            child: Center(
              child: loading
                  ? const GlassSpinner(size: 16)
                  : GlassLabel(s.label, role: gt.typeSubhead, wght: 620, color: sel ? gt.colorLabel1 : gt.colorLabel2),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVertical(BuildContext context, double hit, bool disabled, int selectedIdx) {
    final n = widget.segments.length;
    final rowH = math.max(40.0, hit);
    return Opacity(
      opacity: disabled ? 0.4 : 1,
      child: Focus(
        focusNode: _focus,
        canRequestFocus: !disabled,
        onKeyEvent: _key,
        child: GlassFocusRing(
          shape: const GlassShape.superellipse(14),
          forceVisible: widget.forceStates.focused,
          child: SizedBox(
            width: 220,
            height: rowH * n,
            child: Stack(
              children: [
                SpringValue(
                  value: selectedIdx * rowH,
                  spring: gt.springTab,
                  name: MotionName.tabDroplet,
                  builder: (context, y, v) => Positioned(
                    left: 0,
                    right: 0,
                    top: y,
                    height: rowH,
                    child: IgnorePointer(
                      child: Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.diagonal3Values(1 / math.sqrt(1 + math.min(v.abs() / 2000, 0.25)), 1 + math.min(v.abs() / 2000, 0.25), 1),
                        child: SkinGlass(size: Size(220, rowH), tier: GlassTierId.t1, twin: GlassTwin.onGlass, shape: const GlassShape.superellipse(14), materialize: false, debugLabel: 'GlassSegmentedDroplet', child: const SizedBox.expand()),
                      ),
                    ),
                  ),
                ),
                Column(
                  children: [
                    for (var i = 0; i < n; i++)
                      SizedBox(
                        height: rowH,
                        child: GlassPressable(
                          material: GlassMaterial.content,
                          sink: 0.98,
                          shape: const GlassShape.superellipse(14),
                          minHit: false,
                          onTap: widget.enabled ? () => _select(i) : null,
                          haptic: HapticEvent.select,
                          semanticsLabel: '${widget.segments[i].label}, ${i + 1} of $n',
                          inGroup: !widget.asTabs,
                          checked: widget.asTabs ? null : i == selectedIdx,
                          semanticsSelected: widget.asTabs ? i == selectedIdx : null,
                          builder: (context, info) => Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: GlassLabel(widget.segments[i].label, role: gt.typeSubhead, wght: 620, color: i == selectedIdx ? gt.colorLabel1 : gt.colorLabel2),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
