import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

/// A suggestion token: a 1 px dashed `rule.2` outline (3 px dash, 2 px gap),
/// label in `micro`, with `+` accept and `x` reject buttons (44 pt hit).
class DashedToken extends StatelessWidget {
  const DashedToken({super.key, required this.label, this.onAccept, this.onReject});

  final String label;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<CineTokens>()!;
    return CustomPaint(
      painter: DashedBorderPainter(t.colorRule2),
      child: Padding(
        padding: const EdgeInsets.only(left: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label.toUpperCase(),
                style: TextStyle(fontSize: 10, letterSpacing: 1, color: t.colorInk80),),
            _Btn(icon: Icons.add, tooltip: 'Add tag $label', onTap: onAccept),
            _Btn(icon: Icons.close, tooltip: 'Reject tag $label', onTap: onReject),
          ],
        ),
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  const _Btn({required this.icon, required this.tooltip, this.onTap});
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => IconButton(
        tooltip: tooltip,
        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        padding: EdgeInsets.zero,
        iconSize: 14,
        icon: Icon(icon),
        onPressed: onTap,
      );
}

class DashedBorderPainter extends CustomPainter {
  const DashedBorderPainter(this.color, {this.dash = 3, this.gap = 2});
  final Color color;
  final double dash, gap;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final path = Path()..addRect(Offset.zero & size);
    for (final m in path.computeMetrics()) {
      for (var d = 0.0; d < m.length; d += dash + gap) {
        canvas.drawPath(m.extractPath(d, (d + dash).clamp(0, m.length)), p);
      }
    }
  }

  @override
  bool shouldRepaint(DashedBorderPainter old) => old.color != color;
}
