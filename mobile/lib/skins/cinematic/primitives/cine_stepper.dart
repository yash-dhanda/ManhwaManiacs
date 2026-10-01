import 'dart:async';

import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/feedback.dart';
import 'package:manhwamaniacs/skins/cinematic/focus_ring.dart';
import 'package:manhwamaniacs/skins/cinematic/hit.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_folio_flip.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// The stepper (cinematic 7.21): `−` value `+`, two 36 px ruled buttons (44 / 48 hit) around a
/// [CineFolioFlip] value in `typeFolioLg`, min width 64. The bounds disable their button; press and
/// hold repeats every 120 ms after 400 ms; `select` per step.
class CineStepper extends StatefulWidget {
  const CineStepper({super.key, required this.value, required this.onChanged, this.min = 0, this.max = 99, this.step = 1, this.label, this.format});

  final int value, min, max, step;

  /// The shown and spoken text for a value; null prints the integer.
  final String Function(int)? format;
  String _text(int v) => format?.call(v) ?? '$v';
  final ValueChanged<int> onChanged;
  final String? label;

  @override
  State<CineStepper> createState() => _CineStepperState();
}

class _CineStepperState extends State<CineStepper> {
  Timer? _delay, _repeat;
  late int _v = widget.value;

  @override
  void didUpdateWidget(CineStepper old) {
    super.didUpdateWidget(old);
    _v = widget.value;
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  void _stop() {
    _delay?.cancel();
    _repeat?.cancel();
  }

  bool _can(int dir) => dir < 0 ? _v > widget.min : _v < widget.max;

  void _step(int dir) {
    if (!_can(dir)) {
      _stop();
      return;
    }
    _v = (_v + dir * widget.step).clamp(widget.min, widget.max);
    cineFeedback(context, HapticEvent.select);
    widget.onChanged(_v);
    setState(() {});
  }

  void _down(int dir) {
    _step(dir);
    _stop();
    _delay = Timer(const Duration(milliseconds: 400), () {
      _repeat = Timer.periodic(const Duration(milliseconds: 120), (_) => _step(dir));
    });
  }

  Widget _btn(BuildContext context, int dir) {
    final c = context.cine;
    final on = _can(dir);
    final hit = cineHitMin(context);
    return Semantics(
      button: true,
      enabled: on,
      label: dir < 0 ? 'Decrease' : 'Increase',
      excludeSemantics: true,
      onTap: on ? () => _step(dir) : null,
      child: Listener(
        onPointerDown: on ? (_) => _down(dir) : null,
        onPointerUp: (_) => _stop(),
        onPointerCancel: (_) => _stop(),
        child: CineFocusRing(
          canRequestFocus: on,
          onActivate: on ? () => _step(dir) : null,
          hit: hit,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(border: Border.all(color: on ? c.colorInk45 : c.colorRule1)),
            child: Center(child: CineGlyphIcon(dir < 0 ? CineGlyph.minus : CineGlyph.plus, color: on ? c.colorInk100 : c.colorInk30)),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    return Semantics(
      label: widget.label,
      value: widget._text(_v),
      increasedValue: _can(1) ? widget._text(_v + widget.step) : null,
      decreasedValue: _can(-1) ? widget._text(_v - widget.step) : null,
      onIncrease: _can(1) ? () => _step(1) : null,
      onDecrease: _can(-1) ? () => _step(-1) : null,
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        _btn(context, -1),
        SizedBox(width: c.space2),
        ConstrainedBox(constraints: const BoxConstraints(minWidth: 64), child: Center(child: CineFolioFlip(value: _v, role: c.typeFolioLg, format: widget.format))),
        SizedBox(width: c.space2),
        _btn(context, 1),
      ],),
    );
  }
}
