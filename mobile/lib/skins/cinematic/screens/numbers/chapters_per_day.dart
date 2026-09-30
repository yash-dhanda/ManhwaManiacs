import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:manhwamaniacs/features/library/models/library_statistics.dart';
import 'package:manhwamaniacs/features/library/utils/numbers_rules.dart';
import 'package:manhwamaniacs/skins/cinematic/hit.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/numbers/chart_math.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

const double _kLeft = 30;
const double _kRight = 44;
const double _kAxis = 20;

/// Chapters per day (cinematic 9.2.1, 9.2.3): one bar per day with 2 px gaps,
/// a dotted time line with square markers, only a baseline, the readout, the
/// best day, a text summary and one semantics node per bar.
class ChaptersPerDay extends StatelessWidget {
  const ChaptersPerDay({
    super.key,
    required this.daily,
    required this.days,
    required this.selected,
    required this.onSelect,
    this.tablet = false,
  });

  final List<DailyActivity> daily;
  final int days;

  /// Index into [daily]; null shows today.
  final int? selected;
  final ValueChanged<int?> onSelect;
  final bool tablet;

  @override
  Widget build(BuildContext context) {
    final t = context.cine;
    final best = bestChapterDay(daily);
    final summary = rangeSummary(rangeSentenceLabel(days), daily, best);
    final shown = daily.isEmpty
        ? null
        : daily[(selected ?? daily.length - 1).clamp(0, daily.length - 1)];
    final plotH = tablet ? 240.0 : 160.0;
    final folio =
        CineText.style(context, t.typeFolio).copyWith(color: CineColors.ink45);
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: summary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CineRoleText(summary, t.typeCaption, color: CineColors.ink60),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: shown == null
                      ? const SizedBox.shrink()
                      : Semantics(
                          label: 'Selected: ${daySemantics(shown)}',
                          excludeSemantics: true,
                          child: CineRoleText(dayReadout(shown), t.typeFolio,
                              maxLines: 2,),),),
              if (best != null)
                CineRoleText(
                    'Best day ${bestDate(best.date)} · ${best.chaptersRead} chapters',
                    t.typeCaption,
                    color: CineColors.ink60,
                    maxLines: 1,),
            ],
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, box) {
              final plotW = box.maxWidth - _kLeft - _kRight;
              final painter = _BarsPainter(
                  daily: daily,
                  selected: selected,
                  days: days,
                  plotH: plotH,
                  plotW: plotW,
                  folio: folio,
                  onSelect: onSelect,
                  minHit: cineHitMin(context),);
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (d) {
                  final i = nearestBar(
                      d.localPosition.dx - _kLeft, plotW, daily.length,);
                  if (i == null) return;
                  onSelect(selected == i ? null : i);
                },
                child: CustomPaint(
                    size: Size(box.maxWidth, plotH + _kAxis + 8),
                    painter: painter,),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _BarsPainter extends CustomPainter {
  _BarsPainter(
      {required this.daily,
      required this.selected,
      required this.days,
      required this.plotH,
      required this.plotW,
      required this.folio,
      required this.onSelect,
      required this.minHit,});

  final List<DailyActivity> daily;
  final int? selected;
  final int days;
  final double plotH;
  final double plotW;
  final TextStyle folio;
  final ValueChanged<int?> onSelect;
  final double minHit;

  double get _maxCh =>
      niceMax(daily.fold<int>(0, (m, d) => math.max(m, d.chaptersRead)));
  double get _maxMin => niceMaxMinutes(
      daily.fold<int>(0, (m, d) => math.max(m, d.secondsRead)) / 60,);

  void _label(Canvas canvas, String text, Offset at,
      {TextAlign align = TextAlign.left,}) {
    final tp = TextPainter(
        text: TextSpan(text: text, style: folio),
        textDirection: TextDirection.ltr,
        textAlign: align,)
      ..layout();
    final dx = switch (align) {
      TextAlign.right => at.dx - tp.width,
      TextAlign.center => at.dx - tp.width / 2,
      _ => at.dx,
    };
    tp.paint(canvas, Offset(dx, at.dy - tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final n = daily.length;
    if (n == 0) return;
    final base = plotH;
    canvas.save();
    canvas.translate(_kLeft, 0);
    final bw = barWidth(plotW, n);
    final maxCh = _maxCh;
    // Bars.
    for (var i = 0; i < n; i++) {
      final h = daily[i].chaptersRead / maxCh * plotH;
      if (h <= 0) continue;
      canvas.drawRect(Rect.fromLTWH(barLeft(plotW, n, i), base - h, bw, h),
          Paint()..color = i == selected ? CineColors.spot : CineColors.ink100,);
    }
    // Time line: dotted 1 px ink.45 (2 on, 3 off) with 4 x 4 square markers.
    final maxMin = _maxMin;
    final pts = [
      for (var i = 0; i < n; i++)
        Offset(barLeft(plotW, n, i) + bw / 2,
            base - (daily[i].secondsRead / 60) / maxMin * plotH,),
    ];
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final p in pts.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    final line = Paint()
      ..color = CineColors.ink45
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final m in path.computeMetrics()) {
      var d = 0.0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, math.min(d + 2, m.length)), line);
        d += 5;
      }
    }
    final mark = Paint()..color = CineColors.ink45;
    for (final p in pts) {
      canvas.drawRect(Rect.fromCenter(center: p, width: 4, height: 4), mark);
    }
    // Baseline only: no gridlines.
    canvas.drawRect(
        Rect.fromLTWH(0, base, plotW, 1), Paint()..color = CineColors.rule1,);
    canvas.restore();
    // Axes: chapters left (0, half, max), time right.
    for (final (f, y) in [(0.0, base), (0.5, base - plotH / 2), (1.0, 0.0)]) {
      _label(canvas, (maxCh * f).round().toString(),
          Offset(_kLeft - 6, y.clamp(6.0, base)),
          align: TextAlign.right,);
      _label(canvas, axisTime(maxMin * f),
          Offset(_kLeft + plotW + 6, y.clamp(6.0, base)),);
    }
    // Date labels under the baseline.
    for (final i in labelIndices(n)) {
      final x = _kLeft + barLeft(plotW, n, i) + bw / 2;
      _label(canvas, axisDate(daily[i].date),
          Offset(i == 0 ? x + 12 : (i == n - 1 ? x - 12 : x), base + 14),
          align: TextAlign.center,);
    }
  }

  @override
  SemanticsBuilderCallback get semanticsBuilder => buildSemantics;

  List<CustomPainterSemantics> buildSemantics(Size size) {
    final n = daily.length;
    final w = math.max(
        barWidth(plotW, n), n == 0 ? 0.0 : math.min(minHit, plotW / n),);
    return [
      for (var i = 0; i < n; i++)
        CustomPainterSemantics(
          rect: Rect.fromLTWH(
              _kLeft + barLeft(plotW, n, i) + barWidth(plotW, n) / 2 - w / 2,
              0,
              w,
              plotH,),
          properties: SemanticsProperties(
              textDirection: TextDirection.ltr,
              label: daySemantics(daily[i]),
              selected: i == selected,
              button: true,
              onTap: () => onSelect(selected == i ? null : i),),
        ),
    ];
  }

  @override
  bool shouldRepaint(_BarsPainter old) =>
      old.daily != daily ||
      old.selected != selected ||
      old.plotW != plotW ||
      old.plotH != plotH;

  @override
  bool shouldRebuildSemantics(_BarsPainter old) =>
      old.daily != daily || old.selected != selected || old.plotW != plotW;
}
