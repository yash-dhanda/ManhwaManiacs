import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// `·` at 0.5 em intervals in `ink.30` `typeFolio`, on the baseline, between a label and its
/// value (cinematic 7.16). Decorative: excluded from semantics.
class CineDotLeader extends StatelessWidget {
  const CineDotLeader({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final style = CineText.style(context, c.typeFolio).copyWith(color: c.colorInk30);
    final scaler = CineText.scaler(context, c.typeFolio);
    return ExcludeSemantics(
      child: LayoutBuilder(
        builder: (context, box) {
          final tp = TextPainter(text: TextSpan(text: '·', style: style), textDirection: TextDirection.ltr, textScaler: scaler)..layout();
          final step = (style.fontSize ?? 12) * 0.5 * scaler.scale(1);
          return CustomPaint(
            key: const Key('cine-dot-leader'),
            size: Size(box.maxWidth.isFinite ? box.maxWidth : 0, tp.height),
            painter: _Dots(tp, step),
          );
        },
      ),
    );
  }
}

class _Dots extends CustomPainter {
  _Dots(this.tp, this.step);
  final TextPainter tp;
  final double step;

  @override
  void paint(Canvas canvas, Size size) {
    for (var x = 0.0; x < size.width - tp.width; x += step + tp.width) {
      tp.paint(canvas, Offset(x, 0));
    }
  }

  @override
  bool shouldRepaint(_Dots o) => o.step != step || o.tp.text != tp.text;
}
