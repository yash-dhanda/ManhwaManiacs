import 'dart:async';

import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/reader_glyphs.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// A vertical drag along a screen edge (cinematic 8.14.5): the left 12 % changes the brightness,
/// the right 12 % the auto-scroll speed while it runs. [onChanged] gets the fraction 0..1 the
/// finger stands at, relative to where it started plus the starting [value].
class EdgeDragZone extends StatefulWidget {
  const EdgeDragZone({
    super.key,
    required this.left,
    required this.value,
    required this.onChanged,
    required this.onEnd,
    this.enabled = true,
    this.span = 300,
  });

  final bool left, enabled;

  /// The current value as a fraction 0..1.
  final double value;
  final ValueChanged<double> onChanged;
  final VoidCallback onEnd;

  /// The drag length that covers the whole range.
  final double span;

  @override
  State<EdgeDragZone> createState() => _EdgeDragZoneState();
}

class _EdgeDragZoneState extends State<EdgeDragZone> {
  double _start = 0;
  double _dy = 0;

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return const SizedBox.shrink();
    final width = MediaQuery.sizeOf(context).width * 0.12;
    return Positioned(
      top: 0,
      bottom: 0,
      left: widget.left ? 0 : null,
      right: widget.left ? null : 0,
      width: width,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onVerticalDragStart: (_) {
          _start = widget.value;
          _dy = 0;
        },
        onVerticalDragUpdate: (d) {
          _dy -= d.delta.dy;
          widget.onChanged((_start + _dy / widget.span).clamp(0.0, 1.0));
        },
        onVerticalDragEnd: (_) => widget.onEnd(),
        onVerticalDragCancel: widget.onEnd,
      ),
    );
  }
}

/// The 6 x 140 HUD bar with its glyph and value (cinematic 8.14.5): a 1 px `ink.100` outline, an
/// `ink.100` fill from the bottom, the value on the folio-flag ground. Fades 600 ms after release.
class EdgeHud extends StatelessWidget {
  const EdgeHud({super.key, required this.fill, required this.label, required this.visible, required this.left, this.glyph = ReaderCp.sunDim});

  final double fill;
  final String label;
  final bool visible, left;
  final int glyph;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final side = MediaQuery.viewPaddingOf(context);
    return Positioned(
      top: 0,
      bottom: 0,
      left: left ? side.left + 16 : null,
      right: left ? null : side.right + 16,
      child: IgnorePointer(
        child: Center(
          child: AnimatedOpacity(
            opacity: visible ? 1 : 0,
            duration: const Duration(milliseconds: 600),
            child: ExcludeSemantics(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CineGlyphIcon(glyph, size: 16, color: c.colorInk100),
                  const SizedBox(height: 8),
                  Container(
                    width: 6,
                    height: 140,
                    decoration: BoxDecoration(border: Border.all(color: c.colorInk100)),
                    alignment: Alignment.bottomCenter,
                    child: FractionallySizedBox(heightFactor: fill.clamp(0.0, 1.0), widthFactor: 1, child: ColoredBox(color: c.colorInk100)),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    decoration: BoxDecoration(color: const Color(0xFF000000), border: Border.all(color: c.colorInk100)),
                    child: CineRoleText(label, c.typeFolio, color: c.colorInk100),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Keeps a HUD visible while a drag runs and for 600 ms after.
class HudHold {
  HudHold(this.notify);
  final VoidCallback notify;
  bool visible = false;
  Timer? _t;

  void show() {
    _t?.cancel();
    visible = true;
    notify();
  }

  void releaseSoon() {
    _t?.cancel();
    _t = Timer(const Duration(milliseconds: 600), () {
      visible = false;
      notify();
    });
  }

  void dispose() => _t?.cancel();
}
