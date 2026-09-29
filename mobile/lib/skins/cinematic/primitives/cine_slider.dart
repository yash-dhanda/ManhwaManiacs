import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:manhwamaniacs/skins/cinematic/feedback.dart';
import 'package:manhwamaniacs/skins/cinematic/focus_ring.dart';
import 'package:manhwamaniacs/skins/cinematic/hit.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// The slider (cinematic 7.20), drawn here: a 2 px `rule.2` track, `ink.100` fill up to the value,
/// 1 x 6 px `ink.30` step ticks under it when there are 20 steps or fewer, a 2 x 20 px `ink.100`
/// bar thumb in a 44 / 48 hit square. While dragging a folio flag shows above the thumb (a `#000`
/// box, 1 px `ink.100` border, 4 x 8 padding); the thumb grows 2 x 24 on hover and 3 x 28 pressed
/// and on release settles to its step on `CineSprings.scrub`. Keys: arrows step, `Shift` x 10,
/// `Home` / `End`. [haptic] fires per step; [onStep] sees every step change.
class CineSlider extends StatefulWidget {
  const CineSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 1,
    this.divisions,
    this.label,
    this.flagText,
    this.valueText,
    this.minCaption,
    this.maxCaption,
    this.onChangeEnd,
    this.haptic = HapticEvent.select,
    this.onStep,
    this.focusNode,
  });

  final double value, min, max;
  final int? divisions;
  final ValueChanged<double>? onChanged;
  final ValueChanged<double>? onChangeEnd;

  /// The accessible name.
  final String? label;

  /// The folio flag text for a value ("1.25×", "19 px").
  final String Function(double value)? flagText;

  /// The spoken value ("Page 18 of 40").
  final String Function(double value)? valueText;
  final String? minCaption, maxCaption;
  final HapticEvent haptic;
  final ValueChanged<double>? onStep;
  final FocusNode? focusNode;

  @override
  State<CineSlider> createState() => _CineSliderState();
}

class _CineSliderState extends State<CineSlider> with SingleTickerProviderStateMixin {
  late final AnimationController _f = AnimationController.unbounded(vsync: this, value: _frac(widget.value));
  bool _drag = false, _hover = false, _keys = false;

  double _frac(double v) => widget.max == widget.min ? 0 : ((v - widget.min) / (widget.max - widget.min)).clamp(0.0, 1.0);
  double get _stepSize => widget.divisions != null ? (widget.max - widget.min) / widget.divisions! : (widget.max - widget.min) / 100;
  bool get _enabled => widget.onChanged != null;

  double _snap(double v) {
    v = v.clamp(widget.min, widget.max);
    if (widget.divisions == null) return v;
    return (widget.min + ((v - widget.min) / _stepSize).round() * _stepSize).clamp(widget.min, widget.max);
  }

  @override
  void didUpdateWidget(CineSlider old) {
    super.didUpdateWidget(old);
    if (!_drag && old.value != widget.value) _settle(_frac(widget.value));
  }

  @override
  void dispose() {
    _f.dispose();
    super.dispose();
  }

  void _settle(double to) {
    if (CineMotion.reduced(context)) {
      _f.value = to;
      return;
    }
    _f.animateWith(SpringSimulation(context.cine.springScrub.description, _f.value, to, 0));
  }

  void _set(double v, {bool viaDrag = false}) {
    final n = _snap(v);
    final changed = n != widget.value;
    if (viaDrag) _f.value = _frac(v);
    if (changed) {
      cineFeedback(context, widget.haptic);
      widget.onStep?.call(n);
      widget.onChanged?.call(n);
    }
  }

  void _at(double dx, double width) => _set(widget.min + (dx / width).clamp(0.0, 1.0) * (widget.max - widget.min), viaDrag: true);

