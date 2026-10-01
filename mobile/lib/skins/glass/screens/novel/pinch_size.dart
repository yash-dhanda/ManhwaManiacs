import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/skins/glass/motion.dart';
import 'package:manhwamaniacs/skins/glass/motion_names.g.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

/// Counts the pointers on the column and turns two of them into a pinch scale from the gesture's start (G8). While two are down the
/// column stops scrolling; the text is never scaled, only the capsule shows the size.
class PinchTracker {
  final Map<int, Offset> _pointers = {};
  double? _startDistance;

  bool get pinching => _pointers.length >= 2;

  /// Returns true when this event started a pinch.
  bool down(PointerDownEvent e) {
    _pointers[e.pointer] = e.position;
    if (_pointers.length == 2) {
      _startDistance = _distance();
      return true;
    }
    return false;
  }

  /// The current scale, or null while not pinching.
  double? move(PointerMoveEvent e) {
    if (!_pointers.containsKey(e.pointer)) return null;
    _pointers[e.pointer] = e.position;
    final s = _startDistance;
    if (!pinching || s == null || s <= 0) return null;
    return _distance() / s;
  }

  /// Returns true when this event ended a pinch.
  bool up(PointerEvent e) {
    final was = pinching;
    _pointers.remove(e.pointer);
    if (was && !pinching) {
      _startDistance = null;
      return true;
    }
    return false;
  }

  double _distance() {
    final v = _pointers.values.take(2).toList();
    return (v[0] - v[1]).distance;
  }
}

/// The top-centre slot's capsule (E9): one at a time, `glassThin`, materialising in. The pinch capsule "Text size 21", the rate-limited
/// capsule (with the `warning` glyph) and `mobile/41`'s "Previously" pill share the slot; the newest replaces the older.
class NovelTopCapsule extends StatefulWidget {
  const NovelTopCapsule({super.key, required this.text, required this.lb, this.warning = false, this.tint, this.semanticsLabel});
  final String text;
  final bool warning;
  final double lb;
  final Color? tint;
  final String? semanticsLabel;

  @override
  State<NovelTopCapsule> createState() => _NovelTopCapsuleState();
}

class _NovelTopCapsuleState extends State<NovelTopCapsule> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this);
    unawaited(GlassMotion.play(MotionName.materialise, controller: _c, target: 1));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = roleStyle(context, gt.typeFootnote, onGlass: true, wght: 600, maxScale: 1.3);
    // Never wider than the screen less its gutters; a longer line sets down inside the capsule.
    final w = math.min(measureText(context, widget.text, style).width + 24 + (widget.warning ? 26 : 0), MediaQuery.sizeOf(context).width - 32);
    return FadeTransition(
      opacity: _c,
      child: Semantics(
        liveRegion: true,
        label: widget.semanticsLabel ?? widget.text,
        excludeSemantics: true,
        child: SkinGlass(
          size: Size(w, 32),
          tier: GlassTierId.t2,
          lb: widget.lb,
          layer: GlassLayerKind.hud,
          debugLabel: 'novel top-centre capsule',
          child: GlassHost(
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (widget.tint != null) DecoratedBox(decoration: BoxDecoration(color: widget.tint, borderRadius: BorderRadius.circular(16))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.warning) ...[GlassBacking(size: 20, child: GlyphIcon(GlassGlyph.warning, size: 14, color: gt.colorWarning)), const SizedBox(width: 6)],
                        GlassText(widget.text, role: gt.typeFootnote, wght: 600, onGlass: true, maxScale: 1.3, maxLines: 1),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
