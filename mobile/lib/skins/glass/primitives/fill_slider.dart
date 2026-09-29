import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/glass/glass/focus_ring.dart';
import 'package:manhwamaniacs/skins/glass/icons/phosphor.g.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/spring_value.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart';

enum GlassFillKind { brightness, volume }

/// The Control-Centre style fill slider (glass 7.21): always on a glass host, so it is the `fill2` twin. A 72 x 160
/// capsule that fills from the bottom with `onGlass` at 90 %, a glyph at the bottom (`sun` for brightness,
/// `speaker-high` for volume); drag anywhere on it; the fill follows on `springTrack`. A vertical slider in semantics.
class GlassFillSlider extends ConsumerStatefulWidget {
  const GlassFillSlider({super.key, required this.value, required this.onChanged, required this.label, this.kind = GlassFillKind.brightness, this.onChangeEnd});
  final double value;
  final ValueChanged<double> onChanged;
  final ValueChanged<double>? onChangeEnd;
  final String label;
  final GlassFillKind kind;

  @override
  ConsumerState<GlassFillSlider> createState() => _GlassFillSliderState();
}

class _GlassFillSliderState extends ConsumerState<GlassFillSlider> {
  static const double _w = 72, _h = 160;
  double? _drag;

  void _set(double v) {
    _drag = v.clamp(0.0, 1.0);
    widget.onChanged(_drag!);
  }

  double get _shown => _drag ?? widget.value;

  @override
  Widget build(BuildContext context) {
    final glyph = widget.kind == GlassFillKind.brightness ? PhosphorFill.sun : GlassGlyphExt.speakerHigh;
    return Semantics(
      slider: true,
      excludeSemantics: true,
      label: widget.label,
      value: '${(widget.value * 100).round()} percent',
      increasedValue: '${((widget.value + 0.05).clamp(0.0, 1.0) * 100).round()} percent',
      decreasedValue: '${((widget.value - 0.05).clamp(0.0, 1.0) * 100).round()} percent',
      onIncrease: () => widget.onChanged((widget.value + 0.05).clamp(0.0, 1.0)),
      onDecrease: () => widget.onChanged((widget.value - 0.05).clamp(0.0, 1.0)),
      child: Focus(
        onKeyEvent: (n, e) {
          if (e is! KeyDownEvent && e is! KeyRepeatEvent) return KeyEventResult.ignored;
          if (e.logicalKey == LogicalKeyboardKey.arrowUp) {
            widget.onChanged((widget.value + 0.05).clamp(0.0, 1.0));
          } else if (e.logicalKey == LogicalKeyboardKey.arrowDown) {
            widget.onChanged((widget.value - 0.05).clamp(0.0, 1.0));
          } else {
            return KeyEventResult.ignored;
          }
          return KeyEventResult.handled;
        },
        child: GlassFocusRing(
          shape: GlassShape.superellipse(36),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onVerticalDragStart: (d) => _set(1 - d.localPosition.dy / _h),
            onVerticalDragUpdate: (d) => _set(1 - d.localPosition.dy / _h),
            onVerticalDragEnd: (_) {
              final v = _shown;
              setState(() => _drag = null);
              widget.onChangeEnd?.call(v);
            },
            onTapDown: (d) => _set(1 - d.localPosition.dy / _h),
            child: SizedBox(
              width: _w,
              height: _h,
              child: ClipRSuperellipse(
                borderRadius: BorderRadius.circular(36),
                child: DecoratedBox(
                  decoration: BoxDecoration(color: gt.colorFill2),
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      Positioned.fill(
                        child: SpringValue(
                          value: _shown,
                          spring: gt.springTrack,
                          builder: (context, v, _) => Align(
                            alignment: Alignment.bottomCenter,
                            child: FractionallySizedBox(
                              heightFactor: v.clamp(0.0, 1.0),
                              widthFactor: 1,
                              child: ColoredBox(key: const ValueKey('glass-fill'), color: gt.colorOnGlass.withValues(alpha: 0.9)),
                            ),
                          ),
                        ),
                      ),
                      Padding(padding: const EdgeInsets.only(bottom: 14), child: Icon(glyph, size: 22, color: _shown > 0.12 ? const Color(0xFF111114) : gt.colorOnGlass)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Glyphs the generated Phosphor table does not carry.
abstract final class GlassGlyphExt {
  static const speakerHigh = IconData(0xe44a, fontFamily: 'PhosphorFill');
}
