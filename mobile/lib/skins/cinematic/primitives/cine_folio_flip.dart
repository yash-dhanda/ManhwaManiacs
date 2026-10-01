import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// Folio flip (cinematic 4.5): a tabular Plex Mono number whose changed digits roll, each 80 ms
/// (`durTick`) `easeSet`, 40 ms apart; old digit -100 % and fading, new one in from +100 %, each
/// in a clip. One accessible value. Reduced motion: instant.
class CineFolioFlip extends StatefulWidget {
  const CineFolioFlip({super.key, required this.value, this.role, this.color, this.format});
  final int value;

  /// The shown text for [value]; null prints the integer.
  final String Function(int)? format;
  String text(int v) => format?.call(v) ?? '$v';
  final CineTextRole? role;
  final Color? color;

  @override
  State<CineFolioFlip> createState() => _CineFolioFlipState();
}

class _CineFolioFlipState extends State<CineFolioFlip> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, value: 1);
  late String _from = widget.text(widget.value), _to = _from;

  @override
  void didUpdateWidget(CineFolioFlip old) {
    super.didUpdateWidget(old);
    if (old.value == widget.value) return;
    _from = widget.text(old.value);
    _to = widget.text(widget.value);
    if (CineMotion.reduced(context)) {
      _c.value = 1;
      return;
    }
    final n = _to.length > _from.length ? _to.length : _from.length;
    CineMotion.play(MotionName.folioFlip, _c,
        from: 0, duration: Duration(milliseconds: 80 + 40 * (n - 1)), curve: Curves.linear,);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final role = widget.role ?? c.typeFolioLg;
    final style = CineText.style(context, role).copyWith(
      color: widget.color ?? c.colorInk100,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final scaler = CineText.scaler(context, role);
    Widget t(String s) => Text(s, style: style, textScaler: scaler, maxLines: 1);
    final n = _to.length > _from.length ? _to.length : _from.length;
    final from = _from.padLeft(n), to = _to.padLeft(n);
    final lineH = scaler.scale((style.fontSize ?? 16) * (style.height ?? 1));
    return Semantics(
      value: widget.text(widget.value),
      child: ExcludeSemantics(
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, __) {
            final total = 80.0 + 40.0 * (n - 1);
            final cells = <Widget>[];
            for (var i = 0; i < n; i++) {
              final a = from[i], b = to[i];
              if (a == b || _c.value >= 1) {
                // Only the left padding collapses; a formatted value keeps its own spaces.
                cells.add(i < n - _to.length ? const SizedBox.shrink() : t(b));
                continue;
              }
              // Digit i (from the left) starts 40 ms after the one before it.
              final start = 40.0 * i / total, end = (40.0 * i + 80) / total;
              final p = CineCurves.easeSet.transform(((_c.value - start) / (end - start)).clamp(0.0, 1.0));
              cells.add(ClipRect(
                child: Stack(children: [
                  Opacity(opacity: 1 - p, child: Transform.translate(offset: Offset(0, -lineH * p), child: t(a))),
                  Positioned.fill(
                    child: Opacity(opacity: p, child: Transform.translate(offset: Offset(0, lineH * (1 - p)), child: t(b))),
                  ),
                ],),
              ),);
            }
            return Row(mainAxisSize: MainAxisSize.min, children: cells);
          },
        ),
      ),
    );
  }
}
