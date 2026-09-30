import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:manhwamaniacs/features/library/models/library_statistics.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/numbers/chart_math.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

const double _kCell = 10;
const double _kGap = 2;
const double _kTop = 16;

/// The YEAR range: 53 x 7 cells of 10 px with 2 px gaps (634 x 82), weeks as
/// columns Monday first; levels by size (the 2.1.6 chart palette). Scrolls
/// horizontally, jumped to today's column on mount.
class YearHeatmap extends StatefulWidget {
  const YearHeatmap(
      {super.key,
      required this.daily,
      required this.today,
      required this.selected,
      required this.onSelect,});

  final List<DailyActivity> daily;
  final DateTime today;

  /// Index into [daily].
  final int? selected;
  final ValueChanged<int?> onSelect;

  @override
  State<YearHeatmap> createState() => _YearHeatmapState();
}

class _YearHeatmapState extends State<YearHeatmap> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  int? _indexOf(DateTime d) {
    for (var i = 0; i < widget.daily.length; i++) {
      final x = widget.daily[i].date;
      if (x.year == d.year && x.month == d.month && x.day == d.day) return i;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.cine;
    final grid = heatGrid(widget.daily, widget.today);
    const w = 53 * (_kCell + _kGap) - _kGap;
    const h = _kTop + 7 * (_kCell + _kGap) - _kGap;
    final folio =
        CineText.style(context, t.typeFolio).copyWith(color: CineColors.ink45);
    final selDay =
        widget.selected != null && widget.selected! < widget.daily.length
            ? widget.daily[widget.selected!]
            : null;
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: heatSummary(widget.daily),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CineRoleText(heatSummary(widget.daily), t.typeCaption,
              color: CineColors.ink60,),
          const SizedBox(height: 12),
          if (selDay != null) ...[
            CineRoleText(dayReadout(selDay), t.typeFolio),
            const SizedBox(height: 8),
          ],
          SingleChildScrollView(
            controller: _scroll,
            scrollDirection: Axis.horizontal,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (d) {
                final c = (d.localPosition.dx / (_kCell + _kGap)).floor();
                final r =
                    ((d.localPosition.dy - _kTop) / (_kCell + _kGap)).floor();
                if (c < 0 || c >= 53 || r < 0 || r >= 7) return;
                final cell = grid[c][r];
                if (cell == null) return;
                final i = _indexOf(cell.date);
                widget.onSelect(widget.selected == i ? null : i);
              },
              child: CustomPaint(
                size: const Size(w, h),
                painter: _HeatPainter(
                    grid: grid,
                    today: widget.today,
                    selected: selDay?.date,
                    folio: folio,),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const _Legend(),
        ],
      ),
    );
  }
}

void _paintForm(Canvas canvas, Offset origin, int level) {
  final side = kHeatSides[level];
  if (level == 0) {
    canvas.drawRect(
      Rect.fromLTWH(origin.dx + 0.5, origin.dy + 0.5, _kCell - 1, _kCell - 1),
      Paint()
        ..color = CineColors.rule2
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  } else {
    final o = (_kCell - side) / 2;
    canvas.drawRect(Rect.fromLTWH(origin.dx + o, origin.dy + o, side, side),
        Paint()..color = CineColors.ink100,);
  }
}

class _HeatPainter extends CustomPainter {
  const _HeatPainter(
      {required this.grid,
      required this.today,
      required this.selected,
      required this.folio,});
  final List<List<HeatCell?>> grid;
  final DateTime today;
  final DateTime? selected;
  final TextStyle folio;

  @override
  void paint(Canvas canvas, Size size) {
    final months = monthLabelColumns(grid);
    for (final e in months.entries) {
      final tp = TextPainter(
          text: TextSpan(text: e.value, style: folio),
          textDirection: TextDirection.ltr,)
        ..layout();
      tp.paint(canvas, Offset(e.key * (_kCell + _kGap), 0));
    }
    for (var c = 0; c < grid.length; c++) {
      for (var r = 0; r < 7; r++) {
        final cell = grid[c][r];
        if (cell == null) continue;
        final o = Offset(c * (_kCell + _kGap), _kTop + r * (_kCell + _kGap));
        _paintForm(canvas, o, cell.level);
        final isToday = cell.date.year == today.year &&
            cell.date.month == today.month &&
            cell.date.day == today.day;
        if (isToday) {
          canvas.drawRect(
            Rect.fromLTWH(o.dx + 0.5, o.dy + 0.5, _kCell - 1, _kCell - 1),
            Paint()
              ..color = CineColors.spot
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1,
          );
        }
        if (selected != null && cell.date == selected) {
          canvas.drawRect(
            Rect.fromLTWH(o.dx - 1, o.dy - 1, _kCell + 2, _kCell + 2),
            Paint()
              ..color = CineColors.spot
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1,
          );
        }
      }
    }
  }

  @override
  SemanticsBuilderCallback get semanticsBuilder => (size) => [
        for (var c = 0; c < grid.length; c++)
          for (var r = 0; r < 7; r++)
            if (grid[c][r] != null)
              CustomPainterSemantics(
                rect: Rect.fromLTWH(c * (_kCell + _kGap),
                    _kTop + r * (_kCell + _kGap), _kCell, _kCell,),
                properties: SemanticsProperties(
                    textDirection: TextDirection.ltr,
                    label:
                        '${spokenDate(grid[c][r]!.date)}, ${grid[c][r]!.chapters} ${grid[c][r]!.chapters == 1 ? 'chapter' : 'chapters'}',
                    button: true,),
              ),
      ];

  @override
  bool shouldRepaint(_HeatPainter old) =>
      old.grid != grid || old.selected != selected || old.today != today;
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    const labels = ['0', '1–2', '3–5', '6–10', '11+'];
    final t = context.cine;
    return Semantics(
      label: 'Legend: 0, 1 to 2, 3 to 5, 6 to 10, 11 or more chapters',
      child: ExcludeSemantics(
        child: Wrap(
          spacing: 12,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (var i = 0; i < 5; i++)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomPaint(
                      size: const Size(_kCell, _kCell),
                      painter: _FormPainter(i),),
                  const SizedBox(width: 4),
                  CineRoleText(labels[i], t.typeFolio, color: CineColors.ink45),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _FormPainter extends CustomPainter {
  const _FormPainter(this.level);
  final int level;
  @override
  void paint(Canvas canvas, Size size) =>
      _paintForm(canvas, Offset.zero, level);
  @override
  bool shouldRepaint(_FormPainter old) => old.level != level;
}