  KeyEventResult _key(FocusNode n, KeyEvent e) {
    if (!_enabled || e is KeyUpEvent) return KeyEventResult.ignored;
    final shift = HardwareKeyboard.instance.isShiftPressed ? 10 : 1;
    final k = e.logicalKey;
    double? v;
    if (k == LogicalKeyboardKey.arrowRight || k == LogicalKeyboardKey.arrowUp) {
      v = widget.value + _stepSize * shift;
    } else if (k == LogicalKeyboardKey.arrowLeft || k == LogicalKeyboardKey.arrowDown) {
      v = widget.value - _stepSize * shift;
    } else if (k == LogicalKeyboardKey.home) {
      v = widget.min;
    } else if (k == LogicalKeyboardKey.end) {
      v = widget.max;
    }
    if (v == null) return KeyEventResult.ignored;
    _set(v);
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final hit = cineHitMin(context);
    final active = _drag || _keys;
    final tw = _drag ? 3.0 : 2.0, th = _drag ? 28.0 : (_hover ? 24.0 : 20.0);
    final text = widget.valueText?.call(widget.value) ?? '${widget.value}';
    final s = _stepSize;
    return Semantics(
      slider: true,
      enabled: _enabled,
      label: widget.label,
      value: text,
      increasedValue: widget.valueText?.call(_snap(widget.value + s)),
      decreasedValue: widget.valueText?.call(_snap(widget.value - s)),
      onIncrease: _enabled ? () => _set(widget.value + s) : null,
      onDecrease: _enabled ? () => _set(widget.value - s) : null,
      excludeSemantics: true,
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        LayoutBuilder(
          builder: (context, box) {
            final w = box.maxWidth;
            return MouseRegion(
              onEnter: (_) => setState(() => _hover = true),
              onExit: (_) => setState(() => _hover = false),
              cursor: _enabled ? SystemMouseCursors.click : MouseCursor.defer,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: _enabled ? (d) => _at(d.localPosition.dx, w) : null,
                onTapUp: _enabled ? (_) => _settle(_frac(widget.value)) : null,
                onHorizontalDragStart: _enabled
                    ? (d) {
                        setState(() => _drag = true);
                        _at(d.localPosition.dx, w);
                      }
                    : null,
                onHorizontalDragUpdate: _enabled ? (d) => _at(d.localPosition.dx, w) : null,
                onHorizontalDragEnd: _enabled
                    ? (_) {
                        setState(() => _drag = false);
                        _settle(_frac(widget.value));
                        widget.onChangeEnd?.call(widget.value);
                      }
                    : null,
                child: SizedBox(
                  height: hit + 8,
                  child: AnimatedBuilder(
                    animation: _f,
                    builder: (context, _) {
                      final x = _f.value.clamp(0.0, 1.0) * w;
                      return Stack(clipBehavior: Clip.none, alignment: Alignment.centerLeft, children: [
                        Positioned(left: 0, right: 0, top: (hit + 8) / 2 - 1, height: 2, child: ColoredBox(color: _enabled ? c.colorRule2 : c.colorRule1)),
                        Positioned(left: 0, width: x, top: (hit + 8) / 2 - 1, height: 2, child: ColoredBox(color: _enabled ? c.colorInk100 : c.colorRule2)),
                        if (widget.divisions != null && widget.divisions! <= 20)
                          for (var i = 0; i <= widget.divisions!; i++)
                            Positioned(left: (i / widget.divisions!) * w - 0.5, top: (hit + 8) / 2 + 6, width: 1, height: 6, child: ColoredBox(color: c.colorInk30)),
                        Positioned(
                          left: x - hit / 2,
                          top: 4,
                          width: hit,
                          height: hit,
                          child: Focus(
                            canRequestFocus: false,
                            onKeyEvent: _key,
                            child: CineFocusRing(
                              focusNode: widget.focusNode,
                              canRequestFocus: _enabled,
                              onHighlight: (v) => setState(() => _keys = v),
                              child: Center(
                                child: AnimatedContainer(
                                  duration: CineMotion.reduced(context) ? Duration.zero : c.durTick,
                                  width: tw,
                                  height: th,
                                  color: _enabled ? c.colorInk100 : c.colorInk30,
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (active && widget.flagText != null)
                          Positioned(
                            left: x - 60,
                            width: 120,
                            top: -22,
                            child: Center(
                              child: Container(
                                key: const Key('cine-slider-flag'),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: const Color(0xFF000000), border: Border.all(color: c.colorInk100)),
                                child: CineRoleText(widget.flagText!(widget.value), c.typeFolio),
                              ),
                            ),
                          ),
                      ],);
                    },
                  ),
                ),
              ),
            );
          },
        ),
        if (widget.minCaption != null || widget.maxCaption != null)
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            CineRoleText(widget.minCaption ?? '', c.typeCaption, color: c.colorInk45),
            CineRoleText(widget.maxCaption ?? '', c.typeCaption, color: c.colorInk45),
          ],),
      ],),
    );
  }
}

/// The scrubber base (cinematic 7.20): a [CineSlider] over whole pages with [onTick] per page
/// (`scrub.tick`) and [onBoundary] when a drag crosses into another chapter (`scrub.boundary`,
/// cue `tick`). [chapterStarts] maps a page to the chapter that begins on it. The reader ruler
/// (mobile/12) and the speed ruler (mobile/15) extend it.
class CineScrubber extends StatelessWidget {
  const CineScrubber({
    super.key,
    required this.page,
    required this.pages,
    required this.onPage,
    this.onTick,
    this.onBoundary,
    this.chapterStarts = const {},
    this.valueText,
    this.label = 'Page',
  });

  /// 1-based.
  final int page, pages;
  final ValueChanged<int> onPage;
  final ValueChanged<int>? onTick;
  final ValueChanged<int>? onBoundary;
  final Map<int, int> chapterStarts;
  final String Function(int page)? valueText;
  final String label;

  @override
  Widget build(BuildContext context) => CineSlider(
        value: page.toDouble(),
        min: 1,
        max: math.max(pages, 1).toDouble(),
        divisions: pages > 1 ? pages - 1 : null,
        label: label,
        haptic: HapticEvent.scrubTick,
        flagText: (v) => valueText?.call(v.round()) ?? '${v.round()}',
        valueText: (v) => valueText?.call(v.round()) ?? 'Page ${v.round()} of $pages',
        onStep: (v) {
          final p = v.round();
          onTick?.call(p);
          final ch = chapterStarts[p];
          if (ch != null) {
            cineFeedback(context, HapticEvent.scrubBoundary, sound: SoundEvent.scrubTick);
            onBoundary?.call(ch);
          }
        },
        onChanged: pages > 1 ? (v) => onPage(v.round()) : null,
      );
}
