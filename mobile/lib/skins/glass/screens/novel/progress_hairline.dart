import 'package:flutter/widgets.dart';

/// The progress hairline (E5): 2 px at `inset.top`, full width, the muted ink at 100 % for the read part and 25 % for the rest,
/// always visible (also with the chrome hidden).
class NovelProgressHairline extends StatelessWidget {
  const NovelProgressHairline({super.key, required this.progress, required this.color});
  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: SizedBox(height: 2, width: double.infinity, child: CustomPaint(painter: _Hairline(progress.clamp(0.0, 1.0), color))),
      );
}

class _Hairline extends CustomPainter {
  _Hairline(this.v, this.color);
  final double v;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas
      ..drawRect(Offset.zero & size, Paint()..color = color.withValues(alpha: 0.25))
      ..drawRect(Rect.fromLTWH(0, 0, size.width * v, size.height), Paint()..color = color);
  }

  @override
  bool shouldRepaint(_Hairline old) => old.v != v || old.color != color;
}
