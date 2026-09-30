import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/numbers/clock_copy.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// The 24-hour clock (cinematic 9.2.1): 24 radial bars 4 px wide from radius
/// 60 to 120, hour x 15 degrees clockwise from the top; `ink.100` at opacity
/// `max(0.12, value / max)` for hours with reading, `rule.1` for empty hours;
/// labels 0, 6, 12, 18 just outside.
class ClockChart extends StatelessWidget {
  const ClockChart({super.key, required this.byHour, this.diameter = 240, this.summary});

  /// 24 values of seconds.
  final List<int> byHour;

  /// 240 on The Numbers; the Annual page uses the same radii on a larger plate.
  final double diameter;
  final String? summary;

  @override
  Widget build(BuildContext context) {
    final folio = CineText.style(context, context.cine.typeFolio).copyWith(color: CineColors.ink45);
    const pad = 24.0;
    final side = diameter + pad * 2;
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: summary ?? numbersClockSentence(readClock(byHour)),
      child: SizedBox(
        width: side,
        height: side,
        child: CustomPaint(painter: _ClockPainter(byHour, folio, pad)),
      ),
    );
  }
}

Offset _dir(int hour) {
  final a = hour * 15 * math.pi / 180;
  return Offset(math.sin(a), -math.cos(a));
}

class _ClockPainter extends CustomPainter {
  const _ClockPainter(this.byHour, this.folio, this.pad);
  final List<int> byHour;
  final TextStyle folio;
  final double pad;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final max = byHour.fold<int>(0, math.max);
    for (var h = 0; h < 24; h++) {
      final v = h < byHour.length ? byHour[h] : 0;
      final color = v > 0 ? CineColors.ink100.withValues(alpha: math.max(0.12, v / max)) : CineColors.rule1;
      final d = _dir(h);
      canvas.drawLine(c + d * 60, c + d * 120, Paint()
        ..color = color
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.butt,);
    }
    for (final h in [0, 6, 12, 18]) {
      final tp = TextPainter(text: TextSpan(text: '$h', style: folio), textDirection: TextDirection.ltr)..layout();
      final p = c + _dir(h) * 134;
      tp.paint(canvas, p - Offset(tp.width / 2, tp.height / 2));
    }
  }

  @override
  SemanticsBuilderCallback get semanticsBuilder => (size) {
        final c = size.center(Offset.zero);
        return [
          for (var h = 0; h < 24; h++)
            CustomPainterSemantics(
              rect: Rect.fromCenter(center: c + _dir(h) * 90, width: 24, height: 24),
              properties: SemanticsProperties(label: hourSemantics(h, h < byHour.length ? byHour[h] : 0)),
            ),
        ];
      };

  @override
  bool shouldRepaint(_ClockPainter old) => old.byHour != byHour;
}
